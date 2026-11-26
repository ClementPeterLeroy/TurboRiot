"""Edit roofs in the six existing masters and close existing architectural links.
No facade generator, road/terrain/stair edit or unique per-house asset creation.
Run with Blender --factory-startup --disable-autoexec --background --python.
"""
from pathlib import Path
import bpy,bmesh,json,hashlib,math,sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/environment/city_square';SRC=ASSETS/'sources'
REPORT=ROOT/'artifacts/v061_city_architecture_sources.json'
report={'modules':{},'links':{},'roof_thickness':.18}
if ('--resume' in sys.argv or '--repair-bases' in sys.argv) and REPORT.exists():report=json.loads(REPORT.read_text())
SPECS={'townhouse':('gable_z',1.9),'narrow_house':('gable_z',1.8),'wide_house':('hip_x',2.1),'merchant_house':('gable_x',1.9),'corner_house':('hip_z',1.9),'harbour_house':('gable_x',1.8)}

def fingerprint(obj):
 payload={'v':[list(v.co) for v in obj.data.vertices],'f':[list(p.vertices) for p in obj.data.polygons],'matrix':[list(r) for r in obj.matrix_world],'uv':[[list(v.uv) for v in layer.data] for layer in obj.data.uv_layers]}
 return hashlib.sha256(json.dumps(payload,sort_keys=True).encode()).hexdigest()
def mesh(name,vertices,faces,material):
 data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.materials.append(material);data.update()
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
 if bm.calc_volume(signed=True)<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
 bm.to_mesh(data);bm.free()
 uv=data.uv_layers.new(name='RepeatedMetres')
 for face in data.polygons:
  for index in face.loop_indices:
   p=data.vertices[data.loops[index].vertex_index].co
   uv.data[index].uv=(p.x/2,-p.y/2) if abs(face.normal.z)>.45 else (p.x/2,p.z/2)
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);return obj
def solid_prism(name,vertices,faces,material):
 # Compact only within this prism; adjacent closed volumes may share a party
 # boundary without being globally welded into non-manifold intersections.
 unique=[];mapping=[]
 for p in vertices:
  found=next((i for i,q in enumerate(unique) if (Vector(p)-Vector(q)).length<1e-7),None)
  if found is None:found=len(unique);unique.append(p)
  mapping.append(found)
 valid=[]
 for face in faces:
  f=[]
  for i in face:
   j=mapping[i]
   if not f or f[-1]!=j:f.append(j)
  if len(f)>1 and f[0]==f[-1]:f.pop()
  if len(set(f))>=3:valid.append(f)
 return mesh(name,unique,valid,material)
def shell(name,top,faces,material,thickness=.18):
 vertices=list(top)+[(x,y,z-thickness) for x,y,z in top];n=len(top)
 result=list(faces)+[tuple(i+n for i in reversed(f)) for f in faces]
 edges={}
 for f in faces:
  for a,b in zip(f,f[1:]+f[:1]):
   key=tuple(sorted((a,b)));edges.setdefault(key,[]).append((a,b))
 for matches in edges.values():
  if len(matches)==1:
   a,b=matches[0];result.append((a,b,b+n,a+n))
 return mesh(name,vertices,result,material)
def roof_stats(obj):
 bm=bmesh.new();bm.from_mesh(obj.data)
 chosen={f for f in bm.faces if obj.data.materials[f.material_index].name.startswith('City_Roof')}
 edges={e for f in chosen for e in f.edges}
 boundary=sum(sum(f in chosen for f in e.link_faces)==1 for e in edges)
 nonmanifold=sum(sum(f in chosen for f in e.link_faces)!=2 for e in edges)
 values=[v.co.z for f in chosen for v in f.verts]
 result={'roof_faces':len(chosen),'open_roof_edges':boundary,'nonmanifold_roof_edges':nonmanifold,'roof_height':max(values)-min(values),'min_z':min(values),'max_z':max(values)}
 bm.free();return result
def save(name,join=False):
 bpy.context.scene['turbo_roof_revision']=1
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
 if join:
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
  for obj in objects:obj.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name='House'
 bpy.ops.export_scene.gltf(filepath=str(ASSETS/(name+'.glb')),export_format='GLB',export_apply=True,export_cameras=False,export_lights=False,export_animations=False,will_save_settings=False)
 REPORT.write_text(json.dumps(report,indent=2));print('CITY_ROOF_SAVED',name,flush=True)

