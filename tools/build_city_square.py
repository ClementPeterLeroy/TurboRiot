"""Offline, editable City Square architecture and site mesh authoring.
No owner Blender files or previous circuit assets are modified.
"""
from pathlib import Path
import bpy,bmesh,math,json,sys
from mathutils import Vector,geometry
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/environment/city_square';SRC=OUT/'sources'
SRC.mkdir(parents=True,exist_ok=True);(SRC/'.gdignore').write_text('')
if any(SRC.glob('*.blend')) and '--replace-generated' not in sys.argv:raise SystemExit('Sources exist: review edits before --replace-generated.')
SURVEY=json.loads((ROOT/'resources/tracks/city_square/survey.json').read_text())
ROWS=SURVEY['samples'];BRANCHES=SURVEY['branches']
MANIFEST={'houses':[],'assets':[],'sectors':{},'house_sizes':[]}

def start(color=(.85,.72,.52)):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.context.preferences.filepaths.save_version=0
 bpy.context.scene.unit_settings.system='METRIC'
 global MAT
 palette={'Plaster':color,'Roof':(.69,.29,.16),'Trim':(.86,.81,.65),'Shutters':(.17,.39,.38),'Wood':(.32,.20,.11),'Glass':(.13,.29,.35),'Stone':(.67,.64,.53),'Grass':(.32,.50,.27),'Earth':(.55,.49,.35),'Sea':(.15,.46,.64)}
 MAT={}
 for name,c in palette.items():
  m=bpy.data.materials.new('City_'+name);m.use_nodes=True;m.use_backface_culling=True
  linear=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c)
  m.diffuse_color=(*linear,1);m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*linear,1)
  m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.88
  MAT[name]=m

def bv(p):return(p[0],-p[2],p[1])
def mesh(name,v,faces,paint):
 data=bpy.data.meshes.new(name);data.from_pydata([bv(p) for p in v],[],faces);data.update()
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(data);bm.free()
 if name in ['TownLand','GardenGrass','HarbourIsland']:
  bm=bmesh.new();bm.from_mesh(data)
  for face in bm.faces:
   if face.normal.z<0:face.normal_flip()
  bm.to_mesh(data);bm.free()
 uv=data.uv_layers.new(name='RepeatedMetres')
 for face in data.polygons:
  for loop in face.loop_indices:
   p=data.vertices[data.loops[loop].vertex_index].co
   uv.data[loop].uv=(p.x/2,-p.y/2) if abs(face.normal.z)>.45 else (p.x/2,p.z/2)
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(MAT[paint]);return obj

def box(name,c,size,paint,f=None):
 c=Vector(c);f=Vector((0,0,1)) if f is None else Vector(f).normalized()
 r=Vector((f.z,0,-f.x)).normalized() if math.hypot(f.x,f.z)>.0001 else Vector((1,0,0));u=f.cross(r).normalized()
 v=[c+r*x*size[0]/2+u*y*size[1]/2+f*z*size[2]/2 for z in [-1,1] for y in [-1,1] for x in [-1,1]]
 return mesh(name,v,[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)],paint)

def cylinder(name,c,radius,height,paint,segments=32):
 v=[(c[0]+math.cos(i*math.tau/segments)*radius,c[1]+dy,c[2]+math.sin(i*math.tau/segments)*radius) for dy in [-height/2,height/2] for i in range(segments)]
 faces=[tuple(range(segments-1,-1,-1)),tuple(range(segments,segments*2))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
 return mesh(name,v,faces,paint)

def save(name,merge=False):
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
 if merge:
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name='House'
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_apply=True,export_cameras=False,export_lights=False,export_animations=False,will_save_settings=False)
 MANIFEST['assets'].append(name);print('CITY_ASSET',name,flush=True)

