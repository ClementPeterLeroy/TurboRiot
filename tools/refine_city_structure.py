"""Surgical City Square edit: open existing masters, replace only requested parts.
Blender --factory-startup --disable-autoexec --background --python this_file.
Does not call the initial environment/house generator. One-shot; review subsequent
artist edits before removing the structural_revision guard in the manifest.
"""
from pathlib import Path
import bpy,bmesh,json,math,copy
from mathutils import Vector,geometry,kdtree
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/environment/city_square'; SOURCES=ASSETS/'sources'
DATA=ROOT/'resources/tracks/city_square'
survey=json.loads((DATA/'survey.json').read_text())
plan=json.loads((DATA/'structural_plan.json').read_text())
manifest=json.loads((ASSETS/'manifest.json').read_text())
if manifest.get('structural_revision',0)>=1:raise RuntimeError('Already refined. Review native/source edits before another authoring pass.')
rows=survey['samples']; branches=survey['branches']; edits=survey['height_edits']
report={'removed_houses':[],'retained_houses':[],'new_houses':[],'frontages':[],'changed_meshes':[]}

def godot(p):return Vector((p.x,p.z,-p.y))
def blender(p):return (p[0],-p[2],p[1])
def open_source(name):
 bpy.ops.wm.open_mainfile(filepath=str(SOURCES/(name+'.blend')))
 bpy.context.preferences.filepaths.save_version=0
def export_source(name):
 # The automated review pass must not leave redundant .blend1 artifacts.
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCES/(name+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(ASSETS/(name+'.glb')),export_format='GLB',export_apply=True,export_cameras=False,export_lights=False,export_animations=False,will_save_settings=False)
 print('CITY_REFINED_ASSET',name,flush=True)
def remove(obj):bpy.data.objects.remove(obj,do_unlink=True)
def mesh(name,vertices,faces,material):
 data=bpy.data.meshes.new(name);data.from_pydata([blender(p) for p in vertices],[],faces);data.update()
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
 if name=='GardenGrass' or name.endswith('_Roof'):
  for face in bm.faces:
   if face.normal.z<0:face.normal_flip()
 bm.to_mesh(data);bm.free()
 uv=data.uv_layers.new(name='RepeatedMetres')
 for face in data.polygons:
  for i in face.loop_indices:
   p=data.vertices[data.loops[i].vertex_index].co
   uv.data[i].uv=(p.x/2,-p.y/2) if abs(face.normal.z)>.45 else (p.x/2,p.z/2)
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(material);return obj
def box(name,center,size,material,forward=Vector((0,0,1))):
 c=Vector(center);f=Vector(forward).normalized();r=Vector((f.z,0,-f.x)).normalized();u=f.cross(r).normalized()
 v=[c+r*x*size[0]/2+u*y*size[1]/2+f*z*size[2]/2 for z in [-1,1] for y in [-1,1] for x in [-1,1]]
 return mesh(name,v,[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)],material)
def inside(p,polygon):
 value=False
 for a,b in zip(polygon,polygon[1:]+polygon[:1]):
  if (a.y>p.y)!=(b.y>p.y) and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x:value=not value
 return value
def flat(p):return Vector((p[0],p[2]))
def hull(poly):return [poly[i] for i in geometry.convex_hull_2d(poly)]
def rect(p,yaw,w,d):
 r=Vector((math.cos(yaw),-math.sin(yaw)));b=Vector((math.sin(yaw),math.cos(yaw)));c=flat(p)
 return [c-r*w/2-b*d/2,c+r*w/2-b*d/2,c+r*w/2+b*d/2,c-r*w/2+b*d/2]
def overlaps(a,b):
 for polygon in [a,b]:
  for p,q in zip(polygon,polygon[1:]+polygon[:1]):
   axis=Vector((-(q-p).y,(q-p).x)).normalized()
   aa=[v.dot(axis) for v in a];bb=[v.dot(axis) for v in b]
   if max(aa)<=min(bb)+.003 or max(bb)<=min(aa)+.003:return False
 return True
def strip_poly(a,b):
 p=flat(a['position']);q=flat(b['position']);r=Vector((a['right'][0],a['right'][2]))*a['width']/2;s=Vector((b['right'][0],b['right'][2]))*b['width']/2
 return hull([p-r,p+r,q+s,q-s])
