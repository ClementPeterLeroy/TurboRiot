"""Read-only source/locality audit. Blender --background --python this_file.
--record-baseline records the preserved pre-pass source snapshot once, never
from the edited production meshes. Normal runs need only the saved fixture.
"""
from pathlib import Path
import bpy,json,hashlib,sys,math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.godot/city_transition_baseline'
FIXTURE=ROOT/'tests/fixtures/city_transitions.json'
ASSETS='assets/environment/city_square/'
changed=[ASSETS+folder+name+ext for name in ['driving_surfaces','coast_and_terrain','architectural_links'] for folder,ext in [('', '.glb'),('sources/','.blend')]]+[ASSETS+'manifest.json','scenes/environment/city_square/environment.tscn']
def fingerprint(obj):
    data={'vertices':[list(v.co) for v in obj.data.vertices],'faces':[list(f.vertices) for f in obj.data.polygons],
          'materials':[m.name for m in obj.data.materials],'indices':[f.material_index for f in obj.data.polygons],
          'transform':[list(r) for r in obj.matrix_world], 'uv':[[list(v.uv) for v in layer.data] for layer in obj.data.uv_layers]}
    return hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()
def outside(x,z):return not (-147<x<-74 and 79<z<145)
def support_tree(obj):
    obj.data.calc_loop_triangles()
    return BVHTree.FromPolygons([v.co for v in obj.data.vertices],
        [list(t.vertices) for t in obj.data.loop_triangles if t.normal.z>.05],all_triangles=True)
def samples(obj):
    tree=support_tree(obj);result=[]
    for x in range(-164,104,2):
        for z in range(-170,145,2):
            if not outside(x,z):continue
            hit,normal,_,_=tree.ray_cast(Vector((x,-z,40)),Vector((0,0,-1)),70)
            if hit is not None and normal.z>.05:result.append([x,z,hit.z,list(normal)])
    return result
if '--record-baseline' in sys.argv:
    assert not FIXTURE.exists(),'Baseline fixture already recorded'
    hashes=json.loads((BASE/'hashes.json').read_text())
    fixture={'baseline_commit':(BASE/'commit.txt').read_text(),'frozen_files':{p:h for p,h in hashes.items() if p not in changed},
             'current_hashes':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in changed},'objects':{},'outside_support':{},
             'houses':json.loads((BASE/ASSETS/'manifest.json').read_text())['houses'],
             'moved_houses':['AvenueEntryWest_House01','AvenueEntryWest_House02']}
    for name in ['driving_surfaces','coast_and_terrain','architectural_links']:
        bpy.ops.wm.open_mainfile(filepath=str(BASE/ASSETS/'sources'/f'{name}.blend'))
        objects={}
        for obj in bpy.context.scene.objects:
            if obj.type!='MESH':continue
            if obj.name in ['PavedStreets','GardenGrass']:fixture['outside_support'][obj.name]=samples(obj)
            elif obj.name not in ['AvenueEntryWest','AvenueEntryEast']:objects[obj.name]=fingerprint(obj)
        fixture['objects'][name]=objects
    FIXTURE.write_text(json.dumps(fixture,indent=2)+'\n')

fixture=json.loads(FIXTURE.read_text())
if '--refresh-support-only' in sys.argv:
    # Maintenance of the sampling representation, always from immutable old
    # masters. Oppositely wound coincident faces must not win a floor BVH tie.
    for name,obj in [('driving_surfaces','PavedStreets'),('coast_and_terrain','GardenGrass')]:
        bpy.ops.wm.open_mainfile(filepath=str(BASE/ASSETS/'sources'/f'{name}.blend'))
        fixture['outside_support'][obj]=samples(bpy.data.objects[obj])
    FIXTURE.write_text(json.dumps(fixture,indent=2)+'\n')
results=[];details={}
def check(value,label):
    results.append({'passed':bool(value),'check':label})
    if not value:print('FAIL',label,flush=True)
for path,digest in {**fixture['frozen_files'],**fixture['current_hashes']}.items():
    check(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,'File scope/hash: '+path)
for name,objects in fixture['objects'].items():
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/ASSETS/'sources'/f'{name}.blend'))
    for obj,digest in objects.items():check(fingerprint(bpy.data.objects[obj])==digest,'Unchanged source component: '+name+'/'+obj)
    for obj in ['PavedStreets','GardenGrass']:
        if obj not in fixture['outside_support'] or obj not in bpy.data.objects:continue
        tree=support_tree(bpy.data.objects[obj]);bad=[];maximum=0;edge_aliases=0
        for x,z,y,normal in fixture['outside_support'][obj]:
            hit,n,_,_=tree.ray_cast(Vector((x,-z,40)),Vector((0,0,-1)),70)
            error=abs(hit.z-y) if hit is not None else 999
            maximum=max(maximum,error)
            same_normal=n is not None and n.dot(Vector(normal))>=.999
            if not same_normal and error<=.001:
                # Exact source triangle edges may return either neighbour after
                # rebuilding a BVH. Require the original normal within 2 mm;
                # do not accept a changed floor or a missing neighbour.
                for dx,dz in [(-.002,0),(.002,0),(0,-.002),(0,.002)]:
                    p,q,_,_=tree.ray_cast(Vector((x+dx,-z-dz,40)),Vector((0,0,-1)),70)
                    if p is not None and abs(p.z-y)<.01 and q.dot(Vector(normal))>=.999:same_normal=True;break
                if not same_normal:
                    same_normal=any(q.dot(Vector(normal))>=.999 for p,q,_,_ in tree.find_nearest_range(Vector((x,-z,y)),.002))
                if same_normal:edge_aliases+=1
            if error>.001 or not same_normal:bad.append([x,z,error])
        check(not bad,obj+' preserves support height/normals outside the entrance crop')
        details[obj]={'samples':len(fixture['outside_support'][obj]),'maximum_height_error':maximum,'shared_edge_normal_aliases':edge_aliases,'mismatches':bad[:12]}
    if name=='coast_and_terrain':check(all(f.normal.z>=0 for f in bpy.data.objects['GardenGrass'].data.polygons),'Grass has no downward rendered faces')
    if name=='architectural_links':check(set(o.name for o in bpy.context.scene.objects if o.type=='MESH')==set(objects),'Exactly the two local infills are removed; all other groups remain')
report={'checks':len(results),'failures':sum(not r['passed'] for r in results),'details':details,'results':results}
(ROOT/'artifacts/v061_city_transitions_audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('CITY_TRANSITION_AUDIT',report['checks'],report['failures'],details,flush=True)
if report['failures']:raise RuntimeError('Source/locality audit failed')
