"""Initial native assembly from authored models. Never invoked at runtime.
Existing scene edits require explicit --replace-generated to overwrite.
"""
from pathlib import Path
import json, math, sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'scenes/environment/figure8_stadium'
OUT.mkdir(parents=True,exist_ok=True)
target=OUT/'stadium.tscn'
if target.exists() and '--replace-generated' not in sys.argv:
    raise SystemExit('Assembly exists: review artist edits before --replace-generated.')
m=json.loads((ROOT/'assets/environment/figure8_stadium/stadium_manifest.json').read_text())
survey=json.loads((ROOT/'artifacts/figure8_road_milestone_a.json').read_text())

def vec(v):return 'Vector3(%s)'%', '.join('%.6f'%x for x in v)
def pose(p,yaw=0):return '\nposition = '+vec(p)+'\nrotation = Vector3(0, %.7f, 0)'%yaw
def shape_box(name,pos,size,yaw=0,parent='StructureCollision'):
    resources.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = %s'%(name,vec(size)))
    nodes.append('[node name="%s" type="CollisionShape3D" parent="%s"]%s\nshape = SubResource("%s")'%(name,parent,pose(pos,yaw),name))

# Reusable scene wrappers retain shared imported mesh resources and masses.
for asset,mass,center in [('curved_grandstand',[25,8.8,14],[0,4.25,6.0]),
                           ('garage_bay',[8.3,9.3,13],[0,4.55,0]),
                           ('control_tower',[12,20.8,12],[0,10.3,0]),
                           ('start_gantry',None,None),('sponsor_panel',None,None),('floodlight_mast',None,None)]:
    resources=['[gd_scene format=3]',
        '[ext_resource type="PackedScene" path="res://assets/environment/figure8_stadium/%s.glb" id="Model"]'%asset]
    nodes=['[node name="%s" type="Node3D"]'%asset,
        '[node name="Model" parent="." instance=ExtResource("Model")]']
    if asset=='start_gantry':
        resources.append('[ext_resource type="PackedScene" path="res://scenes/branding/gantry_logo.tscn" id="Brand"]')
        nodes.append('[node name="OfficialBrand" parent="." instance=ExtResource("Brand")]')
    if mass:
        nodes.append('[node name="StructureCollision" type="StaticBody3D" parent="."]')
        shape_box('Mass',center,mass)
    if asset=='start_gantry':
        nodes.append('[node name="StructureCollision" type="StaticBody3D" parent="."]')
        for i,x in enumerate([-10.5,10.5]):shape_box('Upright%d'%i,[x,4,0],[.65,8,1])
        shape_box('Header',[0,7.8,0],[22,1.8,1])
    if asset=='floodlight_mast':
        nodes.append('[node name="StructureCollision" type="StaticBody3D" parent="."]')
        shape_box('Base',[0,1,0],[1.5,2,1.5])
    (OUT/(asset+'.tscn')).write_text('\n\n'.join(resources+nodes)+'\n')

resources=['[gd_scene format=3]',
    '[ext_resource type="Script" path="res://scripts/track/stadium_environment.gd" id="Script"]',
    '[ext_resource type="Resource" path="res://resources/surfaces/grass.tres" id="Grass"]',
    '[ext_resource type="Resource" path="res://resources/surfaces/asphalt.tres" id="Asphalt"]']
for asset in m['assets']:
    path=('scenes/environment/figure8_stadium/'+asset+'.tscn') if (OUT/(asset+'.tscn')).exists() else ('assets/environment/figure8_stadium/'+asset+'.glb')
    resources.append('[ext_resource type="PackedScene" path="res://%s" id="%s"]'%(path,asset))
resources.append('[sub_resource type="StandardMaterial3D" id="RoadPaint"]\nalbedo_color = Color(0.255,0.28,0.31,1)\nroughness = 0.96')
resources.append('[sub_resource type="StandardMaterial3D" id="GroundPaint"]\nalbedo_color = Color(0.09,0.22,0.10,1)\nroughness = 0.99')
nodes=['[node name="EnvironmentArt" type="Node3D"]\nscript = ExtResource("Script")\nroad_material = SubResource("RoadPaint")\nground_material = SubResource("GroundPaint")\nmetadata/stadium_revision = 1']
for group in ['Bridge','Terrain','Grandstands','Pits','Safety','Perimeter','Signage','Lighting']:
    nodes.append('[node name="%s" type="Node3D" parent="."]'%group)
for name,asset,group in [('Infrastructure','bridge_infrastructure','Bridge'),('TrackSafety','track_safety','Safety'),
                           ('StadiumShell','stadium_perimeter','Perimeter'),('SiteFinishes','site_finishes','Terrain')]:
    nodes.append('[node name="%s" parent="%s" instance=ExtResource("%s")]'%(name,group,asset))
