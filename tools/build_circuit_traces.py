"""Offline, reviewed pixel traces -> normalized data and original Curve3D scenes.

No private bitmap enters the game. Run --figure first; Yoshi is a separate step.
Spline handles interpolate meaningful landmarks rather than pixel stair steps.
"""
import argparse
import json
from pathlib import Path
import numpy as np
from scipy.ndimage import gaussian_filter1d
from scipy.optimize import least_squares
from scipy.sparse import lil_matrix

ROOT = Path(__file__).resolve().parents[1]
FIGURE = [
    (506,253),(450,253),(395,253),(340,253),(285,253),
    (248,257),(218,276),(199,307),(197,338),(210,366),
    (236,383),(266,386),(298,375),(327,352),(355,324),
    (390,287),(425,250),(460,213),(495,176),(530,139),
    (560,109),(586,91),(615,81),(645,81),(673,93),
    (696,114),(710,141),(714,169),(707,195),(692,218),
    (669,235),(640,246),(608,252),(570,253),(538,253),
]
# Start on the lower finish straight, travel left. All meaningful outline lobes
# are retained; the source's pixel stair steps and decorative island are not road.
YOSHI = [
    (288,467),(250,467),(221,465),(204,454),(199,439),(199,421),
    (223,400),(244,381),(253,368),(240,350),(221,328),(209,314),
    (191,327),(176,334),(162,332),(151,323),(145,309),(147,296),
    (159,283),(178,269),(187,260),(194,232),(201,204),(205,187),
    (187,185),(151,185),(129,181),(112,170),(102,153),(100,133),
    (104,114),(117,99),(136,91),(158,89),(181,89),(197,88),
    (197,65),(198,50),(211,38),(229,33),(246,37),(262,49),
    (265,67),(265,80),(279,85),(296,81),(309,83),(320,93),
    (328,107),(325,121),(315,136),(318,149),(328,165),(331,181),
    (326,198),(314,207),(296,207),(281,210),(270,220),(269,233),
    (277,244),(295,250),(325,253),(357,262),(383,270),
    (409,262),(433,255),(446,259),(455,269),(456,280),(449,290),
    (429,310),(404,334),(379,357),(353,381),(351,389),
    (362,406),(376,424),(376,445),(370,457),(354,466),(328,467),
]