road_polys=[strip_poly(a,b) for a,b in zip(rows,rows[1:])]
for route in branches:road_polys.extend(strip_poly(a,b) for a,b in zip(route['rows'],route['rows'][1:]))
fountain=Vector((survey['fountain'][0],survey['fountain'][2]))
road_polys.append([fountain+Vector((math.cos(i*math.tau/96),math.sin(i*math.tau/96)))*29 for i in range(96)])

# Height deltas are recorded by the vertical-only curve editor. Reuse existing
# paving vertices/UVs, correcting its local floors and collapsed faces only.
tree=kdtree.KDTree(len(edits))
for i,e in enumerate(edits):tree.insert(Vector((e['old'][0],0,e['old'][2])),i)
tree.balance()
def height_delta(p):
 if not (14<p.x<100 and -105<p.z<-5):return 0
 candidates=tree.find_n(Vector((p.x,0,p.z)),4)
 weights=[1/max(.15,c[2])**3 for c in candidates]
 return sum((edits[c[1]]['new'][1]-edits[c[1]]['old'][1])*w for c,w in zip(candidates,weights))/sum(weights)

# Resolve the union's actual upper surface at junctions. Nearest centreline
# alone can assign an adjacent higher street's delta to a lower overlapping
# surface and excavate a hole in the junction.
surface_triangles=[]
for data in [rows]+[b['rows'] for b in branches]:
 for a,b in zip(data,data[1:]):
  p=Vector(a['position']);q=Vector(b['position']);r=Vector(a['right'])*a['width']/2;t=Vector(b['right'])*b['width']/2
  vertices=[p-r,p+r,q+t,q-t]
  if max(v.x for v in vertices)<10 or min(v.x for v in vertices)>105 or max(v.z for v in vertices)<-110 or min(v.z for v in vertices)>0:continue
  for indices in [(0,1,2),(0,2,3)]:surface_triangles.append([vertices[i] for i in indices])
def paved_height(p):
 heights=[];point=flat(p)
 for a,b,c in surface_triangles:
  x=flat(b)-flat(a);y=flat(c)-flat(a);v=point-flat(a);den=x.cross(y)
  if abs(den)<1e-8:continue
  t=v.cross(y)/den;u=x.cross(v)/den
  if t>=-1e-4 and u>=-1e-4 and t+u<=1.0001:heights.append(a.y*(1-t-u)+b.y*t+c.y*u)
 return max(heights) if heights else None

def displace_paving(paved):
 top=set();bottom=set()
 for face in paved.data.polygons:
  if face.normal.z>.05:top.update(face.vertices)
  elif face.normal.z<-.05:bottom.update(face.vertices)
 for vertex in paved.data.vertices:
  p=godot(vertex.co)
  if not (10<p.x<105 and -110<p.z<0):continue
  target=paved_height(p)
  if target is None:continue
  # Re-level the actual upward floor faces. An overlap can contain a downward
  # interior face above the walkable floor; treating that face as the old top
  # excavates the real floor. Keep lower faces below the new support surface.
  if vertex.index in top:vertex.co.z=target
  elif vertex.index in bottom:vertex.co.z=target-1.2
  else:vertex.co.z=max(target-1.2,min(target,vertex.co.z))
 paved.data.update()
 bm=bmesh.new();bm.from_mesh(paved.data)
 dead=[f for f in bm.faces if f.calc_area()<1e-9]
 if dead:bmesh.ops.delete(bm,geom=dead,context='FACES_ONLY')
 bm.to_mesh(paved.data);bm.free()

open_source('driving_surfaces')
paved=bpy.data.objects['PavedStreets']
displace_paving(paved)
wood_material=bpy.data.objects['TimberDecks'].data.materials[0]
remove(bpy.data.objects['TimberDecks'])
wood_rows=[r for r in rows if r['wood']]
v=[]
for row in wood_rows:
 p=Vector(row['position']);r=Vector(row['right'])
 v.extend(p+r*side*plan['dock_width']/2+Vector((0,dy,0)) for dy in [0,-.45] for side in [-1,1])
