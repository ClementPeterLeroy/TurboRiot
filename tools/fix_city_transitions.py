"""One-time local City fixes. Existing house/roof masters are never regenerated.
Run in Blender after preserving a source baseline; then import and synchronize
the native scene with apply_city_transitions.gd. Revision guards prevent repeats.
"""
from pathlib import Path
import bpy, bmesh, json, math
from mathutils import Vector, geometry
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/environment/city_square'
SRC=ASSETS/'sources'
manifest=json.loads((ASSETS/'manifest.json').read_text())
assert not manifest.get('transition_revision'), 'Local transitions already corrected'
survey=json.loads((ROOT/'resources/tracks/city_square/survey.json').read_text())
report={'moved':[], 'added':[], 'removed_link_groups':['AvenueEntryWest','AvenueEntryEast'],
        'paving_station_range':[1045,1135], 'paved_apron_width':18.0,
        'allowed_geometry_bounds':{'garden_paving':[-146,-75,80,144], 'garden_houses':[-145,38,70,144], 'fountain_houses':[-151,-92,-70,-45]}}

def save(name):
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(ASSETS/(name+'.glb')),export_format='GLB',export_apply=True,
        export_cameras=False,export_lights=False,export_animations=False,will_save_settings=False)
    print('CITY_TRANSITION_SOURCE',name,flush=True)

def source(name):
    bpy.ops.wm.open_mainfile(filepath=str(SRC/(name+'.blend')))
    assert not bpy.context.scene.get('turbo_transition_revision'), name+' already edited'

def row_at(offset):
    rows=survey['samples']
    for a,b in zip(rows,rows[1:]):
        if a['offset']<=offset<=b['offset']:
            t=(offset-a['offset'])/(b['offset']-a['offset'])
            p=Vector(a['position']).lerp(Vector(b['position']),t)
            r=Vector(a['right']).lerp(Vector(b['right']),t).normalized()
            return p,r,a['width']+(b['width']-a['width'])*t
    raise ValueError(offset)

def bv(p):return Vector((p[0],-p[2],p[1]))
def flat(p):return Vector((p.x,p.y))
def area(poly):return sum(a.x*b.y-b.x*a.y for a,b in zip(poly,poly[1:]+poly[:1]))*.5

def new_mesh(name,vertices,faces,material):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.materials.append(material);data.update()
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    if name=='GardenGrass':
        for face in bm.faces:
            if face.normal.z<0:face.normal_flip()
    bm.to_mesh(data);bm.free()
    uv=data.uv_layers.new(name='RepeatedMetres')
    for face in data.polygons:
        for loop in face.loop_indices:
            p=data.vertices[data.loops[loop].vertex_index].co
            uv.data[loop].uv=(p.x/2,-p.y/2)
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);return obj

def half(poly,a,b,inside=True):
    if not poly:return []
    result=[];edge=b-a
    for p,q in zip(poly,poly[1:]+poly[:1]):
        dp=edge.cross(flat(p)-a);dq=edge.cross(flat(q)-a)
        inp=dp>=-1e-7 if inside else dp<=1e-7
        inq=dq>=-1e-7 if inside else dq<=1e-7
        if inp:result.append(p)
        if inp!=inq:
            t=dp/(dp-dq);result.append(p.lerp(q,t))
    compact=[]
    for p in result:
        if not compact or (p-compact[-1]).length>1e-6:compact.append(p)
    if len(compact)>1 and (compact[0]-compact[-1]).length<1e-6:compact.pop()
    return compact if len(compact)>=3 else []

def subtract(poly,cutter):
    remaining=poly;pieces=[]
    for a,b in zip(cutter,cutter[1:]+cutter[:1]):
        outside=half(remaining,a,b,False)
        if outside:pieces.append(outside)
        remaining=half(remaining,a,b,True)
        if not remaining:break
    return pieces


# Replace only the bounded entrance portion of the existing volume. A planar
# constrained union avoids self-intersecting ribbon booleans at the sharp bend.
# Unaffected original faces/UVs stay in their original BMesh, without a rebuild.
source('driving_surfaces')
road=bpy.data.objects['PavedStreets']
vertices=[];quads=[];rows=[]
for station in range(1045,1136):
    p,r,old=row_at(station)
    blend=max(0,min(1,(station-1045)/22));blend=blend*blend*(3-2*blend)
    width=max(old,10+8*blend)
    rows.append((station,p,r,width))
    vertices.extend([bv(p+r*side*width*.5+Vector((0,dy,0))) for dy in [0,-1.2] for side in [-1,1]])