def arch_window(x,y,z,w=1,h=1.6,side=False):
 def p(a,b,d):return (d,b,a) if side else(a,b,d)
 box('WindowRecess',p(x,y,z),(w,h,.10) if not side else(.10,h,w),'Glass')
 for sign in [-1,1]:box('Shutter',p(x+sign*(w/2+.24),y,z-.06),(.37,h,.14) if not side else(.14,h,.37),'Shutters')
 box('StoneSill',p(x,y-h/2-.08,z-.10),(w+.35,.16,.32) if not side else(.32,.16,w+.35),'Trim')
 for sign in [-1,1]:box('WindowTrim',p(x+sign*(w/2+.04),y,z-.07),(.09,h+.2,.13) if not side else(.13,h+.2,.09),'Trim')
 # A simple arch hood distinguishes the upper windows without interiors.
 vertices=[]
 for i in range(13):
  theta=math.pi*i/12
  for radius in [w*.5,w*.5+.12]:vertices.append(p(x+math.cos(theta)*radius,y+h/2+math.sin(theta)*radius*.45,z-.13))
 mesh('ArchedHood',vertices,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(12)],'Trim')

# Six independently authored, reusable architectural types.
for index,(name,w,d,floors,color) in enumerate([
 ('townhouse',8,9,2,(.85,.74,.52)),('narrow_house',6,8,3,(.76,.59,.43)),
 ('wide_house',10,10,2,(.87,.80,.64)),('merchant_house',8,9,2,(.83,.58,.40)),
 ('corner_house',8,9,3,(.79,.73,.55)),('harbour_house',7,8,2,(.73,.79,.71))]):
 if '--site-only' in sys.argv:
  old=json.loads((OUT/'manifest.json').read_text())
  MANIFEST['assets'].append(name);MANIFEST['house_sizes'].append(old['house_sizes'][index])
  continue
 start(color);height=.9+floors*3.1
 box('StoneFoundation',(0,.0,0),(w,1.8,d),'Stone')
 box('StuccoWalls',(0,(height+.8)/2,0),(w,height-.8,d),'Plaster')
 for y in [.8,3.9,height]:box('HorizontalTrim',(0,y,0),(w+.15,.14,d+.15),'Trim')
 # A real pitched roof with overhang and ridge, not a flat colored cuboid.
 v=[(-w/2-.4,height,-d/2-.4),(w/2+.4,height,-d/2-.4),(-w/2-.4,height,d/2+.4),(w/2+.4,height,d/2+.4),(-w/2-.4,height+1.6,0),(w/2+.4,height+1.6,0)]
 mesh('TerracottaRoof',v,[(0,1,5,4),(4,5,3,2),(0,4,2),(1,3,5),(0,2,3,1)],'Roof')
 for floor in range(floors):
  y=2.25+floor*3.1
  for x in [-w*.26,w*.26]:
   if floor==0 and name=='merchant_house':
    box('ShopGlass',(x,y,-d/2-.05),(2.4,2.0,.12),'Glass')
    box('ShopLintel',(x,3.35,-d/2-.10),(2.6,.18,.25),'Wood')
   else:arch_window(x,y,-d/2-.06)
  if name=='corner_house':
   for z in [-2.4,1.1]:arch_window(z,y,-w/2-.06,side=True)
 box('TimberDoor',(0,1.85,-d/2-.06),(1.35,2.1,.16),'Wood')
 box('DoorLintel',(0,3.0,-d/2-.15),(1.7,.20,.30),'Trim')
 if index in [0,3,4,5]:
  box('BalconySlab',(0,4.03,-d/2-.37),(3.2,.18,.9),'Stone')
  box('BalconyToprail',(0,4.85,-d/2-.76),(3.2,.09,.09),'Wood')
  for x in [-1.5,-.75,0,.75,1.5]:box('Balusters',(x,4.45,-d/2-.76),(.07,.8,.07),'Wood')
 save(name,True);MANIFEST['house_sizes'].append([w,d,height+1.6])

def strip(name,rows,paint,width_scale=1):
 vertices=[]
 for row in rows:
  c=Vector(row['position']);r=Vector(row['right']);width=row['width']*width_scale
  vertices += [c+r*side*width*.5+Vector((0,dy,0)) for dy in [0,-.45 if paint=='Wood' else -1.2] for side in [-1,1]]
 faces=[]
 for i in range(len(rows)-1):
  a=i*4;b=a+4
  faces.extend([(a,a+1,b+1,b),(a+2,b+2,b+3,a+3),(a,b,b+2,a+2),(a+1,a+3,b+3,b+1)])
 faces += [(0,2,3,1),(len(vertices)-4,len(vertices)-3,len(vertices)-1,len(vertices)-2)]
 return mesh(name,vertices,faces,paint)

