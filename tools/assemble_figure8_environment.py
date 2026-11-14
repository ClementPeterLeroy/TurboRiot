"""Explicit one-shot authoring helper; not called by the game or editor.

Writes the new modular environment scenes from the preserved bridge survey.
Manual scene edits are authoritative after initial assembly; do not rerun over
an artist's edits unless intentionally rebuilding these new environment files.
"""
from pathlib import Path
import json
import math
import sys

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/environment/figure8'
SCENES=ROOT/'scenes/environment/figure8'
SCENES.mkdir(parents=True,exist_ok=True)
if (SCENES/'figure8_environment.tscn').exists() and '--replace-generated' not in sys.argv:
    raise SystemExit('Scene already exists. Edit it in Godot, or explicitly pass --replace-generated to discard those edits and rebuild.')
p=json.loads((ROOT/'resources/tracks/figure_8_environment_profile.json').read_text())
origin=[p['origin'][0],0,p['origin'][2]]

def vec(v):return 'Vector3(%s)'%', '.join('%.7f'%x for x in v)
def sub(a,b):return [x-y for x,y in zip(a,b)]
def add(a,b):return [x+y for x,y in zip(a,b)]
def mul(a,t):return [x*t for x in a]
def norm(a):return mul(a,1/math.sqrt(sum(x*x for x in a)))
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def transform(pos,forward):
    f=norm(forward);r=norm([ -f[2],0,f[0] ]);up=norm(cross(r,f))
    back=mul(f,-1)
    # Godot text transforms serialize the matrix by rows, not axis vectors.
    matrix=[axis[row] for row in range(3) for axis in [r,up,back]]
    return 'Transform3D(%s)'%', '.join('%.7f'%x for x in matrix+pos)

(SCENES/'grandstand.tscn').write_text('''[gd_scene format=3]
[ext_resource type="PackedScene" path="res://assets/environment/figure8/grandstand.glb" id="1"]
[sub_resource type="BoxShape3D" id="Mass"]
size = Vector3(60,4.8,12)
[node name="Grandstand" type="Node3D"]
[node name="Model" parent="." instance=ExtResource("1")]
[node name="StructureCollision" type="StaticBody3D" parent="."]
[node name="Mass" type="CollisionShape3D" parent="StructureCollision"]
position = Vector3(0,2.4,0)
shape = SubResource("Mass")
[node name="Banner" type="Label3D" parent="."]
position = Vector3(0,7.08,-6.80)
rotation_degrees = Vector3(0,180,0)
text = "TURBO RIOT  //  CIRCUIT 08"
font_size = 64
pixel_size = 0.028
modulate = Color(0.96,0.94,0.82,1)
outline_size = 0
''')
(SCENES/'race_flag.tscn').write_text('''[gd_scene format=3]
[sub_resource type="StandardMaterial3D" id="Steel"]
albedo_color = Color(0.6,0.69,0.73,1)
roughness = 0.9
[sub_resource type="StandardMaterial3D" id="FlagPaint"]
albedo_color = Color(0.06,0.43,0.53,1)
roughness = 0.9
[sub_resource type="BoxMesh" id="Pole"]
size = Vector3(0.12,4,0.12)
material = SubResource("Steel")
[sub_resource type="BoxMesh" id="Cloth"]
size = Vector3(1.5,0.8,0.04)
material = SubResource("FlagPaint")
[node name="RaceFlag" type="Node3D"]
[node name="Pole" type="MeshInstance3D" parent="."]
position = Vector3(0,2,0)
mesh = SubResource("Pole")
cast_shadow = 0
[node name="Flag" type="MeshInstance3D" parent="."]
position = Vector3(0.7,3.5,0)
mesh = SubResource("Cloth")
cast_shadow = 0
''')

resources=['''[gd_scene format=3]
[ext_resource type="PackedScene" path="res://assets/environment/figure8/bridge_shell.glb" id="Shell"]
[ext_resource type="PackedScene" path="res://assets/environment/figure8/approach_verges.glb" id="Verges"]
[ext_resource type="PackedScene" path="res://scenes/environment/figure8/grandstand.tscn" id="Stand"]
[ext_resource type="PackedScene" path="res://scenes/environment/figure8/race_flag.tscn" id="Flag"]
[ext_resource type="Resource" path="res://resources/surfaces/grass.tres" id="Grass"]
[sub_resource type="StandardMaterial3D" id="PierPaint"]
albedo_color = Color(0.60,0.66,0.68,1)
roughness = 0.95
''']
nodes=['[node name="EnvironmentArt" type="Node3D"]',
       '[node name="Bridge" type="Node3D" parent="."]\nposition = '+vec(origin),
       '[node name="Shell" parent="Bridge" instance=ExtResource("Shell")]',
       '[node name="DeckCollision" type="StaticBody3D" parent="Bridge"]',
       '[node name="Supports" type="Node3D" parent="Bridge"]']