nodes.append('[node name="DeckCollision" type="StaticBody3D" parent="Bridge"]\nmetadata/surface = ExtResource("Asphalt")')
nodes.append('[node name="BankCollision" type="StaticBody3D" parent="Terrain"]\nmetadata/surface = ExtResource("Grass")')
nodes.append('[node name="SupportCollision" type="StaticBody3D" parent="Bridge"]')
for i,c in enumerate(m['collisions']):
    shape='SurveyShape%d'%i
    resources.append('[sub_resource type="ConcavePolygonShape3D" id="%s"]\ndata = PackedVector3Array(%s)'%(shape,','.join('%.6f'%x for p in c['triangles'] for x in p)))
    parent='Terrain/BankCollision' if c['surface']=='grass' else 'Bridge/DeckCollision'
    nodes.append('[node name="%s" type="CollisionShape3D" parent="%s"]\nshape = SubResource("%s")'%(c['name'].replace('__','_'),parent,shape))
for i,p in enumerate(m['piers']):shape_box('Pier%d'%i,p['position'],p['size'],parent='Bridge/SupportCollision')
for i,s in enumerate([297,370]):
    rows=survey['samples'];index=round(s/survey['length']*len(rows));c=rows[index]['position'];a=rows[index-1]['position'];b=rows[index+1]['position']
    shape_box('Abutment%d'%i,[c[0],(c[1]-1.3)/2,c[2]],[18.2,c[1]-1.3,1.2],math.atan2(b[0]-a[0],b[2]-a[2]),'Bridge/SupportCollision')
for s in m['stands']:
    nodes.append('[node name="%s" parent="Grandstands" instance=ExtResource("curved_grandstand")]%s'%(s['name'],pose(s['position'],s['yaw'])))
for i,g in enumerate(m['garages']):
    nodes.append('[node name="%s" parent="Pits" instance=ExtResource("garage_bay")]%s'%(g['name'],pose(g['position'])))
    nodes.append('[node name="Number%02d" type="Label3D" parent="Pits/%s"]\nposition = Vector3(0,3.45,-6.02)\nrotation = Vector3(0,3.14159265,0)\ntext = "BAY %02d"\nfont_size = 64\npixel_size = 0.009\noutline_size = 0\nmodulate = Color(0.96,0.75,0.30,1)'%(i,g['name'],i+1))
nodes.append('[node name="RaceControl" parent="Pits" instance=ExtResource("control_tower")]\nposition = Vector3(47,-0.02,25)')
nodes.append('[node name="StartGantry" parent="Signage" instance=ExtResource("start_gantry")]\nposition = Vector3(-8.5,0.04,-1.25)\nrotation = Vector3(0,-1.57079633,0)')
nodes.append('[node name="ServiceSign" type="Label3D" parent="Pits"]\nposition = Vector3(8,9.5,18.1)\nrotation = Vector3(0,3.14159265,0)\ntext = "TURBO RIOT  //  MOTORSPORT CENTRE"\nfont_size = 64\npixel_size = 0.020\noutline_size = 0\nmodulate = Color(0.95,0.75,0.24,1)')
nodes.append('[node name="WallCollision" type="StaticBody3D" parent="Perimeter"]')
for i,c in enumerate(m['perimeter_collision']):shape_box('Bay%03d'%i,c['position'],c['size'],c['yaw'],'Perimeter/WallCollision')
rows=survey['samples']
for i,(offset,side) in enumerate([(20,1),(48,1),(80,1),(130,1),(180,1),(225,1),(270,1),(310,1),(355,-1),(402,-1),(450,-1),(494,-1),(540,-1),(580,-1),(620,1)]):
    j=round(offset/survey['length']*len(rows));p=rows[j]['position'];a=rows[(j-1)%len(rows)]['position'];b=rows[(j+1)%len(rows)]['position']
    f=[b[0]-a[0],b[2]-a[2]];mag=math.hypot(*f);out=[-f[1]/mag*side,f[0]/mag*side]
    pos=[p[0]+out[0]*10.0,p[1],p[2]+out[1]*10.0]
    nodes.append('[node name="Sponsor%02d" parent="Signage" instance=ExtResource("sponsor_panel")]%s'%(i,pose(pos,math.atan2(out[0],out[1]))))
for i,p in enumerate([[-185,0,5],[-159,0,92],[-70,0,70],[6,0,-120],[115,0,-80],[120,0,10]]):
    yaw=math.atan2(p[0]+35,p[2]+15)
    nodes.append('[node name="Mast%02d" parent="Lighting" instance=ExtResource("floodlight_mast")]%s'%(i,pose(p,yaw)))
target.write_text('\n\n'.join(resources+nodes)+'\n')
print('STADIUM_ASSEMBLED',len(m['stands']),'curved stands;',len(m['garages']),'garage bays')