def union(name,objects):
 base=objects[0]
 for o in objects[1:]:
  bpy.context.view_layer.objects.active=base
  mod=base.modifiers.new('Seamless junction','BOOLEAN');mod.operation='UNION';mod.solver='EXACT';mod.object=o
  bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(o,do_unlink=True)
 base.name=name
 # Refresh coherent planar UVs after the authored boolean junction operation.
 uv=base.data.uv_layers.active
 for face in base.data.polygons:
  for loop in face.loop_indices:
   p=base.data.vertices[base.data.loops[loop].vertex_index].co
   uv.data[loop].uv=(p.x/2,-p.y/2)
 return base

# Dedicated streets/junction/plaza volume; smooth collision is exported below.
start();road_parts=[];wood_parts=[]
groups=[];part=[];kind=ROWS[0]['wood']
for i,row in enumerate(ROWS):
 if row['wood']!=kind:
  part.append(row);groups.append((kind,part));part=[ROWS[i-1],row];kind=row['wood']
 else:part.append(row)
groups.append((kind,part))
# Overlap the two stone ends through the lap seam before boolean union. Caps
# that only touch at the finish can survive as internal vertical collision faces.
if not groups[0][0] and not groups[-1][0]:groups[-1][1].extend(ROWS[1:3])
for i,(wood,rows) in enumerate(groups):
 obj=strip('RoadSegment%d'%i,rows,'Wood' if wood else 'Stone')
 (wood_parts if wood else road_parts).append(obj)
for i,b in enumerate(BRANCHES):road_parts.append(strip('Branch%d'%i,b['rows'],'Stone'))
f=SURVEY['fountain']
plaza=cylinder('CircularPlaza',(f[0],f[1]-.6,f[2]),29,1.2,'Stone',80);road_parts.append(plaza)
road=union('PavedStreets',road_parts)
wood=union('TimberDecks',wood_parts)
save('driving_surfaces')

# Stair treads are architecture; the road volume remains a smooth collision.
start()
def stair_tread(a,b,name):
 p=Vector(a['position']);q=Vector(b['position'])
 if p.y-q.y<=.025:return
 # Join the actual road cross-sections through corners. A thin midpoint box
 # intersects the sloped road and leaves triangular gaps/overlaps at bends.
 r=Vector(a['right'])*(a['width']/2-.1);s=Vector(b['right'])*(b['width']/2-.1)
 height=max(p.y,q.y)+.015
 top=[p-r,p+r,q+s,q-s]
 vertices=[(v.x,height,v.z) for v in top]+[(v.x,min(p.y,q.y)-.12,v.z) for v in top]
 mesh(name,vertices,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'Stone')
for a,b in zip(BRANCHES[0]['rows'],BRANCHES[0]['rows'][1:]):stair_tread(a,b,'LongStairTreads')
for a,b in zip(ROWS,ROWS[1:]):
 if BRANCHES[0]['entry']<a['offset']<BRANCHES[0]['exit']:stair_tread(a,b,'ShortStairTreads')
# Structural dock beams and vertical piles at regular actual route distance.
wood_rows=[r for r in ROWS if r['wood']]
for i in range(0,len(wood_rows)-1,9):
 a=wood_rows[i];b=wood_rows[min(i+9,len(wood_rows)-1)];p=Vector(a['position']);q=Vector(b['position']);r=Vector(a['right']);v=q-p
 for side in [-1,1]:
  beam=(p+q)/2+r*side*4.8+Vector((0,-.70,0))
  box('DockLongitudinalBeams',beam,(.42,.55,v.length+.3),'Wood',v)
  center=p+r*side*4.8
  cylinder('TimberPiles',(center.x,-.25,center.z),.38,4.0,'Wood',10)
 box('DockCrossbeams',p+Vector((0,-.80,0)),(12.6,.5,.45),'Wood',v)
save('stairs_and_dock_structure')