faces=[]
for i in range(len(rows)-1):
    a=i*4;b=a+4
    faces.extend([(a,a+1,b+1,b),(a+2,b+2,b+3,a+3),(a,b,b+2,a+2),(a+1,a+3,b+3,b+1)])
    poly=[flat(vertices[j]) for j in [a,a+1,b+1,b]]
    hull=[poly[j] for j in geometry.convex_hull_2d(poly)]
    if area(hull)<0:hull.reverse()
    quads.append(hull)
faces.extend([(0,2,3,1),(len(vertices)-4,len(vertices)-3,len(vertices)-1,len(vertices)-2)])
crop=[Vector((-146,-144)),Vector((-75,-144)),Vector((-75,-80)),Vector((-146,-80))]
clipped_quads=[]
for quad in quads:
    poly=[Vector((p.x,p.y,0)) for p in quad]
    for a,b in zip(crop,crop[1:]+crop[:1]):poly=half(poly,a,b)
    if poly:clipped_quads.append([flat(p) for p in poly])
quads=clipped_quads
# Pave the local forecourt up to the replacement facades. Its north end tapers
# back to the preserved 22 m avenue; the south/east edges meet the wider garden
# bend. This removes exposed slab sides and grass slits against house footings.
forecourt=[(-131,80),(-109,80),(-106.1837845,84),(-106.1837845,105.375),
           (-112,108),(-118,113),(-125,125),(-134.8396149,125),(-134.8396149,84)]
forecourt_vertices=[Vector((x,-z,0)) for x,z in forecourt]
for triangle in geometry.tessellate_polygon([forecourt_vertices]):
    poly=[flat(forecourt_vertices[p] if isinstance(p,int) else p) for p in triangle]
    if area(poly)<0:poly.reverse()
    quads.append(poly)
report['forecourt_polygon_xz']=forecourt

def inside(point,poly):
    return all((b-a).cross(point-a)>=-1e-6 for a,b in zip(poly,poly[1:]+poly[:1]))

original_bvh=BVHTree.FromObject(road,bpy.context.evaluated_depsgraph_get())
def height(point):
    # Exact original support at the two join planes; interior height follows
    # the unchanged route with continuous segment interpolation.
    if abs(point.x+75)<.0002 or abs(point.y+80)<.0002:
        hit=original_bvh.ray_cast(Vector((point.x,point.y,30)),Vector((0,0,-1)),40)[0]
        if hit is not None:return hit.z
    # Use the same projected source grade as the ribbon cross-sections. A
    # separate nonlinear height blend can fold skinny constrained triangles
    # even when its sampled heights appear smooth.
    best=(float('inf'),0)
    for (_,a,_,_),(_,b,_,_) in zip(rows,rows[1:]):
        start=Vector((a.x,-a.z));edge=Vector((b.x-a.x,-b.z+a.z))
        t=max(0,min(1,(point-start).dot(edge)/max(1e-10,edge.length_squared)))
        distance=(point-start-edge*t).length_squared
        if distance<best[0]:best=(distance,a.y+(b.y-a.y)*t)
    return best[1]

points=[];edges=[];polygons=[]
for quad in quads:
    first=len(points);points.extend(quad);ids=list(range(first,len(points)))
    edges.extend(zip(ids,ids[1:]+ids[:1]));polygons.append(ids)
for x in range(-145,-75):
    for y in range(-143,-80):
        p=Vector((x,y))
        if any(inside(p,q) for q in quads):points.append(p)
vs,_,fs,*_=geometry.delaunay_2d_cdt(points,edges,polygons,0,.001,False)
top=[]
for face in fs:
    center=sum((vs[i] for i in face),Vector((0,0)))/len(face)
    if inside(center,crop) and any(inside(center,q) for q in quads):
        ids=list(face)
        if area([vs[i] for i in ids])<0:ids.reverse()
        top.append(ids)

bm=bmesh.new();bm.from_mesh(road.data);uv=bm.loops.layers.uv.active
generated=[]
lookup={tuple(round(v,5) for v in vertex.co):vertex for vertex in bm.verts}
def vertex(p):
    key=tuple(round(v,5) for v in p)
    if key not in lookup:lookup[key]=bm.verts.new(p)
    return lookup[key]
def face_from(points):
    verts=[vertex(p) for p in points]
    verts=list(dict.fromkeys(verts))
    if len(verts)<3:return
    try:face=bm.faces.new(verts)
    except ValueError:return
    generated.append(face)

# Boolean-authored source faces can be concave. Triangulate only faces touching
# the local crop before clipping; distant polygons and UV loops remain intact.
touching=[]
for face in bm.faces:
    p=[v.co for v in face.verts]
    if max(v.x for v in p)>=-146 and min(v.x for v in p)<=-75 and max(v.y for v in p)>=-144 and min(v.y for v in p)<=-80:touching.append(face)
