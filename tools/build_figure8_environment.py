"""Run with Blender --background --python tools/build_figure8_environment.py.

Builds only new Circuit 8 environment assets, never existing artist source files.
The road survey is an explicit authoring input, not runtime generated scenery.
Editable .blend sources and GLB exports are both retained.
"""
from pathlib import Path
import json
import sys
import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/environment/figure8"
SOURCES = OUT / "sources"
OUT.mkdir(parents=True, exist_ok=True)
SOURCES.mkdir(exist_ok=True)
(SOURCES / ".gdignore").write_text("")
PROFILE = json.loads((ROOT / "resources/tracks/figure_8_environment_profile.json").read_text())
ORIGIN = Vector((PROFILE["origin"][0], 0, PROFILE["origin"][2]))
args = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
if "--replace-generated" not in args and any((SOURCES/(n+".blend")).exists() for n in ["bridge_shell","approach_verges","grandstand"]):
    raise SystemExit("Sources already exist. Edit them in Blender, or explicitly pass -- --replace-generated to discard those edits and rebuild.")


def start():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1


def material(name, color):
    m = bpy.data.materials.new(name)
    linear = tuple(c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4 for c in color)
    m.diffuse_color = (*linear, 1)
    m.use_backface_culling = True
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*linear, 1)
    bsdf.inputs["Roughness"].default_value = 0.85
    m.surface_render_method = "DITHERED"
    return m


def bv(point):
    """Godot (X,Y,Z) -> Blender (X,-Z,Y), preserving handedness."""
    return (point[0], -point[2], point[1])


def mesh(name, vertices, faces, paint):
    data = bpy.data.meshes.new(name)
    data.from_pydata([bv(p) for p in vertices], [], faces)
    data.update()
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(paint)
    return obj


def box(name, center, size, paint, forward=None):
    c = Vector(center)
    f = Vector((0, 0, 1)) if forward is None else Vector(forward).normalized()
    right = Vector((f.z, 0, -f.x)).normalized()
    up = f.cross(right).normalized()
    verts = [c+right*x*size[0]/2+up*y*size[1]/2+f*z*size[2]/2
             for z in [-1,1] for y in [-1,1] for x in [-1,1]]
    return mesh(name, verts, [(0,1,3,2),(4,6,7,5),(0,4,5,1),
                             (2,3,7,6),(0,2,6,4),(1,5,7,3)], paint)


def batch(name, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    objects[0].name = name


def save(name):
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCES / (name + ".blend")))
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + ".glb")),
                             export_format="GLB", export_apply=True,
                             export_cameras=False, export_lights=False,
                             export_animations=False, will_save_settings=False)
    print("FIGURE8_ASSET", name)


# Bridge shell follows the unmodified source road, below its driving surface.
start()
gold = material("Bridge_Ochre", (0.80, 0.58, 0.10))
panel = material("Bridge_GoldPanels", (0.93, 0.72, 0.24))
concrete = material("Bridge_Concrete", (0.43, 0.48, 0.51))
rows = PROFILE["deck"]
deck_verts, deck_faces = [], []
for row in rows:
    c, r = Vector(row["center"])-ORIGIN, Vector(row["right"]).normalized()
    deck_verts += [c+r*side*8.7+Vector((0,dy,0)) for dy in [-0.10,-0.80] for side in [-1,1]]
for i in range(len(rows)-1):
    a, b = 4*i, 4*(i+1)
    deck_faces += [(a,a+1,b+1,b),(a+2,b+2,b+3,a+3),
                   (a,b,b+2,a+2),(a+1,a+3,b+3,b+1)]
deck_faces += [(0,2,3,1),(len(deck_verts)-4,len(deck_verts)-3,len(deck_verts)-1,len(deck_verts)-2)]
mesh("DeckShell", deck_verts, deck_faces, concrete)
gold_parts, panels = [], []
for i, (a,b) in enumerate(zip(rows, rows[1:])):
    ca, cb = Vector(a["center"])-ORIGIN, Vector(b["center"])-ORIGIN
    right = Vector(a["right"]).normalized()
    for side in [-1,1]:
        pos=(ca+cb)/2 + right*side*9.05
        gold_parts.append(box("Parapet", pos+Vector((0,0.4,0)), (0.60,1.6,(cb-ca).length+0.02), gold, cb-ca))
        # Original faceted masonry rhythm; no copied textures or branding.
        for tier in [0,1]:
            panels.append(box("Panel",pos+right*side*0.34+Vector((0,-0.35+tier*0.72,0)),
                              (0.10,0.65,max(0.1,(cb-ca).length-0.10)),panel,cb-ca))
batch("GoldParapets",gold_parts)
batch("GoldPanels",panels)
save("bridge_shell")

# Four restrained verge wedges support the raised approaches, clear of the
# lower-road corridor. Surface collision is serialized in the Godot wrapper.
start()
grass=material("Approach_Grass",(0.318,0.604,0.384))
for index, section in enumerate(PROFILE["banks"]):
    for side in [-1,1]:
        verts,faces=[],[]
        for row in section:
            c,r=Vector(row["center"])-ORIGIN,Vector(row["right"]).normalized()
            inner=c+r*side*8.9;inner.y-=0.12
            outer=c+r*side*18.9;outer.y=-0.08
            verts += [inner,outer]
        for i in range(len(section)-1):
            a=2*i;faces.append((a,a+1,a+3,a+2))
        obj=mesh("Approach_%d_%s"%(index,"Left" if side<0 else "Right"),verts,faces,grass)
        # Open surfaces need an explicit front direction.
        bm=bmesh.new();bm.from_mesh(obj.data)
        for face in bm.faces:
            if face.normal.z<0:face.normal_flip()
        bm.to_mesh(obj.data);bm.free()
save("approach_verges")

# One reusable original grandstand; two native scene instances retain editing.
start()
frame=material("Stand_Concrete",(0.67,0.73,0.76))
steel=material("Stand_Steel",(0.08,0.16,0.22))
teal=material("Stand_Canopy",(0.06,0.36,0.44))
blue=material("Stand_BlueSeats",(0.11,0.28,0.55))
amber=material("Stand_AmberSeats",(0.93,0.58,0.12))
structure=[box("Base",(0,0.25,0),(60,0.5,12),frame)]
seats=[]
for i in range(6):
    height=(i+1)*0.7
    z=-4.4+i*1.6
    structure.append(box("Terrace",(0,0.5+height/2,z),(60,height,1.6),frame))
    seats.append(box("SeatRow",(0,0.5+height+0.08,z),(58,0.16,1.15),blue if i%2==0 else amber))
batch("SteppedStructure",structure)
batch("SeatingBands",seats)
columns=[]
for x in [-28,-9.3,9.3,28]:
    for z in [-5.7,5.7]:columns.append(box("Column",(x,3.8,z),(0.30,7.6,0.30),steel))
batch("CanopyFrame",columns)
box("Canopy",(0,7.7,0),(62,0.3,13.5),teal)
box("FrontFascia",(0,7.1,-6.65),(62,0.95,0.18),teal)
save("grandstand")