# Solid coast, graded town and simple garden grass; water has no collision.
start()
coast_px=[(235,75),(500,75),(540,100),(580,140),(582,175),(650,200),(650,322),(610,333),(585,360),(570,382),(570,415),(534,415),(534,490),(235,490)]
coast=[Vector(((x-520)*.75,(z-300)*.75)) for x,z in coast_px]
def inside(p,polygon):
 result=False
 for a,b in zip(polygon,polygon[1:]+polygon[:1]):
  if (a.y>p.y)!=(b.y>p.y) and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x:result=not result
 return result
all_rows=ROWS+[r for branch in BRANCHES for r in branch['rows']]
def terrain_y(x,z):
 row=min(all_rows,key=lambda r:(r['position'][0]-x)**2+(r['position'][2]-z)**2)
 return row['position'][1]-.85
verts2=list(coast)
for x in range(-210,100,8):
 for z in range(-165,150,8):
  p=Vector((x,z))
  if inside(p,coast):verts2.append(p)
edges=[(i,(i+1)%len(coast)) for i in range(len(coast))]
v,e,faces,*_=geometry.delaunay_2d_cdt(verts2,edges,[list(range(len(coast)))],1,1e-5)
vertices=[(p.x,terrain_y(p.x,p.y),p.y) for p in v]
mesh('TownLand',vertices,faces,'Earth')
cliffv=[]
for p in coast:cliffv.extend([(p.x,terrain_y(p.x,p.y),p.y),(p.x,-2,p.y)])
mesh('CoastalCliffs',cliffv,[(i*2,i*2+1,((i+1)%len(coast))*2+1,((i+1)%len(coast))*2) for i in range(len(coast))],'Stone')
# Gardens occupy a distinct low island/path approach, clear of open water.
garden=[((x-520)*.75,1.87,(z-300)*.75) for x,z in [(365,405),(432,400),(465,415),(534,415),(534,490),(360,490)]]
mesh('GardenGrass',garden,[tuple(range(len(garden)))],'Grass')
island=[((x-520)*.75,1.85,(z-300)*.75) for x,z in [(590,415),(727,415),(727,440),(703,454),(640,454),(590,442)]]
mesh('HarbourIsland',island,[tuple(range(len(island)))],'Grass')
box('Water',(0,0,0),(900,.02,800),'Sea')
save('coast_and_terrain')

start();cylinder('FountainBasin',(f[0],10.85,f[2]),6.0,.7,'Stone',48)
cylinder('BasinWater',(f[0],11.22,f[2]),5.45,.025,'Sea',48)
cylinder('FountainPedestal',(f[0],12.2,f[2]),1.0,2.5,'Stone',20)
cylinder('FountainUpperBowl',(f[0],13.2,f[2]),2.1,.35,'Stone',32)
save('fountain')

# Deterministic frontage lots. Reject a footprint if another road enters it.
size_table=MANIFEST['house_sizes'];occupied=[]
def house_ok(p,yaw,w,d):
 right=Vector((math.cos(yaw),0,-math.sin(yaw)));back=Vector((math.sin(yaw),0,math.cos(yaw)))
 for row in all_rows:
  c=Vector(row['position']);v=c-p
  # Reserve the entire road width, including branch junctions and the plaza.
  dx=max(0,abs(v.dot(right))-w/2);dz=max(0,abs(v.dot(back))-d/2)
  if math.hypot(dx,dz)<row['width']/2+.08:return False
 for q,ww,dd,angle in occupied:
  qr=Vector((math.cos(angle),0,-math.sin(angle)));qb=Vector((math.sin(angle),0,math.cos(angle)))
  if all(abs((p-q).dot(axis)) < (abs(right.dot(axis))*w+abs(back.dot(axis))*d+abs(qr.dot(axis))*ww+abs(qb.dot(axis))*dd)/2-.002 for axis in [right,back,qr,qb]):return False
 return True
