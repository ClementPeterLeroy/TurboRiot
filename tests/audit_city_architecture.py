"""Read-only Blender audit of source volumes, facade preservation and frozen files.
Run: blender --factory-startup --disable-autoexec --background --python tests/audit_city_architecture.py
"""
from pathlib import Path
import bpy,bmesh,json,hashlib,collections,sys
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
ASSETS=ROOT/'assets/environment/city_square';checks=[];details={}
def check(value,message):
 checks.append({'pass':bool(value),'message':message})
 if not value:print('FAIL',message,flush=True)
def fingerprint(obj):
 payload={'v':[list(v.co) for v in obj.data.vertices],'f':[list(p.vertices) for p in obj.data.polygons],'matrix':[list(r) for r in obj.matrix_world],'uv':[[list(v.uv) for v in layer.data] for layer in obj.data.uv_layers]}
 return hashlib.sha256(json.dumps(payload,sort_keys=True).encode()).hexdigest()
def topology(obj,prefix):
 b=bmesh.new();b.from_mesh(obj.data);faces={f for f in b.faces if obj.data.materials[f.material_index].name.startswith(prefix)};edges={e for f in faces for e in f.edges}
 result={'faces':len(faces),'open_edges':sum(sum(f in faces for f in e.link_faces)==1 for e in edges),'nonmanifold_edges':sum(sum(f in faces for f in e.link_faces)!=2 for e in edges)}
 b.free();return result
source=json.loads((ROOT/'artifacts/v061_city_architecture_sources.json').read_text())
for name,spec in source['modules'].items():
 bpy.ops.wm.open_mainfile(filepath=str(ASSETS/'sources'/f'{name}.blend'))
 roof=bpy.data.objects['TerracottaRoof'];b=bmesh.new();b.from_mesh(roof.data)
 edges=topology(roof,'City_Roof');check(edges['nonmanifold_edges']==0,name+' roof is a closed manifold shell')
 check(any(.1<f.normal.z<.99 for f in b.faces) and any(-.99<f.normal.z<-.1 for f in b.faces),name+' has sloping top and underside')
 thickness=abs(b.calc_volume())/(spec['wall_width']*(spec['wall_depth']+.44));check(.15<thickness<.22,name+' is an 18 cm shell rather than a floating sheet')
 bounds=[min(v.co.x for v in b.verts),max(v.co.x for v in b.verts)];check(abs(bounds[0]+spec['wall_width']/2)<1e-4 and abs(bounds[1]-spec['wall_width']/2)<1e-4,name+' roof stops at shared side walls')
 b.free()
 check(all(fingerprint(bpy.data.objects[n])==digest for n,digest in spec['facade_fingerprints'].items()),name+' preserves every original facade object/UV/transform')
 for part in ['StuccoWalls','StoneFoundation']:
  obj=bpy.data.objects[part];bm=bmesh.new();bm.from_mesh(obj.data);check(all(e.is_manifold for e in bm.edges),name+' '+part+' encloses all four sides and bottom');bm.free()
 gables=[o for o in bpy.context.scene.objects if o.name.startswith('RoofGableWall')]
 check(len(gables)==(2 if spec['kind'].startswith('gable') else 0),name+' uses correct closed gable caps or hipped ends')
 for obj in gables:
  bm=bmesh.new();bm.from_mesh(obj.data);check(all(e.is_manifold for e in bm.edges),name+' '+obj.name+' is a closed wall prism');bm.free()
 details[name]={'roof':edges,'effective_thickness':thickness,'party_wall_x_bounds':bounds}
bpy.ops.wm.open_mainfile(filepath=str(ASSETS/'sources/architectural_links.blend'))
for obj in bpy.context.scene.objects:
 if obj.type!='MESH':continue
 roof=topology(obj,'City_Roof');check(roof['nonmanifold_edges']==0,obj.name+' roof shell has no open or nonmanifold edges')
 core=topology(obj,'City_Plaster');check(core['open_edges']==0,obj.name+' plaster core and gable returns have no open edges')
 stone=topology(obj,'City_Stone');check(stone['open_edges']==0,obj.name+' foundation has a bottom closure')
 details[obj.name]={'roof':roof,'core':core,'foundation':stone}
frozen=json.loads((ROOT/'tests/fixtures/city_architecture_frozen.json').read_text())
for path,digest in frozen.items():check(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,'Feature freeze: '+path)
result={'checks':len(checks),'failures':sum(not c['pass'] for c in checks),'details':details,'results':checks}
(ROOT/'artifacts/v061_city_architecture_audit.json').write_text(json.dumps(result,indent=2)+'\n');print('CITY_ARCHITECTURE_AUDIT',result['checks'],result['failures'],flush=True)
if result['failures']:raise RuntimeError('Architecture audit failed')