faces=[]
for i in range(len(wood_rows)-1):
 a=i*4;b=a+4;faces.extend([(a,a+1,b+1,b),(a+2,b+2,b+3,a+3),(a,b,b+2,a+2),(a+1,a+3,b+3,b+1)])
faces.extend([(0,2,3,1),(len(v)-4,len(v)-3,len(v)-1,len(v)-2)])
mesh('TimberDecks',v,faces,wood_material)
export_source('driving_surfaces');report['changed_meshes']+=['PavedStreets:Y only','TimberDecks:19.5m']

open_source('stairs_and_dock_structure')
stone=next(o.data.materials[0] for o in bpy.context.scene.objects if o.name.startswith('LongStair'))
wood=next(o.data.materials[0] for o in bpy.context.scene.objects if o.name.startswith('Dock'))
for o in list(bpy.context.scene.objects):remove(o)
for fi,flight in enumerate(survey['stair_flights']):
 a=Vector(flight['start']);b=Vector(flight['end']);forward=b-a;forward.y=0;length=forward.length;forward.normalize()
 count=math.ceil(length/.75)
 for i in range(count):
  t=i/count;end=(i+1)/count;middle=(t+end)/2;p=a.lerp(b,middle)
  # Straight, horizontal architectural treads over the continuous incline.
  height=a.y-(a.y-b.y)*(t*t*(3-2*t))+.015
  p.y=height-.13
  box(('LongStairTreads' if flight['side']=='left' else 'ShortStairTreads')+f'_Flight{fi}_Step{i}',p,(19.8,.26,length/count+.006),stone,forward)
for i in range(0,len(wood_rows)-1,9):
 a=wood_rows[i];b=wood_rows[min(i+9,len(wood_rows)-1)];p=Vector(a['position']);q=Vector(b['position']);r=Vector(a['right']);f=q-p
 for side in [-1,1]:
  offset=plan['dock_width']/2-1.7
  box('DockLongitudinalBeams',(p+q)/2+r*side*offset+Vector((0,-.7,0)),(.42,.55,f.length+.3),wood,f)
  c=p+r*side*offset;vertices=[(c.x+math.cos(j*math.tau/10)*.38,y,c.z+math.sin(j*math.tau/10)*.38) for y in [-2.25,1.75] for j in range(10)]
  fs=[tuple(range(9,-1,-1)),tuple(range(10,20))]+[(j,(j+1)%10,(j+1)%10+10,j+10) for j in range(10)]
  mesh('TimberPiles',vertices,fs,wood)
 box('DockCrossbeams',p+Vector((0,-.8,0)),(plan['dock_width']-.4,.5,.45),wood,f)
export_source('stairs_and_dock_structure')

# Constrained triangles share the real road edges, with no coincident grass
# underneath paving. This makes surface tags deterministic at road/grass joins.
open_source('coast_and_terrain')
if bpy.data.objects.get('HarbourIsland'):remove(bpy.data.objects['HarbourIsland'])
grass=bpy.data.objects['GardenGrass'];grass_material=grass.data.materials[0]
garden=[Vector(p) for p in plan['garden_polygon']]
remove(grass)
garden_rows=[r for r in rows if r['offset']>940]
quads=[strip_poly(a,b) for a,b in zip(garden_rows,garden_rows[1:])]
vertices2=[];edges=[];polygons=[]
def constraint(poly):
 start=len(vertices2);vertices2.extend(poly);ids=list(range(start,len(vertices2)));polygons.append(ids)
 edges.extend(zip(ids,ids[1:]+ids[:1]))
constraint(garden)
for quad in quads:constraint(quad)
for x in range(-120,12,2):
 for z in range(74,144,2):
  p=Vector((x,z))
  if inside(p,garden):vertices2.append(p)