# Explicit frontage blocks: consecutive lots share party-wall planes. Reserve
# intersections rather than marching separate sampled houses around every bend.
def frontage(a,b,width,label):
 a=Vector(((a[0]-520)*.75,0,(a[1]-300)*.75));b=Vector(((b[0]-520)*.75,0,(b[1]-300)*.75))
 direction=(b-a).normalized();length=(b-a).length-14
 if length<6:return
 models=[];total=0
 while True:
  model=4 if not models else [0,2,1,3][len(models)%4]
  w=size_table[model][0]
  if total+w>length:break
  models.append(model);total+=w
 for side in [-1,1]:
  outward=Vector((direction.z,0,-direction.x))*side;yaw=math.atan2(outward.x,outward.z);cursor=-total/2
  # Bezier approaches bulge beyond their control polygon. Fit a continuous
  # frontage to the actual road envelope, not to the unbaked straight chord.
  bulge=0
  for row in all_rows:
   v=Vector(row['position'])-a;along=v.dot(direction);across=v.dot(outward)
   if 0<=along<=(b-a).length and abs(across)<width*.6 and abs(Vector(row['right']).dot(outward))>.9:bulge=max(bulge,across)
  for i,model in enumerate(models):
   w,d,h=size_table[model];center=(a+b)/2+direction*(cursor+w/2);cursor+=w
   # Use the actual sampled grade while keeping the frontage in one plane.
   row=min(all_rows,key=lambda r:(r['position'][0]-center.x)**2+(r['position'][2]-center.z)**2)
   p=center+outward*(width/2+d/2+bulge+.12);p.y=row['position'][1]-.8
   if not house_ok(p,yaw,w,d):continue
   MANIFEST['houses'].append({'name':label+('_Left' if side<0 else '_Right')+'_%02d'%i,'model':model,'position':list(p),'yaw':yaw,'size':[w,d,h],'block':label+str(side),'lot':i})
   occupied.append((p,w,d,yaw))
frontage((360,440),(360,225),22,'Avenue')
for label,a,b in [
 ('PlazaExit',(400,155),(465,155)),('UpperWest',(465,155),(465,112)),
 ('UpperNorth',(475,104),(510,104)),('UpperEast',(558,133),(560,182)),
 ('ForkNorth',(560,182),(630,182)),('RightStairs',(630,182),(630,270)),
 ('LeftStairs',(560,182),(560,270)),('MergeSouth',(560,270),(630,270)),
 ('HarbourApproach',(630,270),(625,320))]:frontage(a,b,22 if label=='PlazaExit' else 20,label)
# The square is enclosed by discrete townhouses, with street portals reserved.
for i,angle in enumerate(range(0,360,16)):
 theta=math.radians(angle);outward=Vector((math.cos(theta),0,math.sin(theta)))
 model=[2,0,4,1,3][i%5];w,d,h=size_table[model]
 p=Vector(f)+outward*(29+d/2-.05);p.y=f[1]-.8
 yaw=math.atan2(outward.x,outward.z)
 if house_ok(p,yaw,w,d):
  MANIFEST['houses'].append({'name':'Square%02d'%i,'model':model,'position':list(p),'yaw':yaw,'size':[w,d,h]})
  occupied.append((p,w,d,yaw))
# Inaccessible coherent blocks behind the primary street frontage.
for ix,x in enumerate(range(270,335,14)):
 for iz,z in enumerate(range(240,425,15)):
  p=Vector(((x-520)*.75,0,(z-300)*.75));p.y=terrain_y(p.x,p.z)+.05
  model=[0,2,1,3,4][(ix+iz*2)%5];w,d,h=size_table[model]
  yaw=0 if ix%2 else math.pi
  if house_ok(p,yaw,w,d):
   MANIFEST['houses'].append({'name':'Block%02d_%02d'%(ix,iz),'model':model,'position':list(p),'yaw':yaw,'size':[w,d,h]})
   occupied.append((p,w,d,yaw))
# Harbour/island structures do not obstruct the outer timber racing platform.
for i,pixel in enumerate([(650,432),(680,432),(710,432)]):
 p=Vector(((pixel[0]-520)*.75,1.05,(pixel[1]-300)*.75))
 MANIFEST['houses'].append({'name':'Harbour%02d'%i,'model':5,'position':list(p),'yaw':math.pi,'size':size_table[5]})
(OUT/'manifest.json').write_text(json.dumps(MANIFEST,indent=2))
print('CITY_COMPLETE houses=',len(MANIFEST['houses']),flush=True)