bmesh.ops.triangulate(bm,faces=touching)
for face in list(bm.faces):
    poly=[v.co.copy() for v in face.verts]
    if max(p.x for p in poly)<-146 or min(p.x for p in poly)>-75 or max(p.y for p in poly)<-144 or min(p.y for p in poly)>-80:continue
    inside_part=poly
    for a,b in zip(crop,crop[1:]+crop[:1]):inside_part=half(inside_part,a,b)
    if not inside_part:continue
    outside=subtract(poly,crop)
    bm.faces.remove(face)
    for part in outside:face_from(part)

counts={}
for ids in top:
    upper=[Vector((vs[i].x,vs[i].y,height(vs[i]))) for i in ids]
    face_from(upper)
    face_from([p-Vector((0,0,1.2)) for p in reversed(upper)])
    for a,b in zip(ids,ids[1:]+ids[:1]):counts.setdefault(tuple(sorted((a,b))),[]).append((a,b))
for values in counts.values():
    if len(values)!=1:continue
    a,b=values[0];pa=Vector((vs[a].x,vs[a].y,height(vs[a])));pb=Vector((vs[b].x,vs[b].y,height(vs[b])))
    # Join planes connect directly to preserved road, without an internal wall.
    if (abs(pa.x+75)<.0002 and abs(pb.x+75)<.0002) or (abs(pa.y+80)<.0002 and abs(pb.y+80)<.0002):continue
    face_from([pb,pa,pa-Vector((0,0,1.2)),pb-Vector((0,0,1.2))])
for face in generated:
    for loop in face.loops:
        p=loop.vert.co;loop[uv].uv=(p.x/2,-p.y/2)
bm.normal_update()
# Keep the constrained triangles: dissolving this graded union can produce
# concave/nonplanar n-gons whose export triangulation introduces false ridges.
bm.to_mesh(road.data);bm.free();road.data.update()
road_bvh=BVHTree.FromObject(road,bpy.context.evaluated_depsgraph_get())
bpy.context.scene['turbo_transition_revision']=1
save('driving_surfaces')

# Remove grass beneath the new apron exactly, clipping existing triangles.
# Keep every unaffected triangle and all other terrain objects. New boundary
# vertices sample the real final road top, so paving/grass share one edge height.
source('coast_and_terrain')
grass=bpy.data.objects['GardenGrass'];material=grass.data.materials[0]
old=[v.co.copy() for v in grass.data.vertices]
grass.data.calc_loop_triangles()
triangles=[list(t.vertices) for t in grass.data.loop_triangles]
new_vertices=[];new_faces=[];vertex_map={};clipped=0
cutters=[(q, min(p.x for p in q),max(p.x for p in q),min(p.y for p in q),max(p.y for p in q)) for q in quads]
for triangle in triangles:
    poly=[old[i].copy() for i in triangle];parts=[poly]
    xmin=min(p.x for p in poly);xmax=max(p.x for p in poly);ymin=min(p.y for p in poly);ymax=max(p.y for p in poly)
    relevant=[q for q,x0,x1,y0,y1 in cutters if x1>=xmin and x0<=xmax and y1>=ymin and y0<=ymax]
    for q in relevant:parts=[piece for part in parts for piece in subtract(part,q)]
    changed=bool(relevant)
    if changed:clipped+=1
    for part in parts:
        ids=[]
        for p in part:
            if changed:
                # Only a boundary close to the actual paving inherits its
                # height; distant grass retains its original interpolation.
                # A nearest 3D point may select the vertical slab side below
                # its top. Cast down instead, sampling just inside exact edges.
                for dx,dy in [(0,0),(.0002,0),(-.0002,0),(0,.0002),(0,-.0002)]:
                    point=road_bvh.ray_cast(Vector((p.x+dx,p.y+dy,35)),Vector((0,0,-1)),45)[0]
                    if point is not None and abs(point.z-p.z)<.75:p.z=point.z;break
            key=tuple(round(v,5) for v in p)
            if key not in vertex_map:vertex_map[key]=len(new_vertices);new_vertices.append(p)
            ids.append(vertex_map[key])
        if len(set(ids))<3:continue
        # Clipping triangles by convex half-planes leaves convex pieces.
        for i in range(1,len(ids)-1):
            tri=(ids[0],ids[i],ids[i+1])
            a,b,c=(new_vertices[j] for j in tri)
            area2=(b-a).cross(c-a).length
            longest=max((b-a).length,(c-a).length,(c-b).length)
            # Discard clipping dust in the edited area before float/mesh
            # compression can turn it into zero-area collision segments.
            if changed and area2/max(longest,1e-9)<.005:continue
            if area2>1e-8:new_faces.append(tri)
bpy.data.objects.remove(grass,do_unlink=True)
new_mesh('GardenGrass',new_vertices,new_faces,material)
bpy.context.scene['turbo_transition_revision']=1
save('coast_and_terrain')
report['clipped_grass_triangles']=clipped

