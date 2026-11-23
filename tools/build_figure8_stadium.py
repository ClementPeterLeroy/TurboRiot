"""Offline stadium asset authoring; Blender --background --python this_file.

Only writes new figure8_stadium assets. Saved .blend models remain editable.
Curve samples are a spatial survey, never a replacement for the driving road.
Rebuilding after artist edits requires an explicit --replace-generated argument.
"""
from pathlib import Path
import bpy, bmesh, math, json, sys
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/environment/figure8_stadium'
SRC = OUT / 'sources'
SRC.mkdir(parents=True, exist_ok=True)
(SRC / '.gdignore').write_text('')
if any(SRC.glob('*.blend')) and '--replace-generated' not in sys.argv:
    raise SystemExit('Artist sources exist: review them before --replace-generated.')
SURVEY = json.loads((ROOT / 'artifacts/figure8_road_milestone_a.json').read_text())
ROWS = SURVEY['samples']
LENGTH = SURVEY['length']
COLLISIONS = []
MANIFEST = {'road_survey': 'artifacts/figure8_road_milestone_a.json', 'assets': [],
            'stands': [], 'garages': [], 'piers': [], 'collisions': COLLISIONS}

def sample(s):
    index = (s % LENGTH) / LENGTH * len(ROWS)
    a = int(index) % len(ROWS)
    return Vector(ROWS[a]['position']).lerp(Vector(ROWS[(a+1) % len(ROWS)]['position']), index % 1)

def frame(s):
    c = sample(s)
    f = (sample(s+.2)-sample(s-.2)).normalized()
    r = f.cross(Vector((0,1,0))).normalized()
    return c, r, f

def bv(p): return (p[0], -p[2], p[1])
def gv(p): return [p[0], p[2], -p[1]]

def start():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.context.scene.unit_settings.system = 'METRIC'
    bpy.context.scene.unit_settings.scale_length = 1
    global PAINT
    palette = {'concrete':(.77,.76,.68), 'dark':(.075,.14,.20),
               'blue':(.12,.34,.48), 'orange':(.91,.38,.12),
               'gold':(.94,.67,.19), 'ivory':(.93,.92,.81),
               'glass':(.16,.48,.57), 'steel':(.48,.58,.61),
               'grass':(.25,.48,.29), 'turf':(.31,.56,.33),
               'earth':(.47,.44,.31), 'red':(.77,.18,.13)}
    PAINT = {}
    for name, color in palette.items():
        m = bpy.data.materials.new('TR_'+name)
        linear = tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in color)
        m.diffuse_color = (*linear,1)
        m.use_nodes = True
        m.use_backface_culling = True
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value = (*linear,1)
        bsdf.inputs['Roughness'].default_value = .7 if name=='glass' else .87
        if name in ['steel','glass']: bsdf.inputs['Metallic'].default_value = .25
        PAINT[name] = m

def mesh(name, vertices, faces, paint, collision=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata([bv(v) for v in vertices], [], faces)
    data.update()
    bm = bmesh.new(); bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(data); bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(PAINT[paint])
    if collision:
        triangles=[]
        for face in data.polygons:
            v=[gv(data.vertices[i].co) for i in face.vertices]
            for i in range(1,len(v)-1): triangles.extend([v[0],v[i+1],v[i]])
        COLLISIONS.append({'name':name,'triangles':triangles,'surface':'grass' if paint in ['grass','turf'] else 'asphalt'})
    return obj

def box(name, c, size, paint, forward=None):
    c=Vector(c); f=Vector((0,0,1)) if forward is None else Vector(forward).normalized()
    r=Vector((f.z,0,-f.x)).normalized() if math.hypot(f.x,f.z)>.00001 else Vector((1,0,0))
    u=f.cross(r).normalized()
    v=[c+r*x*size[0]/2+u*y*size[1]/2+f*z*size[2]/2 for z in [-1,1] for y in [-1,1] for x in [-1,1]]
    return mesh(name,v,[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)],paint)

def prism(name, outline, bottom, top, paint):
    n=len(outline)
    v=[(x,y,z) for y in [bottom,top] for x,z in outline]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,v,faces,paint)

def beam(name, a, b, width, depth, paint):
    a,b=Vector(a),Vector(b)
    return box(name,(a+b)/2,(width,depth,(b-a).length),paint,b-a)