vs,es,fs,*_=geometry.delaunay_2d_cdt(vertices2,edges,polygons,0,1e-5,False)
kept=[f for f in fs if inside(sum((vs[i] for i in f),Vector((0,0)))/len(f),garden) and not any(inside(sum((vs[i] for i in f),Vector((0,0)))/len(f),q) for q in quads)]
def grass_height(p):
 candidates=[]
 for a,b in zip(garden_rows,garden_rows[1:]):
  x=flat(a['position']);edge=flat(b['position'])-x
  t=max(0,min(1,(p-x).dot(edge)/max(1e-8,edge.length_squared)))
  distance=max(0,(p-x-edge*t).length-(a['width']+(b['width']-a['width'])*t)/2)
  candidates.append((distance,a['position'][1]+(b['position'][1]-a['position'][1])*t))
 candidates.sort(key=lambda c:c[0]);nearest,height=candidates[0]
 if nearest<=1.5:return height
 weighted=sum(y/max(1,d)**4 for d,y in candidates)/sum(1/max(1,d)**4 for d,y in candidates)
 t=max(0,min(1,(nearest-1.5)/8));t=t*t*(3-2*t)
 return height*(1-t)+weighted*t
mesh('GardenGrass',[(p.x,grass_height(p),p.y) for p in vs],kept,grass_material)
land=bpy.data.objects['TownLand']
city_rows=[r for r in rows if branches[0]['entry']-10<r['offset']<branches[0]['exit']+10]+branches[0]['rows']
for vertex in land.data.vertices:
 p=godot(vertex.co)
 if -124<p.x<15 and 71<p.z<146:vertex.co.z=min(vertex.co.z,1.55)
 if 10<p.x<105 and -110<p.z<0:
  near=[r['position'][1] for r in city_rows if (flat(r['position'])-flat(p)).length<18]
  if near:vertex.co.z=min(vertex.co.z,min(near)-1.45)
land.data.update()
export_source('coast_and_terrain');report['changed_meshes']+=['HarbourIsland:removed','GardenGrass:continuous road-edge height','TownLand:under garden only']
land_bvh=BVHTree.FromObject(land,bpy.context.evaluated_depsgraph_get())
def foundation_depth(item):
 x,y,z=item['position'];hit=land_bvh.ray_cast(Vector((x,-z,35)),Vector((0,0,-1)),45)[0]
 return max(0,y-.9-hit.z+.15) if hit else 0

# Preserve the existing street houses; remove only the purple background group
# and the three island houses. Adjust Y on affected stairs, never their XZ/yaw.
retained=[]
for h in manifest['houses']:
 if any(h['name'].startswith(prefix) for prefix in plan['remove_house_prefixes']):report['removed_houses'].append(h['name']);continue
 item=copy.deepcopy(h);p=Vector(item['position']);item['position'][1]+=height_delta(p)
 item['foundation_extension']=foundation_depth(item)
 retained.append(item);report['retained_houses'].append(h['name'])
manifest['houses']=retained
footprints=[rect(h['position'],h['yaw'],h['size'][0],h['size'][1]) for h in retained]
def allowed(poly):return not any(overlaps(poly,q) for q in road_polys) and not any(overlaps(poly,q) for q in footprints)
def lerp_row(data,s):
 for a,b in zip(data,data[1:]):
  if a['offset']<=s<=b['offset']:
   t=(s-a['offset'])/max(.0001,b['offset']-a['offset']);p=Vector(a['position']).lerp(Vector(b['position']),t);r=Vector(a['right']).lerp(Vector(b['right']),t).normalized();return p,r,a['width']
 r=data[-1];return Vector(r['position']),Vector(r['right']),r['width']
