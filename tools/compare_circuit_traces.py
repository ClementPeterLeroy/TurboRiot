"""Private reference annotations/comparisons; public JSON contains numbers only.

Requires Pillow, NumPy and SciPy. Does not change runtime resources.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial import cKDTree
from build_circuit_traces import ROOT

SOURCES = {'figure_8': 'Figure 8/figure_8_overhead_map.png',
           'yoshi_ds': 'Yoshi circuit/yoshi_circuit_overhead_map.png'}

def dense_spline(points):
    result = []
    for i, a in enumerate(points):
        b = a + (points[(i+1)%len(points)]-points[(i-1)%len(points)])/6
        d = points[(i+1)%len(points)]
        c = d - (points[(i+2)%len(points)]-a)/6
        for t in np.linspace(0,1,30,endpoint=False):
            result.append((1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d)
    return np.array(result)

def compare(identifier):
    trace = json.loads((ROOT/f'resources/tracks/{identifier}_trace.json').read_text())
    reference = Image.open(ROOT/'references/tracks'/SOURCES[identifier]).convert('RGB')
    native = Image.open(ROOT/f'artifacts/v061_{identifier}_top.png').convert('RGB')
    assert reference.size == native.size == tuple(trace['image_size'])
    points = np.array(trace['normalized_points'])*trace['image_size']
    spline = dense_spline(points)
    landmarks = np.array(trace['traced_landmarks'])
    original = np.concatenate([np.linspace(a, landmarks[(i+1)%len(landmarks)],50,endpoint=False) for i,a in enumerate(landmarks)])
    forward = cKDTree(original).query(spline)[0]
    backward = cKDTree(spline).query(original)[0]
    pixels = [tuple(p) for p in spline] + [tuple(spline[0])]
    annotated = reference.copy()
    draw = ImageDraw.Draw(annotated)
    draw.line(pixels, fill=(255,50,210), width=2)
    for i, p in enumerate(points[::max(1,len(points)//24)]):
        x,y = p
        draw.ellipse((x-2,y-2,x+2,y+2),fill='yellow')
    x,y = points[0]
    draw.line((x,y,x-30,y), fill=(255,240,0), width=3)
    draw.text((8,8),'Magenta: generated centerline | Yellow: start/direction',fill='white',stroke_width=1,stroke_fill='black')
    overlay = Image.blend(reference,native,.5)
    ImageDraw.Draw(overlay).line(pixels,fill=(255,50,210),width=1)
    comparison = Image.new('RGB',(reference.width*2,reference.height+24),(15,25,35))
    comparison.paste(annotated,(0,24));comparison.paste(native,(reference.width,24))
    ImageDraw.Draw(comparison).text((8,5),'PRIVATE SOURCE + TRACE                         /                         NATIVE GODOT RECONSTRUCTION',fill='white')
    private = ROOT/'references/analysis';private.mkdir(exist_ok=True)
    annotated.save(private/f'{identifier}_annotated.png')
    overlay.save(private/f'{identifier}_overlay.png')
    comparison.save(private/f'{identifier}_comparison.png')
    # Approximate asphalt segmentation. Kerbs/grid/buildings/occlusion introduce
    # mask errors: this is a reproducible footprint diagnostic, not ground truth.
    def asphalt(image):
        a = np.asarray(image).astype(float)
        return (np.ptp(a,axis=2)<=12)&(a.mean(2)>35)&(a.mean(2)<180)
    first,second=asphalt(reference),asphalt(native)
    return dict(image_size=trace['image_size'],source=SOURCES[identifier],
                generated_to_landmarks_mean_pixels=float(forward.mean()),
                symmetric_landmark_fit_max_pixels=float(max(forward.max(),backward.max())),
                approximate_asphalt_mask_iou=float((first&second).sum()/(first|second).sum()),
                disclaimer='Landmarks were manually traced; fit is not independent source accuracy. Mask includes occlusion/decoration errors. Human comparison remains pending.')

if __name__=='__main__':
    report = {key:compare(key) for key in SOURCES}
    (ROOT/'artifacts/v061_trace_comparison.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