def text(name, content, pos, size, paint='ivory', yaw=0):
    data=bpy.data.curves.new(name,'FONT'); data.body=content
    data.align_x='CENTER'; data.align_y='CENTER'; data.size=size
    data.resolution_u=2
    obj=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(obj)
    obj.location=bv(pos)
    # Default text lies in Blender XY, front +Z. Turn to Godot front -Z.
    obj.rotation_euler=(math.pi/2,0,math.pi-yaw)
    data.materials.append(PAINT[paint])
    return obj

def batch_roles():
    # Architectural roles remain separate editable meshes, with shared paints.
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type=='MESH':groups.setdefault(obj.name.split('.')[0].split('__')[0],[]).append(obj)
    for name, objects in groups.items():
        if len(objects)<2:continue
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join(); objects[0].name=name

def save(name):
    batch_roles()
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
    for obj in list(bpy.context.scene.objects):
        if obj.type=='FONT':
            bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True)
            bpy.context.view_layer.objects.active=obj; bpy.ops.object.convert(target='MESH')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',
        export_apply=True,export_cameras=False,export_lights=False,export_animations=False,will_save_settings=False)
    MANIFEST['assets'].append(name)
    print('STADIUM_ASSET',name,flush=True)

def sweep(name, offsets, section, paint, collision=False):
    vertices=[]
    for s in offsets:
        c,r,f=frame(s)
        for lateral,dy in section:vertices.append(c+r*lateral+Vector((0,dy,0)))
    n=len(section); faces=[]
    for i in range(len(offsets)-1):
        for j in range(n):faces.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    faces += [tuple(range(n-1,-1,-1)),tuple((len(offsets)-1)*n+j for j in range(n))]
    return mesh(name,vertices,faces,paint,collision)

# 1. Continuous deck, box-girder ribs, abutments and supported approach banks.
start()
offsets=list(range(150,522,2))
sweep('StructuralDeck',offsets,[(-9.05,-.20),(9.05,-.20),(9.05,-1.25),(-9.05,-1.25)],'concrete',True)
for side in [-1,1]:
    sweep('EdgeGirders__'+str(side),offsets,[(side*8.7,-.30),(side*9.15,-.30),(side*9.15,-1.50),(side*8.7,-1.50)],'blue')
for s in [299,367]:
    c,r,f=frame(s)
    top=c.y-1.32
    beam('PierCaps__'+str(s),c+r*9.1+Vector((0,-1.45,0)),c-r*9.1+Vector((0,-1.45,0)),1.6,1.1,'concrete')
    for side in [-1,1]:
        p=c+r*side*6.8
        # Chamfered solid piers and flared footings, not thin floating poles.
        outline=[(p.x+dx,p.z+dz) for dx,dz in [(-1.2,-1.8),(.8,-1.8),(1.2,-1.4),(1.2,1.4),(.8,1.8),(-1.2,1.8)]]
        prism('Piers__'+str(s)+str(side),outline,-.08,top,'concrete')
        box('Footings__'+str(s)+str(side),(p.x,.20,p.z),(3.6,.56,4.8),'blue')
        MANIFEST['piers'].append({'position':[p.x,(top-.08)/2,p.z],'size':[2.4,top+.08,3.6]})
for a,b in [(146,298),(369,529)]:
    section=list(range(a,b+1,2))
    verts=[]
    for s in section:
        c,r,f=frame(s); extent=11.3+max(0,c.y)*1.5
        for lateral,dy in [(-extent,-.08-c.y),(-8.9,-.23),(8.9,-.23),(extent,-.08-c.y)]:
            verts.append(c+r*lateral+Vector((0,dy,0)))
    faces=[]
    for i in range(len(section)-1):
        for j in range(3):faces.append((4*i+j,4*i+j+1,4*i+5+j,4*i+4+j))
    mesh('Embankment__'+str(a),verts,faces,'grass',True)
    # Curved retaining toe, continuous at the abutment rather than pillars.
    for side in [-1,1]:
        for i,s in enumerate(section[:-1]):
            c,r,f=frame(s); d,rr,ff=frame(section[i+1])
            w=11.3+max(0,c.y)*1.5; ww=11.3+max(0,d.y)*1.5
            p=c+r*side*w; q=d+rr*side*ww; p.y=q.y=.18
            beam('RetainingToes__'+str(a)+str(side),p,q,.48,.52,'concrete')