for i,(a,b) in enumerate(zip(p['deck'],p['deck'][1:])):
    f=sub(b['center'],a['center']);pos=sub(mul(add(a['center'],b['center']),0.5),origin);pos[1]-=0.45
    resources.append('[sub_resource type="BoxShape3D" id="Deck%d"]\nsize = %s'%(i,vec([17.4,0.7,math.sqrt(sum(x*x for x in f))+0.02])))
    nodes.append('[node name="Section%02d" type="CollisionShape3D" parent="Bridge/DeckCollision"]\ntransform = %s\nshape = SubResource("Deck%d")'%(i,transform(pos,f),i))
for i,row in enumerate(p['piers']):
    for j,side in enumerate([-1,1]):
        k=i*2+j;c=sub(add(row['center'],mul(norm(row['right']),side*8)),origin)
        top=c[1]-0.8;height=top+0.08;c[1]=(top-0.08)/2
        resources += ['[sub_resource type="BoxMesh" id="PierMesh%d"]\nsize = %s\nmaterial = SubResource("PierPaint")'%(k,vec([2,height,2])),
                      '[sub_resource type="BoxShape3D" id="PierShape%d"]\nsize = %s'%(k,vec([2,height,2]))]
        nodes += ['[node name="Pier%d" type="MeshInstance3D" parent="Bridge/Supports"]\nposition = %s\nmesh = SubResource("PierMesh%d")'%(k,vec(c),k),
                  '[node name="Body" type="StaticBody3D" parent="Bridge/Supports/Pier%d"]'%k,
                  '[node name="Shape" type="CollisionShape3D" parent="Bridge/Supports/Pier%d/Body"]\nshape = SubResource("PierShape%d")'%(k,k)]
nodes += ['[node name="Terrain" type="Node3D" parent="."]\nposition = '+vec(origin),
          '[node name="ApproachVerges" parent="Terrain" instance=ExtResource("Verges")]',
          '[node name="VergeCollision" type="StaticBody3D" parent="Terrain"]\nmetadata/surface = ExtResource("Grass")']
for i,section in enumerate(p['banks']):
    for j,side in enumerate([-1,1]):
        vertices=[]
        for row in section:
            c=sub(row['center'],origin);r=norm(row['right']);inner=add(c,mul(r,side*8.9));inner[1]-=0.12;outer=add(c,mul(r,side*18.9));outer[1]=-0.08;vertices += [inner,outer]
        faces=[]
        for row in range(len(section)-1):
            a=row*2
            for triangle in [(a,a+2,a+1),(a+1,a+2,a+3)]:
                t=[vertices[k] for k in triangle]
                if cross(sub(t[1],t[0]),sub(t[2],t[0]))[1]>0:t.reverse()
                faces.extend(t)
        k=i*2+j
        resources.append('[sub_resource type="ConcavePolygonShape3D" id="Bank%d"]\ndata = PackedVector3Array(%s)'%(k,','.join('%.7f'%x for v in faces for x in v)))
        nodes.append('[node name="Bank%d" type="CollisionShape3D" parent="Terrain/VergeCollision"]\nshape = SubResource("Bank%d")'%(k,k))
nodes += ['[node name="Grandstands" type="Node3D" parent="."]',
          '[node name="FinishStand" parent="Grandstands" instance=ExtResource("Stand")]\nposition = Vector3(18,-0.08,22)',
          '[node name="NorthStand" parent="Grandstands" instance=ExtResource("Stand")]\nposition = Vector3(52,-0.08,-112)\nrotation_degrees = Vector3(0,180,0)',
          '[node name="Props" type="Node3D" parent="."]']
for i,pos in enumerate([[-12,-0.08,14.5],[48,-0.08,14.5],[22,-0.08,-103],[82,-0.08,-103]]):
    nodes.append('[node name="RaceFlag%d" parent="Props" instance=ExtResource("Flag")]\nposition = %s'%(i,vec(pos)))
(SCENES/'figure8_environment.tscn').write_text('\n\n'.join(resources+nodes)+'\n')
print('Assembled editable Figure-8 environment scenes')
