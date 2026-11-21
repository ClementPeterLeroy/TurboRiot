"""Explicit authoring, not runtime generation. Editable sources and instances.
Run with Blender --background --python tools/build_yoshi_environment.py.
Existing outputs require -- --replace-generated; artist edits otherwise survive.
"""
from pathlib import Path
import ast,json,math,sys
import bpy,bmesh
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/environment/yoshi';SOURCES=OUT/'sources'
SCENES=ROOT/'scenes/environment/yoshi'
for d in [OUT,SOURCES,SCENES]:d.mkdir(parents=True,exist_ok=True)
if (SOURCES/'island.blend').exists() and '--replace-generated' not in sys.argv:
    raise SystemExit('Existing artist sources: explicitly use -- --replace-generated to rebuild.')
(SOURCES/'.gdignore').write_text('')
# Reuse the existing authoring functions, without executing its asset-building
# statements or modifying Circuit 8 outputs.
code=(ROOT/'tools/build_figure8_environment.py').read_text()
for node in ast.parse(code).body:
    if isinstance(node,ast.FunctionDef):exec(compile(ast.Module(body=[node],type_ignores=[]),'shared_asset_authoring','exec'))
plan=json.loads((ROOT/'resources/tracks/yoshi_environment_layout.json').read_text())
def sphere(name,pos,scale,paint):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=bv(pos))
    o=bpy.context.object;o.name=name;o.scale=(scale[0],scale[2],scale[1]);o.data.materials.append(paint)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return o
def v(v):return 'Vector3('+','.join('%.6f'%x for x in v)+')'
def shape(name,size):return '[sub_resource type="BoxShape3D" id="%s"]\nsize = %s'%(name,v(size))
def tf(pos,f):
    f=Vector(f).normalized();r=f.cross(Vector((0,1,0))).normalized();up=r.cross(f)
    return 'Transform3D('+','.join('%.7f'%axis[row] for row in range(3) for axis in [r,up,-f])+','+','.join('%.7f'%x for x in pos)+')'
def wrapper(name,collider=None):
    lines=['[gd_scene format=3]','[ext_resource type="PackedScene" path="res://assets/environment/yoshi/%s.glb" id="Model"]'%name]
    if collider:lines.append(shape('Collision',collider[1]))
    lines+=['[node name="%s" type="Node3D"]'%name,'[node name="Model" parent="." instance=ExtResource("Model")]']
    if collider:lines+=['[node name="Body" type="StaticBody3D" parent="."]','[node name="Shape" type="CollisionShape3D" parent="Body"]\nposition = %s\nshape = SubResource("Collision")'%v(collider[0])]
    (SCENES/(name+'.tscn')).write_text('\n\n'.join(lines)+'\n')

# Coastal island: a deliberately authored outline, simple sand rim and cliffs.
start();green=material('Garden_Grass',(.32,.60,.38));sand=material('Warm_Sand',(.85,.72,.46));rock=material('Coastal_Stone',(.39,.49,.46))
points=[Vector((x,0,z)) for x,z in plan['coast']]
triangles=tessellate_polygon([[Vector(bv(p)) for p in points]])
faces=[];collision=[]
for tri in triangles:
    indices=[q if isinstance(q,int) else next(i for i,p in enumerate(points) if (Vector(bv(p))-q).length<.001) for q in tri]
    if (points[indices[1]]-points[indices[0]]).cross(points[indices[2]]-points[indices[0]]).y>0:indices.reverse()
    faces.append(tuple(indices));collision.extend([[points[i].x,-.08,points[i].z] for i in indices])
land=mesh('IslandTop',[(p.x,-.08,p.z) for p in points],faces,green)
bm=bmesh.new();bm.from_mesh(land.data);bm.normal_update()
for face in bm.faces:
    if face.normal.z<0:face.normal_flip()
bm.to_mesh(land.data);bm.free()
rim_v=[];rim_f=[];cliff_v=[];cliff_f=[]
for i,a in enumerate(points):
    b=points[(i+1)%len(points)]
    ao=a+Vector((a.x,0,a.z)).normalized()*4;bo=b+Vector((b.x,0,b.z)).normalized()*4
    k=len(rim_v);rim_v += [(a.x,-.08,a.z),(b.x,-.08,b.z),(bo.x,-.25,bo.z),(ao.x,-.25,ao.z)];rim_f.append((k,k+1,k+2,k+3))
    k=len(cliff_v);cliff_v += [(ao.x,-.25,ao.z),(bo.x,-.25,bo.z),(bo.x,-3.8,bo.z),(ao.x,-3.8,ao.z)];cliff_f.append((k,k+1,k+2,k+3))