def close_bases(obj):
 # Clipped, triangulated bottom caps have several sub-millimetre slivers and
 # a few open loops below grade. Weld only plaster/stone vertices, then close
 # their remaining boundary loops. No roof or facade outline is moved.
 bm=bmesh.new();bm.from_mesh(obj.data);uv=bm.loops.layers.uv.active
 gable=bm.faces.layers.int.get('roof_gable')
 for prefix in ['City_Plaster','City_Stone']:
  faces={f for f in bm.faces if obj.data.materials[f.material_index].name.startswith(prefix) and (not gable or f[gable]==0)}
  vertices={v for f in faces for v in f.verts}
  bmesh.ops.remove_doubles(bm,verts=list(vertices),dist=.0001)
  faces={f for f in bm.faces if obj.data.materials[f.material_index].name.startswith(prefix) and (not gable or f[gable]==0)}
  edges={e for f in faces for e in f.edges};boundary=[e for e in edges if sum(f in faces for f in e.link_faces)==1]
  if boundary:
   material=next(iter(faces)).material_index
   filled=bmesh.ops.holes_fill(bm,edges=boundary,sides=0)['faces']
   for face in filled:
    face.material_index=material
    if uv:
     for loop in face.loops:loop[uv].uv=(loop.vert.co.x/2,-loop.vert.co.y/2)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()

if '--repair-bases' in sys.argv:
 bpy.ops.wm.open_mainfile(filepath=str(SRC/'architectural_links.blend'))
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH':close_bases(obj)
 save('architectural_links');sys.exit(0)

for name,(kind,rise) in SPECS.items():
 bpy.ops.wm.open_mainfile(filepath=str(SRC/(name+'.blend')))
 if bpy.context.scene.get('turbo_roof_revision',0):
  if '--resume' in sys.argv:
   assert name in report['modules'],'Missing source record for corrected master: '+name
   continue
  raise RuntimeError('Roof revision already applied: '+name)
 before={o.name:fingerprint(o) for o in bpy.context.scene.objects if o.type=='MESH' and o.name!='TerracottaRoof'}
 wall=bpy.data.objects['StuccoWalls'];corners=[wall.matrix_world@v.co for v in wall.data.vertices]
 w=max(p.x for p in corners)-min(p.x for p in corners);d=max(p.y for p in corners)-min(p.y for p in corners);eave=max(p.z for p in corners)
 material=bpy.data.objects['TerracottaRoof'].data.materials[0];plaster=wall.data.materials[0]
 bpy.data.objects.remove(bpy.data.objects['TerracottaRoof'],do_unlink=True)
 # Seat the shell below the wall top so its front/rear overhang cannot leave
 # a daylight slit. Gable tips finish inside the 18 cm roof thickness.
 x=w/2;y=d/2+.22;z=eave+.04
 if kind=='gable_z':
  top=[(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z),(0,-y,z+rise),(0,y,z+rise)]
  faces=[(0,4,5,3),(4,1,2,5)]
  for sign in [-1,1]:
   front=sign*d/2;back=front-sign*.18
   solid_prism('RoofGableWall'+str(sign),[(-x,front,eave),(x,front,eave),(0,front,eave+rise),(-x,back,eave),(x,back,eave),(0,back,eave+rise)],[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],plaster)
 elif kind=='gable_x':
  top=[(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z),(-x,0,z+rise),(x,0,z+rise)]
  faces=[(0,1,5,4),(4,5,2,3)]
  for sign in [-1,1]:
   front=sign*x;back=front-sign*.18
   solid_prism('RoofGableWall'+str(sign),[(front,-d/2,eave),(front,d/2,eave),(front,0,eave+rise),(back,-d/2,eave),(back,d/2,eave),(back,0,eave+rise)],[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],plaster)
 elif kind=='hip_x':
  top=[(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z),(-w*.25,0,z+rise),(w*.25,0,z+rise)]
  faces=[(0,1,5,4),(4,5,2,3),(0,4,3),(1,2,5)]
 else:
  top=[(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z),(0,-d*.25,z+rise),(0,d*.25,z+rise)]
  faces=[(0,4,5,3),(4,1,2,5),(0,1,4),(3,5,2)]
 roof=shell('TerracottaRoof',top,faces,material)
 after={n:fingerprint(bpy.data.objects[n]) for n in before}
 assert before==after,'Facade changed in '+name
 stats=roof_stats(roof);assert stats['nonmanifold_roof_edges']==0 and stats['roof_height']>1.5
 stats.update({'kind':kind,'facades_unchanged':before==after,'facade_fingerprints':before,'wall_width':w,'wall_depth':d,'wall_top':eave,'side_overhang':0,'front_rear_overhang':.22})
 report['modules'][name]=stats;save(name,True)