guides=[]
for desc in plan['frontages']:
 points=[];normals=[];heights=[]
 if desc['kind'] in ['main','left']:
  source=rows if desc['kind']=='main' else branches[0]['rows']
  for i in range(math.ceil((desc['end']-desc['start'])/1.0)+1):
   s=min(desc['end'],desc['start']+i);p,r,w=lerp_row(source,s);normal=r*desc['side']
   q=p+normal*(w/2+.03);points.append(flat(q));normals.append(flat(normal));heights.append(p.y)
 elif desc['kind']=='plaza':
  for angle in range(desc['start'],desc['end']+1,2):
   n=Vector((math.cos(math.radians(angle)),math.sin(math.radians(angle))));radius=29
   # Find the actual outer edge of the plaza/curve union along this ray.
   for distance in [29+i*.2 for i in range(61)]:
    if any(inside(fountain+n*distance,q) for q in road_polys):radius=distance+.05
   points.append(fountain+n*radius);normals.append(n);heights.append(10.5)
 else:
  raw=[Vector(p) for p in desc['points']]
  for a,b in zip(raw,raw[1:]):
   direction=(b-a).normalized();normal=Vector((direction.y,-direction.x))*desc['side']
   for i in range(math.ceil((b-a).length)):
    p=a.lerp(b,i/math.ceil((b-a).length));points.append(p);normals.append(normal)
    heights.append(grass_height(p) if desc['name']=='GardenTownEdge' else 2.0)
 points=list(points)
 if len(points)<2:continue
 # Repeat existing modules deliberately along each named red frontage.
 cursor=3.8;stations=[0]
 for a,b in zip(points,points[1:]):stations.append(stations[-1]+(b-a).length)
 count=0
 while cursor<stations[-1]-3:
  model=[0,2,3,1,4,5][count%6];w,d,h=manifest['house_sizes'][model]
  i=min(range(len(stations)),key=lambda i:abs(stations[i]-cursor));n=normals[i]
  center=points[i]+n*d/2;p=[center.x,heights[i]-.8,center.y];yaw=math.atan2(n.x,n.y)
  poly=rect(p,yaw,w,d)
  if allowed(poly):
   name=desc['name']+'_House%02d'%count;item={'name':name,'model':model,'position':p,'yaw':yaw,'size':[w,d,h],'palette':count%4,'structural_added':True}
   item['foundation_extension']=foundation_depth(item)
   manifest['houses'].append(item);footprints.append(poly);report['new_houses'].append(name)
  cursor+=w;count+=1
 guides.append({'name':desc['name'],'points':points,'normals':normals,'heights':heights})

# Simple closed architectural links fill remaining frontage gaps through corners.
# They are real roofed buildings with facade openings, not collision-only walls.
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(str(SOURCES/'townhouse.blend'),link=False) as (src,dst):dst.materials=[n for n in src.materials if n.startswith('City_')]
materials={m.name:m for m in bpy.data.materials}
def vary_frontage(obj,guide):
 stations=[0]
 for a,b in zip(guide['points'],guide['points'][1:]):stations.append(stations[-1]+(b-a).length)
 palette={'City_Plaster':[(.85,.74,.52),(.87,.72,.58),(.89,.82,.66),(.78,.72,.57)],'City_Roof':[(.69,.29,.16),(.62,.26,.15),(.74,.36,.21)]}
 slots={}
 for base,colors in palette.items():
  for i,c in enumerate(colors):
   name=base+'Shade'+str(i)
   paint=bpy.data.materials.get(name)
   if paint is None:
    paint=materials[base].copy();paint.name=name
    linear=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c)
    paint.diffuse_color=(*linear,1);paint.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*linear,1)
   slots[name]=len(obj.data.materials);obj.data.materials.append(paint)
 for face in obj.data.polygons:
  original=obj.data.materials[face.material_index].name
  if original not in palette:continue
  p=flat(godot(face.center));i=min(range(len(guide['points'])),key=lambda i:(guide['points'][i]-p).length_squared)
  variant=int(stations[i]/8)%len(palette[original])
  face.material_index=slots[original+'Shade'+str(variant)]