def emit(identifier, pixels, size, scale, road_width, elevated=False):
    width, height = size
    landmarks = list(pixels)
    if identifier == 'yoshi_ds':
        # Round source polygon corners at road scale before offsetting the rails.
        # A sharp centerline kink folds the inner road edge; this is not an AI fix.
        closed = np.array(pixels + [pixels[0]], dtype=float)
        distances = np.r_[0, np.cumsum(np.linalg.norm(np.diff(closed, axis=0), axis=1))]
        offsets = np.arange(0, distances[-1], 1.)
        dense = np.c_[np.interp(offsets, distances, closed[:,0]), np.interp(offsets, distances, closed[:,1])]
        smooth = gaussian_filter1d(dense, 10, axis=0, mode='wrap')
        lengths = np.r_[0, np.cumsum(np.linalg.norm(np.diff(np.vstack([smooth,smooth[0]]),axis=0),axis=1))]
        uniform = np.linspace(0, lengths[-1], round(lengths[-1]/6), endpoint=False)
        target = np.c_[np.interp(uniform,lengths,np.r_[smooth[:,0],smooth[0,0]]),
                       np.interp(uniform,lengths,np.r_[smooth[:,1],smooth[0,1]])]
        count = len(target)
        def residual(flat):
            p = flat.reshape(-1,2)
            tangent = (np.roll(p,-1,axis=0)-np.roll(p,1,axis=0))/6
            a, b, c, d = p, p+tangent, np.roll(p-tangent,-1,axis=0), np.roll(p,-1,axis=0)
            penalties = []
            for t in [0,.25,.5,.75,1]:
                first = 3*(1-t)**2*(b-a)+6*(1-t)*t*(c-b)+3*t*t*(d-c)
                second = 6*(1-t)*(c-2*b+a)+6*t*(d-2*c+b)
                curvature = np.abs(first[:,0]*second[:,1]-first[:,1]*second[:,0])/np.maximum(.01,np.linalg.norm(first,axis=1)**3)
                penalties.append(np.maximum(0,curvature-1/22)*3000)
            return np.r_[(p-target).ravel(), *penalties]
        sparsity = lil_matrix((count*7,count*2), dtype=int)
        for i in range(count):
            sparsity[i*2:i*2+2,i*2:i*2+2] = 1
            for k in range(5):
                for j in [(i-1)%count,i,(i+1)%count,(i+2)%count]: sparsity[count*(2+k)+i,j*2:j*2+2] = 1
        fitted = least_squares(residual,target.ravel(),jac_sparsity=sparsity.tocsr(),max_nfev=300).x.reshape(-1,2)
        pixels = [tuple(p) for p in fitted]
    points = []
    for x, y in pixels:
        elevation = 0.04
        if elevated and 13 <= len(points) <= 20:
            # Approved conservative overpass, broad flat crest, gentle approaches.
            elevation += [0, 1.5, 4, 6.5, 7, 6.5, 4, 1.5][len(points)-13]
        points.append(((x-width/2)*scale, elevation, (y-height/2)*scale))
    data = dict(id=identifier, image_size=size, metres_per_pixel=scale,
                road_width=road_width, normalized_points=[(x/width,y/height) for x,y in pixels],
                elevations=[p[1] for p in points], handle_tension=1/6,
                traced_landmarks=landmarks, smoothing_pixels=10 if identifier=='yoshi_ds' else 0,
                minimum_design_radius_pixels=22 if identifier=='yoshi_ds' else None)
    folder = ROOT/'resources'/'tracks'
    folder.mkdir(parents=True, exist_ok=True)
    (folder/f'{identifier}_trace.json').write_text(json.dumps(data, indent=2)+'\n')
    packed = []
    for i in range(len(points)+1):
        index = i % len(points)
        before, here, after = points[(index-1)%len(points)], points[index], points[(index+1)%len(points)]
        tangent = [(after[k]-before[k])/6 for k in range(3)]
        # Horizontal crest and slope starts prevent unsupported overshoot below terrain.
        if here[1] == 0.04 or here[1] >= 7: tangent[1] = 0
        packed.extend([-v for v in tangent]+tangent+list(here))
    values = ', '.join(f'{v:.7f}' for v in packed)
    half_x, half_z = width*scale/2+12, height*scale/2+12
    text = f'''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/track/track_builder.gd" id="1"]
[ext_resource type="Script" path="res://scripts/track/greybox_ground.gd" id="2"]

[sub_resource type="Curve3D" id="Route"]
bake_interval = 0.15
_data = {{
"points": PackedVector3Array({values}),
"tilts": PackedFloat32Array({', '.join('0' for _ in range(len(points)+1))})
}}
point_count = {len(points)+1}

[node name="Track" type="Path3D"]
script = ExtResource("1")
curve = SubResource("Route")
road_width = {road_width}
sample_spacing = 1.0
use_curve_elevation = {str(elevated).lower()}
outer_perimeter_enabled = false
playable_half_extents = Vector2({half_x}, {half_z})
checkpoint_count = 24

[node name="Ground" type="Node3D" parent="."]
script = ExtResource("2")
'''
    out = ROOT/'scenes'/'tracks'
    out.mkdir(parents=True, exist_ok=True)
    (out/f'{identifier}.tscn').write_text(text)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--figure', action='store_true')
    parser.add_argument('--yoshi', action='store_true')
    args = parser.parse_args()
    if args.figure: emit('figure_8', FIGURE, (1046,511), .5, 15, True)
    if args.yoshi: emit('yoshi_ds', YOSHI, (512,542), .75, 19.5)