# Existing links: keep every original facade and upper roof triangle. Add roof
# undersides/skirt edges, bottom closures, and closed gable/return prisms.
bpy.ops.wm.open_mainfile(filepath=str(SRC/'architectural_links.blend'))
if bpy.context.scene.get('turbo_roof_revision',0):raise RuntimeError('Link roofs already corrected.')
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 bm=bmesh.new();bm.from_mesh(obj.data);uv=bm.loops.layers.uv.active
 gable_layer=bm.faces.layers.int.new('roof_gable')
 old_faces=list(bm.faces);roof_faces={f for f in old_faces if obj.data.materials[f.material_index].name.startswith('City_Roof')}
 # Clipped roof patches can meet at a point without sharing a face edge.
 # Give each vertex fan its own vertex before thickening; otherwise the
 # vertical shell seam at that point would have four incident side faces.
 corner_map={}
 for v in {v for f in roof_faces for v in f.verts}:
  pending={f for f in v.link_faces if f in roof_faces}
  while pending:
   seed=pending.pop();fan={seed};todo=[seed]
   while todo:
    face=todo.pop()
    for edge in face.edges:
     if v not in edge.verts:continue
     for neighbor in edge.link_faces:
      if neighbor in pending:pending.remove(neighbor);fan.add(neighbor);todo.append(neighbor)
   vertex=bm.verts.new(v.co)
   for f in fan:corner_map[(f,v)]=vertex
 rebuilt=set()
 for f in roof_faces:
  fresh=bm.faces.new([corner_map[(f,v)] for v in f.verts]);fresh.material_index=f.material_index
  if uv:
   for old,new in zip(f.loops,fresh.loops):new[uv].uv=old[uv].uv
  rebuilt.add(fresh)
 bmesh.ops.delete(bm,geom=list(roof_faces),context='FACES_ONLY')
 old_faces=[f for f in old_faces if f.is_valid]+list(rebuilt)
 roof_faces=rebuilt
 roof_verts={v for f in roof_faces for v in f.verts}
 edges={e for f in roof_faces for e in f.edges};boundary=[]
 for edge in edges:
  fs=[f for f in edge.link_faces if f in roof_faces]
  if len(fs)==1:
   face=fs[0]
   for loop in face.loops:
    if loop.edge==edge:boundary.append((loop.vert,loop.link_loop_next.vert,face.material_index));break
 original_xy={}
 for v in bm.verts:original_xy.setdefault((v.co.x,v.co.y),[]).append(v)
 body_top={}
 for face in old_faces:
  material=obj.data.materials[face.material_index].name
  if material.startswith('City_Plaster') and face.normal.z>.5:
   for v in face.verts:
    key=(v.co.x,v.co.y)
    if key not in body_top or v.co.z>body_top[key][0]:body_top[key]=(v.co.z,face.material_index)
 generated=[]
 for face in old_faces:
  material=obj.data.materials[face.material_index].name
  depth=8.0 if material.startswith('City_Plaster') else 2.55 if material=='City_Stone' else 0
  if depth==0 or face.normal.z<.5:continue
  bottom=[]
  for v in reversed(face.verts):
   point=v.co-Vector((0,0,depth));matches=original_xy.get((point.x,point.y),[])
   target=min(matches,key=lambda q:abs(q.co.z-point.z)) if matches else None
   if target is None or abs(target.co.z-point.z)>.0001:target=bm.verts.new(point)
   bottom.append(target)
  try:f=bm.faces.new(bottom);f.material_index=face.material_index;generated.append(f)
  except ValueError:pass
 underside={v:bm.verts.new(v.co-Vector((0,0,.18))) for v in roof_verts}
 for face in roof_faces:
  f=bm.faces.new([underside[v] for v in reversed(face.verts)]);f.material_index=face.material_index;generated.append(f)
 for a,b,material in boundary:
  f=bm.faces.new([a,b,underside[b],underside[a]]);f.material_index=material;generated.append(f)
 gables=0
 for a,b,_ in boundary:
  ka=(a.co.x,a.co.y);kb=(b.co.x,b.co.y)
  if ka not in body_top or kb not in body_top:continue
  low_a=Vector((a.co.x,a.co.y,body_top[ka][0]));low_b=Vector((b.co.x,b.co.y,body_top[kb][0]))
  high_a=Vector((a.co.x,a.co.y,max(low_a.z,a.co.z-.18)));high_b=Vector((b.co.x,b.co.y,max(low_b.z,b.co.z-.18)))
  if max(high_a.z-low_a.z,high_b.z-low_b.z)<.01:continue
  edge=b.co-a.co;edge.z=0
  if edge.length<1e-6:continue
  inward=Vector((-edge.y,edge.x,0)).normalized()*.16
  points=[low_a,low_b,high_b,high_a]
  points+= [p+inward for p in points]
  vertices=[];mapping=[]
  for p in points:
   found=next((i for i,q in enumerate(vertices) if (p-q.co).length<1e-7),None)
   if found is None:found=len(vertices);vertices.append(bm.verts.new(p))
   mapping.append(found)
  for ids in [(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]:
   ids=list(dict.fromkeys(mapping[i] for i in ids))
   if len(ids)<3:continue
   f=bm.faces.new([vertices[i] for i in ids]);f.material_index=body_top[ka][1];f[gable_layer]=1;generated.append(f)
  gables+=1
 bm.normal_update()
 for face in generated:
  if uv:
   for loop in face.loops:
    p=loop.vert.co;loop[uv].uv=(p.x/2,-p.y/2) if abs(face.normal.z)>.45 else (p.x/2,p.z/2)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
 close_bases(obj)
 report['links'][obj.name]=roof_stats(obj)
 report['links'][obj.name]['closed_gable_returns']=gables
 print('LINK_STATS',obj.name,report['links'][obj.name],flush=True);assert report['links'][obj.name]['nonmanifold_roof_edges']==0,obj.name
save('architectural_links')