# Abutment front walls reach the deck at either end of the open span.
for s in [297,370]:
    c,r,f=frame(s)
    box('Abutments__'+str(s),(c.x,(c.y-1.3)/2,c.z),(18.2,c.y-1.3,1.2),'concrete',f)
save('bridge_infrastructure')

# 2. Reusable curved, stepped and closed-back spectator architecture.
start()
R=48.0
def arc(x,z,y):
    angle=x/R
    return (math.sin(angle)*(R+z),y,math.cos(angle)*(R+z)-R)
def sector(name,x0,x1,z0,z1,y0,y1,paint):
    steps=max(2,math.ceil((x1-x0)/1.5)); v=[]
    for i in range(steps+1):
        x=x0+(x1-x0)*i/steps
        v += [arc(x,z,y) for y in [y0,y1] for z in [z0,z1]]
    faces=[(0,1,3,2),(4*steps,4*steps+2,4*steps+3,4*steps+1)]
    for i in range(steps):
        a=i*4;b=a+4
        faces.extend([(a,b,b+1,a+1),(a+2,a+3,b+3,b+2),(a,a+2,b+2,b),(a+1,b+1,b+3,a+3)])
    return mesh(name,v,faces,paint)
sector('Foundations',-11.5,11.5,-.7,13.5,-.12,.60,'concrete')
for row in range(9):
    z=.3+row*1.35; y=.65+(row+1)*.63
    sector('SteppedTerraces__'+str(row),-11.4,11.4,z,z+1.35,.40,y,'concrete')
    # Two 1.6 m aisles break each tier. Seat blocks use a coordinated palette.
    for block,(left,right) in enumerate([(-10.5,-1.0),(1.0,10.5)]):
        paint=['blue','gold','orange','blue'][row//3+block if row//3+block<4 else 0]
        for seat in range(12):
            x=left+(right-left)*(seat+.5)/12
            box('SeatPans__'+paint,arc(x,z+.60,y+.13),(.56,.17,.55),paint)
            box('SeatBacks__'+paint,arc(x,z+1.0,y+.40),(.56,.65,.13),paint)
            if row in [1,2,4,6,8] and seat%3!=2:
                # Batched, low-poly head/shoulder silhouettes; no NPC nodes.
                shirt=['ivory','orange','dark','gold'][(seat+block+row)%4]
                box('Crowd__'+shirt,arc(x,z+.65,y+.65),(.39,.63,.26),shirt)
                p=arc(x,z+.65,y+1.08)
                outline=[(p[0]+math.cos(a*math.tau/6)*.17,p[2]+math.sin(a*math.tau/6)*.16) for a in range(6)]
                prism('CrowdHeads',outline,p[1]-.16,p[1]+.16,'concrete')
    # Central aisle uses real intermediate half-rise steps.
    for half in [0,1]:
        sector('AisleStairs__'+str(row)+str(half),-.85,.85,z+half*.675,z+(half+1)*.675,.50,y-.315+half*.315,'concrete')
sector('RearWall',-11.5,11.5,12.5,13.0,.40,8.6,'blue')
sector('RearParapet',-11.6,11.6,12.4,13.15,8.5,9.0,'gold')
for x in [-11,0,11]:
    for z in [4.5,12.8]:
        a=arc(x,z,0);b=arc(x,z,10.4)
        beam('Columns__'+str(x)+str(z),a,b,.32,.32,'dark')
    beam('CanopyRibs__'+str(x),arc(x,3.5,10.0),arc(x,13.8,10.9),.30,.34,'dark')
sector('CanopyPanels',-12.1,12.1,4.5,14.2,10.40,10.68,'blue')
sector('CanopyLeadingFascia',-12.1,12.1,4.4,4.7,9.85,10.70,'ivory')
sector('FrontAdBand',-11.5,11.5,-.55,-.40,.75,1.55,'blue')
text('StandBrand','TURBO RIOT   //   LIVE AT THE EIGHT',(0,1.14,-.64),.60)
text('CanopyBrand','RIVET RACING',(0,10.18,4.10),1.0,'blue')
save('curved_grandstand')
for region,offsets,side in [('West',range(140,231,18),1),('East',range(449,562,18),-1)]:
    for i,s in enumerate(offsets):
        c,r,f=frame(s); outward=r*side; p=c+outward*17.3; p.y=-.02
        MANIFEST['stands'].append({'name':region+'%02d'%i,'position':list(p),'yaw':math.atan2(outward.x,outward.z)})
for i,x in enumerate([22,48]):
    MANIFEST['stands'].append({'name':'Finish%02d'%i,'position':[x,-.02,-22],'yaw':math.pi})

# 3. Garage module, integrated control tower and start gantry.
start()
box('Foundation',(0,.22,0),(8.35,.60,12.6),'concrete')
box('RearServiceWall',(0,4.4,5.85),(8.2,8.8,.40),'concrete')
for side in [-1,1]:
    box('Columns__'+str(side),(side*3.8,4.5,-5.7),(.60,9.0,.70),'concrete')
    box('SideWalls__'+str(side),(side*4.0,4.3,0),(.25,8.5,12),'concrete')
box('GarageLintel',(0,4.25,-5.65),(8.2,.70,.8),'blue')
box('DoorRecess',(0,2.0,-5.65),(6.8,3.8,.15),'dark')
for panel in range(7):
    box('DoorPanels__'+str(panel),(0,.45+panel*.48,-5.79),(6.45,.43,.12),'steel')
box('DoorStripe',(0,1.1,-5.88),(6.45,.17,.06),'gold')
box('ServiceDoor',(2.6,1.25,5.60),(1.1,2.5,.16),'blue')
box('UpperFloor',(0,4.7,0),(8.35,.40,12.4),'concrete')
box('ObservationGlazing',(0,6.55,-5.78),(6.9,2.7,.16),'glass')
for x in [-2.25,0,2.25]:box('Mullions__'+str(x),(x,6.6,-5.95),(.09,2.85,.12),'ivory')
box('Roof',(0,8.55,0),(8.65,.32,13.4),'blue')
for z in [-6.4,6.4]:box('Parapet__'+str(z),(0,9.0,z),(8.65,.6,.16),'ivory')
box('Balcony',(0,4.70,-6.45),(8.2,.25,1.8),'concrete')
box('BalconyRail',(0,5.55,-7.3),(8.2,.12,.12),'dark')
for x in [-3.6,0,3.6]:box('Balusters__'+str(x),(x,5.15,-7.3),(.10,.85,.10),'dark')
box('ToolCabinet',(-2.8,.6,-6.6),(1.1,1.2,.6),'orange')
for y in [.3,.6,.9]:box('DrawerHandles__'+str(y),(-2.8,y,-6.93),(.7,.05,.05),'steel')
text('GarageSign','TR MOTORSPORT',(0,4.22,-6.10),.57)
save('garage_bay')
for i in range(8):MANIFEST['garages'].append({'name':'Garage%02d'%(i+1),'position':[-25+i*8.35,-.02,25]})
start()
outline=[(-5,-5),(3.8,-5),(5,-3.8),(5,4),(-4,4),(-5,3)]
prism('TowerCore',outline,-.08,18,'concrete')
for x in [-4.6,4.6]:box('VerticalFins__'+str(x),(x,10,-5.25),(.55,20,.65),'blue')
box('VerticalWindowBand',(0,10,-5.10),(2.5,13,.10),'glass')
for y in [5,8,11,14,17]:box('WindowTransoms__'+str(y),(0,y,-5.25),(2.6,.12,.12),'ivory')
prism('ControlCabin',[(-6,-6),(5,-6),(6,-5),(6,5),(-5,5),(-6,4)],17,20,'blue')
for side in [-1,1]:box('PanoramaGlass__'+str(side),(0,18.5,side*5.94),(10.4,1.7,.13),'glass')
box('CrownRoof',(0,20.4,0),(13,.5,13),'gold')
box('RoofMast',(0,22,0),(.22,3.2,.22),'dark')
text('ControlSign','TURBO RIOT',(0,16,-5.35),1.0,'blue')
text('ControlSubtitle','RACE CONTROL  /  08',(0,14.9,-5.35),.51,'blue')
save('control_tower')
start()
for side in [-1,1]:
    x=side*10.5
    prism('GantryBases__'+str(side),[(x-1,-1.2),(x+1,-1.2),(x+.8,1.2),(x-.8,1.2)],-.08,1.5,'concrete')
    box('GantryUprights__'+str(side),(x,4.0,0),(.60,8,.65),'blue')
    beam('GantryBraces__'+str(side),(x,5.3,0),(side*7.8,7.5,0),.25,.25,'steel')
box('GantrySign',(0,7.8,0),(22,1.8,1.0),'blue')
box('GantryCrown',(0,8.85,0),(22.5,.25,1.2),'gold')
# The official two-sided logo is a native texture scene; do not bake wordmarks.
for i in range(5):
    box('StartingLights__'+str(i),(-2.4+i*1.2,6.65,-.2),(.7,.70,.4),'dark')
    box('LampLens__'+str(i),(-2.4+i*1.2,6.65,-.44),(.44,.44,.06),'red')
text('TimingDisplay','LAP  /  03',(7.0,6.7,-.55),.58,'gold')
save('start_gantry')

# 4. Curve-fitted guardrails and opaque-geometry catch mesh, no alpha layers.
start()
for side in [-1,1]:
    offsets=[LENGTH*i/math.ceil(LENGTH/1.2) for i in range(math.ceil(LENGTH/1.2)+1)]
    center=side*8.45
    sweep('SafetyPlinth__'+str(side),offsets,[(center-.44,-.05),(center+.44,-.05),(center+.36,.98),(center-.36,.98)],'concrete')
    for y in [.47,.78,1.05]:
        sweep('CorrugatedRail__'+str(side)+str(y),offsets,[(center-.40,y-.09),(center+.42,y-.09),(center+.42,y+.09),(center-.40,y+.09)],'steel')
    # Visual grid merges into spatially named chunks; no per-wire nodes.
    for i,s in enumerate(range(0,int(LENGTH),4)):
        chunk=i//14
        c,r,f=frame(s);p=c+r*side*9.12
        box('FencePosts%02d__'%chunk+str(side)+str(i),p+Vector((0,2.05,0)),(.10,2.8,.10),'blue')
    count=math.ceil(LENGTH/2)
    for i in range(count):
        a=LENGTH*i/count;b=LENGTH*(i+1)/count; ca,ra,fa=frame(a);cb,rb,fb=frame(b)
        chunk=i//28
        for y in [1.25,1.9,2.55,3.2]:
            p=ca+ra*side*9.12+Vector((0,y,0));q=cb+rb*side*9.12+Vector((0,y,0))
            beam('FenceGrid%02d__'%chunk+str(side)+str(i)+str(y),p,q,.027,.027,'dark')
        for t in [0,.5]:
            p=ca.lerp(cb,t)+ra.lerp(rb,t)*side*9.12
            beam('FenceGrid%02d__'%chunk+str(side)+str(i)+str(t),p+Vector((0,1.25,0)),p+Vector((0,3.2,0)),.024,.024,'dark')
save('track_safety')

# Stadium shell follows the inflated convex footprint, with planned height bays.
start()
points=sorted(set((p['position'][0],p['position'][2]) for p in ROWS[::12]))
def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
lower=[];upper=[]
for p in points:
    while len(lower)>1 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
    lower.append(p)
for p in reversed(points):
    while len(upper)>1 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
    upper.append(p)
hull=lower[:-1]+upper[:-1]
perimeter=[]
for i,p in enumerate(hull):
    a=Vector((p[0]-hull[i-1][0],0,p[1]-hull[i-1][1])).normalized()
    q=hull[(i+1)%len(hull)];b=Vector((q[0]-p[0],0,q[1]-p[1])).normalized()
    na=Vector((a.z,0,-a.x));nb=Vector((b.z,0,-b.x));n=(na+nb).normalized()
    perimeter.append(Vector((p[0],0,p[1]))+n*49/max(.7,n.dot(nb)))
bay_index=0
for i,a in enumerate(perimeter):
    b=perimeter[(i+1)%len(perimeter)];steps=math.ceil((b-a).length/10)
    for j in range(steps):
        p=a.lerp(b,j/steps);q=a.lerp(b,(j+1)/steps);f=q-p;length=f.length
        center=(p+q)/2; height=8.5+([0,1.5,3.0,1.5][(bay_index//4)%4])
        outward=Vector((f.z,0,-f.x)).normalized()
        wall_paint='blue' if (bay_index//4)%3==0 else 'concrete'
        box('PerimeterFoundation__'+str(i)+str(j),center+Vector((0,1.0,0)),(.85,2.16,length+.08),'concrete',f)
        box('StadiumWall__'+str(i)+str(j),center+Vector((0,height/2+1,0)),(.45,height-2,length+.08),wall_paint,f)
        inset=center-outward*.32+Vector((0,4.0,0))
        box('ServiceFacade__'+str(i)+str(j),inset,(.16,3.2,max(.2,length-1.4)),'dark' if bay_index%8<2 else 'blue',f)
        for y in [2.45,5.55]:
            box('ServiceLintels__'+str(i)+str(j)+str(y),center-outward*.43+Vector((0,y,0)),(.18,.15,max(.2,length-1.1)),'ivory',f)
        if bay_index%10==0 and length>5:
            ptext=center-outward*.45+Vector((0,6.8,0))
            text('PerimeterBrand__'+str(bay_index),['08 / ARENA','RIVET RACING','APEX ENERGY'][(bay_index//10)%3],ptext,.70,'ivory',math.atan2(outward.x,outward.z))
        for y in [height-.8,height]:box('PerimeterFascia__'+str(i)+str(j)+str(y),center+Vector((0,y,0)),(.65,.25,length+.1),'gold',f)
        box('Buttresses__'+str(i)+str(j),p+Vector((0,height/2,0)),(1.1,height,1.2),'concrete',f)
        MANIFEST.setdefault('perimeter_collision',[]).append({'position':list(center+Vector((0,height/2,0))),'size':[1.0,height,length+.12],'yaw':math.atan2(f.x,f.z)})
        bay_index+=1
MANIFEST['perimeter']=[list(p) for p in perimeter]
save('stadium_perimeter')

# 5. Site finishes, original ad module and reusable stadium lighting mast.
start()
box('AdBacking',(0,1.1,0),(7.5,1.5,.16),'blue')
box('AdCrown',(0,1.90,0),(7.7,.12,.22),'gold')
text('Sponsor','APEX / ENERGY',(0,1.1,-.10),.74)
save('sponsor_panel')
start()
box('MastFoundation',(0,.3,0),(2.6,.76,2.6),'concrete')
for x in [-.50,.50]:
    beam('MastLegs__'+str(x),(x,0,0),(x*.30,24,0),.22,.22,'steel')
for y in range(2,24,3):
    beam('MastTruss__'+str(y),(-.4,y,0),(.4,y+2.5,0),.08,.08,'steel')
box('FloodlightFrame',(0,24,0),(7,2,.4),'dark')
for x in [-2.5,0,2.5]:
    for y in [23.5,24.5]:box('FloodlightLenses__'+str(x)+str(y),(x,y,-.25),(1.6,.65,.16),'ivory')
save('floodlight_mast')
start()
box('PitApron',(6,.0,23),(86,.10,28),'steel')
for x in range(-32,52,4):box('ApronGrid__'+str(x),(x,.06,15.5),(.08,.02,10),'ivory')
for x in range(-25,45,9):
    box('ServiceStrip__'+str(x),(x,.065,10.3),(4,.025,.20),'gold')
for c,radius in [((-112,0,33),15),((49,0,-47),17),((-9,0,-24),7)]:
    outline=[(c[0]+math.cos(a*math.tau/48)*radius,c[2]+math.sin(a*math.tau/48)*radius*.65) for a in range(48)]
    prism('InfieldTurf__'+str(c),outline,-.075,-.045,'turf')
    for a in range(0,360,30):
        theta=math.radians(a); x=c[0]+math.cos(theta)*radius*.80;z=c[2]+math.sin(theta)*radius*.52
        box('GardenEdges__'+str(c)+str(a),(x,.12,z),(1.0,.36,1.0),'grass')
save('site_finishes')
(OUT/'stadium_manifest.json').write_text(json.dumps(MANIFEST,separators=(',',':')))
print('STADIUM_COMPLETE',len(MANIFEST['stands']),'stands',len(MANIFEST['garages']),'garages',flush=True)
