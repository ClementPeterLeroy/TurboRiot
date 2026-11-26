"""Local architecture-only setback; run in Blender after correct_city_roofs.py."""
from pathlib import Path
import bpy,json,sys
root=Path(__file__).resolve().parents[1];assets=root/'assets/environment/city_square'
path=assets/'manifest.json';data=json.loads(path.read_text())
if '--geometry-only' not in sys.argv:assert 'architecture_revision' not in data,'Manifest setback already applied'
bpy.ops.wm.open_mainfile(filepath=str(assets/'sources/architectural_links.blend'))
assert not bpy.context.scene.get('turbo_entry_setback',0),'Setback already applied'
for name,dx in [('AvenueEntryWest',-2),('AvenueEntryEast',2)]:bpy.data.objects[name].location.x+=dx
bpy.context.scene['turbo_entry_setback']=2
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(assets/'sources/architectural_links.blend'))
bpy.ops.export_scene.gltf(filepath=str(assets/'architectural_links.glb'),export_format='GLB',export_apply=True,export_cameras=False,export_lights=False,export_animations=False,will_save_settings=False)
if '--geometry-only' in sys.argv:sys.exit(0)
moves={**{f'Avenue_Left_{i:02}':2 for i in range(3)},**{f'Avenue_Right_{i:02}':-2 for i in range(3)},'AvenueEntryWest_House01':-2,'AvenueEntryWest_House02':-2}
for house in data['houses']:
 if house['name'] in moves:house['position'][0]+=moves[house['name']]
data['architecture_revision']=1;data['entrance_setbacks_x']=moves
data['link_setbacks_x']={'AvenueEntryWest':-2,'AvenueEntryEast':2}
path.write_text(json.dumps(data,indent=2)+'\n')