used_bands=[]
for guide in guides:
 subject=[]
 for i in range(len(guide['points'])-1):
  a,b=guide['points'][i:i+2];n,m=guide['normals'][i:i+2];subject.append(hull([a,b,b+m*6.5,a+n*6.5]))
 # Limit cutters to the frontage bounding box before CDT subdivision.
 allp=[p for poly in subject for p in poly];low=Vector((min(p.x for p in allp),min(p.y for p in allp)));high=Vector((max(p.x for p in allp),max(p.y for p in allp)))
 cutters=[q for q in road_polys+footprints+used_bands if max(p.x for p in q)>=low.x and min(p.x for p in q)<=high.x and max(p.y for p in q)>=low.y and min(p.y for p in q)<=high.y]
 pts=[];ed=[];polys=[]
 for poly in subject+cutters:
  start=len(pts);pts.extend(poly);ids=list(range(start,len(pts)));ed.extend(zip(ids,ids[1:]+ids[:1]));polys.append(ids)
 ridge=[]
 for p,n in zip(guide['points'],guide['normals']):ridge.append(len(pts));pts.append(p+n*3.25)
 ed.extend(zip(ridge,ridge[1:]))
 vv,ee,ff,*_=geometry.delaunay_2d_cdt(pts,ed,polys,0,1e-5,False)
 triangles=[]
 for face in ff:
  c=sum((vv[i] for i in face),Vector((0,0)))/len(face)
  if any(inside(c,p) for p in subject) and not any(inside(c,p) for p in cutters):triangles.append(face)
 if not triangles:continue
 def base(p):
  i=min(range(len(guide['points'])),key=lambda i:(guide['points'][i]-p).length_squared)
  return guide['heights'][i]
 # Only boundary edges receive facade walls; interior triangulation is hidden.
 counts={}
 for face in triangles:
  for a,b in zip(face,face[1:]+face[:1]):counts[tuple(sorted((a,b)))]=counts.get(tuple(sorted((a,b))),0)+1
 boundary=[e for e,n in counts.items() if n==1]
 verts=[(p.x,base(p)-.8,p.y) for p in vv]+[(p.x,base(p)+7.2,p.y) for p in vv]
 n=len(vv);walls=[(a,b,b+n,a+n) for a,b in boundary]
 mesh(guide['name']+'_Infill',verts,walls+[tuple(i+n for i in f) for f in triangles],materials['City_Plaster'])
 footing=[(p.x,base(p)-2.5,p.y) for p in vv]+[(p.x,base(p)+.05,p.y) for p in vv]
 mesh(guide['name']+'_Footings',footing,walls+[tuple(i+n for i in f) for f in triangles],materials['City_Stone'])
 def roof_height(p):
  i=min(range(len(guide['points'])),key=lambda i:(guide['points'][i]-p).length_squared)
  depth=(p-guide['points'][i]).dot(guide['normals'][i])
  return base(p)+7.25+1.4*max(0,1-abs(depth-3.25)/3.25)
 roofverts=[(p.x,roof_height(p),p.y) for p in vv]
 mesh(guide['name']+'_Roof',roofverts,triangles,materials['City_Roof'])
 facade_windows=0
 for i in range(1,len(guide['points'])-1,3):
  p=guide['points'][i];normal=guide['normals'][i];behind=p+normal*.12
  if any(inside(behind,q) for q in footprints+road_polys+used_bands):continue
  pos=Vector((p.x,guide['heights'][i]+2.15,p.y));f=Vector((normal.x,0,normal.y));r=Vector((f.z,0,-f.x))
  for floor in range(2):
   center=pos+Vector((0,floor*3,0))
   box('LinkWindow',center-f*.025,(1.05,1.45,.10),materials['City_Glass'],f)
   for side in [-1,1]:box('LinkShutter',center+r*side*.68-f*.06,(.28,1.45,.12),materials['City_Shutters'],f)
   box('LinkSill',center+Vector((0,-.8,0))-f*.11,(1.65,.15,.3),materials['City_Trim'],f)
  facade_windows+=1
 # Join a frontage into one editable mesh, retaining shared material surfaces.
 objects=list(bpy.context.scene.objects)
 objects=[o for o in objects if o.name.startswith(guide['name']) or o.name.startswith('Link')]
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=guide['name']
 vary_frontage(objects[0],guide)
 report['frontages'].append({'name':guide['name'],'new_windows':facade_windows,'length':sum((b-a).length for a,b in zip(guide['points'],guide['points'][1:])),'infill_triangles':len(triangles)})
 used_bands.extend(subject)
export_source('architectural_links')
manifest['structural_revision']=1;manifest['structural_frontages']=[g['name'] for g in guides]
report['frontage_paths']=[{'name':g['name'],'points':[[p.x,y,p.y] for p,y in zip(g['points'],g['heights'])],'normals':[[n.x,n.y] for n in g['normals']]} for g in guides]
(ASSETS/'manifest.json').write_text(json.dumps(manifest,indent=2))
(DATA/'structural_report.json').write_text(json.dumps(report,indent=2))
print('CITY_STRUCTURAL_COMPLETE houses=',len(manifest['houses']),'added=',len(report['new_houses']),'removed=',len(report['removed_houses']),'frontages=',len(report['frontages']),flush=True)