# The two irregular corner infills are the only deleted source objects.
# Other ten connector meshes, six modular masters and all roofs are untouched.
source('architectural_links')
for name in report['removed_link_groups']:bpy.data.objects.remove(bpy.data.objects[name],do_unlink=True)
bpy.context.scene['turbo_transition_revision']=1
save('architectural_links')

def add(name,model,position,yaw,scale_x=1.0):
    w,d,h=manifest['house_sizes'][model]
    item={'name':name,'model':model,'position':position,'yaw':yaw,'size':[w*scale_x,d,h],
          'scale':[scale_x,1,1], 'palette':len(report['added'])%4,'transition_added':True,'foundation_extension':0}
    manifest['houses'].append(item);report['added'].append(item.copy())

# Fit two reused modules between each existing terrace end and the clipped
# fountain frontage tip. Small width scaling applies only to the four new lots.
for side,front,end in [('West',-133.5,-65.65506744384766),('East',-105.5,-66.01234436035156)]:
    scale=(-48.625-end)/16;cursor=-48.625
    for index,model in enumerate([3,4]):
        w,d,_=manifest['house_sizes'][model];length=w*scale
        x=front-d/2 if side=='West' else front+d/2
        add('FountainEntry_'+side+'_%02d'%index,model,[x,9.7,cursor-length/2],-math.pi/2 if side=='West' else math.pi/2,scale)
        cursor-=length

# Reuse the two detached west-side houses as a coherent garden-facing terrace.
west_front=-134.83961486816406
for name,x,z in [('AvenueEntryWest_House01',west_front-5,129),('AvenueEntryWest_House02',west_front-4.5,138)]:
    house=next(h for h in manifest['houses'] if h['name']==name)
    before=json.loads(json.dumps(house));house['position']=[x,1.2,z];house['yaw']=-math.pi/2
    report['moved'].append({'name':name,'before':before,'after':json.loads(json.dumps(house))})

cursor=97.375;scale=(124-cursor)/26
for index,model in enumerate([4,2,3]):
    w,d,_=manifest['house_sizes'][model];length=w*scale
    add('GardenEntry_West_%02d'%index,model,[west_front-d/2,1.2,cursor+length/2],-math.pi/2,scale)
    cursor+=length

add('GardenEntry_Corner',4,[-101.68378448486328,1.2,101.375],math.pi/2)
# Close the land-facing gap between the existing garden row and coast frontage.
start=9.504806518554688;end=31.0;scale=(end-start)/21
for index,model in enumerate([5,3,1]):
    w,d,_=manifest['house_sizes'][model];length=w*scale
    add('GardenLandEdge_%02d'%index,model,[start+length/2,1.2,86.25-d/2],math.pi,scale)
    start+=length

# Sample the unchanged solid land beneath each new/moved lot; extend only its
# own footing when necessary, never the road or terrain under other houses.
bpy.ops.wm.open_mainfile(filepath=str(SRC/'coast_and_terrain.blend'))
land_bvh=BVHTree.FromObject(bpy.data.objects['TownLand'],bpy.context.evaluated_depsgraph_get())
changed_names={h['name'] for h in report['added']}|{h['name'] for h in report['moved']}
for house in manifest['houses']:
    if house['name'] not in changed_names:continue
    x,y,z=house['position'];w,d,_=house['size'];yaw=house['yaw'];heights=[]
    for a,b in [(0,0),(-1,-1),(-1,1),(1,-1),(1,1)]:
        px=x+math.cos(yaw)*a*w*.49+math.sin(yaw)*b*d*.49
        pz=z-math.sin(yaw)*a*w*.49+math.cos(yaw)*b*d*.49
        hit=land_bvh.ray_cast(Vector((px,-pz,45)),Vector((0,0,-1)),60)[0]
        assert hit is not None,'Lot has no solid land: '+house['name']
        heights.append(hit.z)
    house['foundation_extension']=max(0,y-.9-min(heights)+.1)

manifest['transition_revision']=1
manifest['transition_removed_link_groups']=report['removed_link_groups']
manifest['previous_link_setbacks_x']=manifest['link_setbacks_x']
manifest['link_setbacks_x']={}
manifest['structural_frontages']=[n for n in manifest['structural_frontages'] if n not in report['removed_link_groups']]
report['added']=[h for h in manifest['houses'] if h.get('transition_added')]
for moved in report['moved']:moved['after']=next(h for h in manifest['houses'] if h['name']==moved['name'])
(ASSETS/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(ROOT/'artifacts/v061_city_transitions_changes.json').write_text(json.dumps(report,indent=2)+'\n')
print('CITY_TRANSITIONS_READY',len(manifest['houses']),'shared house instances',flush=True)