mesh('SandShore',rim_v,rim_f,sand);mesh('CliffSides',cliff_v,cliff_f,rock);save('island')
plan['island_collision']=collision

# Reusable broadleaf tree. Named parts remain editable in its Blender source.
start();bark=material('Bark',(.30,.19,.11));leaf=material('Leaf_Green',(.18,.43,.20));light=material('Leaf_Sunlit',(.33,.59,.24))
box('Trunk',(0,2,0),(.7,4,.7),bark)
canopies=[sphere('Crown',(-1.2,5.7,0),(2.7,2.6,2.8),leaf),sphere('Crown',(1.5,5.9,.5),(2.4,2.4,2.5),leaf),sphere('Crown',(0,7.1,-.3),(2.5,2.4,2.4),light)]
batch('Foliage',canopies);save('garden_tree');wrapper('garden_tree',((0,1.8,0),(.8,3.6,.8)))

# A complete flowerbed is one reusable prop, not hundreds of scene nodes.
start();petal=material('Flower_Coral',(.95,.43,.36));yellow=material('Flower_Center',(.97,.79,.25));leaves=material('Flower_Leaves',(.20,.43,.22));white=material('Flower_Cream',(.98,.91,.72))
parts=[]
for i,(x,z) in enumerate([(-1.3,-.5),(0,-.6),(1.2,-.4),(-.8,.65),(.65,.6)]):
    parts.append(box('Stem',(x,.3,z),(.07,.6,.07),leaves))
    parts.append(sphere('Center',(x,.68,z),(.16,.12,.16),yellow))
    for angle in range(5):
        a=angle*math.tau/5;parts.append(sphere('Petal',(x+math.cos(a)*.26,.64,z+math.sin(a)*.26),(.23,.09,.20),petal if i%2 else white))
batch('Flowerbed',parts);save('flowerbed');wrapper('flowerbed')

# Stone tunnel shell, open at both ends. Collision uses the same arch wedges.
start();stone=material('Tunnel_Stone',(.62,.70,.64));trim=material('Tunnel_Trim',(.90,.82,.59));moss=material('Tunnel_GardenRoof',(.25,.46,.24))
arches=[];arch_shapes=[]
for i in range(12):
    a=i*math.pi/12;b=(i+1)*math.pi/12
    verts=[(math.cos(t)*r,math.sin(t)*r,z) for z in [-7,7] for r in [14,17] for t in [a,b]]
    arches.append(mesh('ArchSegment',verts,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],moss if i in range(3,9) else stone))
    arch_shapes.append(verts)
    for z in [-7.15,7.15]:
        vv=[(math.cos(t)*r,math.sin(t)*r,z+dz) for dz in [-.15,.15] for r in [14,17.25] for t in [a,b]]
        arches.append(mesh('PortalTrim',vv,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],trim))
batch('TunnelShell',arches);save('garden_tunnel')
text=['[gd_scene format=3]','[ext_resource type="PackedScene" path="res://assets/environment/yoshi/garden_tunnel.glb" id="Model"]']
for i,verts in enumerate(arch_shapes):text.append('[sub_resource type="ConvexPolygonShape3D" id="Arch%d"]\npoints = PackedVector3Array(%s)'%(i,','.join('%.6f'%x for p in verts for x in p)))
text += ['[node name="GardenTunnel" type="Node3D"]','[node name="Model" parent="." instance=ExtResource("Model")]','[node name="ArchCollision" type="StaticBody3D" parent="."]']
for i in range(12):text.append('[node name="Section%d" type="CollisionShape3D" parent="ArchCollision"]\nshape = SubResource("Arch%d")'%(i,i))
(SCENES/'garden_tunnel.tscn').write_text('\n\n'.join(text))

# Small paddock buildings: opaque windows/awnings, warm walls, stepped roofs.
start();wall=material('Cafe_Plaster',(.89,.79,.59));roof=material('Roof_Teal',(.08,.33,.38));window=material('Window_Blue',(.18,.40,.49));wood=material('Door_Wood',(.38,.24,.15))
box('Walls',(0,2.5,0),(12,5,8),wall);box('Roof',(0,5.35,0),(13,.7,9),roof)
box('FrontAwning',(0,3.5,4.8),(12,.3,2.4),roof)
for x in [-4,-1.6,2.8]:box('Window',(x,2.3,4.05),(1.8,1.8,.12),window)
box('Door',(0,1.3,4.08),(1.3,2.6,.15),wood)
save('paddock_house');wrapper('paddock_house',((0,2.5,0),(12,5,8)))
start();wall=material('Tower_Cream',(.91,.85,.67));roof=material('Tower_Coral',(.81,.33,.24));window=material('Tower_Glass',(.15,.35,.43))
box('Tower',(0,5.5,0),(5,11,5),wall);box('Cabin',(0,10,0),(7,3,7),window);box('Roof',(0,11.8,0),(8,.6,8),roof);save('race_tower');wrapper('race_tower',((0,5.5,0),(7,11,7)))

# Persistent native scene assembly. Every placement is an editable instance.
header=['[gd_scene format=3]','[ext_resource type="PackedScene" path="res://assets/environment/yoshi/island.glb" id="Island"]','[ext_resource type="Resource" path="res://resources/surfaces/grass.tres" id="Grass"]','[sub_resource type="ConcavePolygonShape3D" id="IslandCollision"]\ndata = PackedVector3Array('+','.join('%.6f'%x for p in collision for x in p)+')']
(SCENES/'island_ground.tscn').write_text('\n\n'.join(header+['[node name="Ground" type="Node3D"]','[node name="Island" parent="." instance=ExtResource("Island")]','[node name="GroundBody" type="StaticBody3D" parent="."]\nmetadata/surface = ExtResource("Grass")','[node name="Shape" type="CollisionShape3D" parent="GroundBody"]\nshape = SubResource("IslandCollision")']))
stand=(ROOT/'scenes/environment/figure8/grandstand.tscn').read_text().replace('CIRCUIT 08','COASTAL GP')
(SCENES/'grandstand.tscn').write_text(stand)
text=['[gd_scene format=3]']
for name in ['garden_tree','flowerbed','garden_tunnel','paddock_house','race_tower','grandstand']:
    text.append('[ext_resource type="PackedScene" path="res://scenes/environment/yoshi/%s.tscn" id="%s"]'%(name,name))
text+=['[ext_resource type="Shader" path="res://assets/environment/yoshi/sea.gdshader" id="SeaShader"]','[sub_resource type="ShaderMaterial" id="Water"]\nshader = ExtResource("SeaShader")','[sub_resource type="PlaneMesh" id="Sea"]\nsize = Vector2(1800,1800)\nmaterial = SubResource("Water")','[node name="EnvironmentArt" type="Node3D"]','[node name="Sea" type="MeshInstance3D" parent="."]\nposition = Vector3(0,-3,0)\nmesh = SubResource("Sea")\ncast_shadow = 0']
for group in ['Trees','Flowers','Tunnels','Paddock','Grandstands']:text.append('[node name="%s" type="Node3D" parent="."]'%group)
for i,item in enumerate(plan['trees']):text.append('[node name="GardenTree%02d" parent="Trees" instance=ExtResource("garden_tree")]\nposition = %s\nscale = %s\nrotation_degrees = Vector3(0,%d,0)'%(i,v(item['position']),v([item['scale']]*3),item['yaw']))
for i,pos in enumerate(plan['flowers']):text.append('[node name="Flowerbed%02d" parent="Flowers" instance=ExtResource("flowerbed")]\nposition = %s'% (i,v(pos)))
for i,t in enumerate(plan['tunnels']):text.append('[node name="Tunnel%d" parent="Tunnels" instance=ExtResource("garden_tunnel")]\ntransform = %s'%(i,tf(t['center'],t['forward'])))
for i,pos in enumerate(plan['buildings']):text.append('[node name="%s%d" parent="Paddock" instance=ExtResource("%s")]\nposition = %s'%('Building',i,'paddock_house' if i<2 else 'race_tower',v(pos)))
for i,pos in enumerate(plan['stands']):text.append('[node name="StartStand%d" parent="Grandstands" instance=ExtResource("grandstand")]\nposition = %s\nrotation_degrees = Vector3(0,%d,0)'%(i,v(pos),0 if i==0 else -90))
(SCENES/'yoshi_environment.tscn').write_text('\n\n'.join(text)+'\n')
(ROOT/'resources/tracks/yoshi_environment_layout.json').write_text(json.dumps(plan,indent=2))
print('YOSHI_ASSETS_AND_SCENES_READY')
