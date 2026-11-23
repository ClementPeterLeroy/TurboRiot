"""Explicit Milestone A authoring. Keeps all horizontal interpolation points.
The resulting saved Curve3D is authoritative; this never runs inside the game.
"""
from pathlib import Path
import argparse, re, math, json
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'scenes/tracks/figure_8.tscn'
archive=ROOT/'scenes/tracks/archive/figure_8_before_reconstruction.tscn'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--replace-generated', action='store_true',
                    help='Explicitly replace the active road, discarding subsequent scene edits.')
args = parser.parse_args()
if archive.exists() and not args.replace_generated:
    parser.error('Archive already exists. Review active scene edits before using --replace-generated.')
archive.parent.mkdir(parents=True,exist_ok=True)
if not archive.exists():archive.write_bytes(source.read_bytes())
t=archive.read_text(encoding='utf-8')
numbers=[float(x) for x in re.search(r'"points": PackedVector3Array\((.*?)\)',t,re.S).group(1).split(',')]
pts=[[numbers[i+6],numbers[i+8]] for i in range(0,len(numbers),9)][:-1]
n=len(pts)
# Periodic cubic interpolation: neighboring segment derivatives and second
# derivatives match. Gaussian elimination avoids an external authoring dependency.
matrix=[]
for i in range(n):
    row=[0.0]*(n+2);row[i]=4;row[(i-1)%n]+=1;row[(i+1)%n]+=1
    row[n:]=[3*(pts[(i+1)%n][j]-pts[(i-1)%n][j]) for j in range(2)]
    matrix.append(row)
for k in range(n):
    pivot=max(range(k,n),key=lambda r:abs(matrix[r][k]));matrix[k],matrix[pivot]=matrix[pivot],matrix[k]
    scale=matrix[k][k];matrix[k]=[v/scale for v in matrix[k]]
    for r in range(n):
        if r==k:continue
        scale=matrix[r][k];matrix[r]=[a-scale*b for a,b in zip(matrix[r],matrix[k])]
handles=[[matrix[i][n+j]/3 for j in range(2)] for i in range(n)]
def position(i,u):
    a=pts[i];b=[a[j]+handles[i][j] for j in range(2)];d=pts[(i+1)%n];c=[d[j]-handles[(i+1)%n][j] for j in range(2)]
    return [a[j]*(1-u)**3+3*b[j]*u*(1-u)**2+3*c[j]*u*u*(1-u)+d[j]*u**3 for j in range(2)]
offsets=[];samples=[];distance=0;last=pts[0]
for i in range(n):
    offsets.append(distance)
    for k in range(1,101):
        p=position(i,k/100);distance+=math.dist(last,p);last=p
        samples.append((distance,p,i))
peak=min((s for s in samples if 13<=s[2]<=18),key=lambda s:math.dist(s[1],[-50.4,-1.25]))[0]
begin,end=peak-195,peak+205
def elevation(s):
    if s<=begin or s>=end:return .04,0
    length=peak-begin if s<peak else end-peak
    q=(s-begin)/length if s<peak else (end-s)/length
    return .04+8*(6*q**5-15*q**4+10*q**3),8*30*q*q*(q-1)**2/length*(1 if s<peak else -1)
out=[]
for i in range(n+1):
    j=i%n;x,z=pts[j];hx,hz=handles[j];height,grade=elevation(offsets[j]);hy=grade*math.hypot(hx,hz)
    out += [-hx,-hy,-hz,hx,hy,hz,x,height,z]
t=re.sub(r'"points": PackedVector3Array\(.*?\)',lambda _: '"points": PackedVector3Array('+', '.join('%.8f'%v for v in out)+')',t,flags=re.S)
# Remove the previous environment instance and instance overrides from this
# study scene. Its exact source, layout edits and assets remain in the archive.
t=re.sub(r'^\[ext_resource type="PackedScene"[^\n]*id="3_environment"\]\n','',t,flags=re.M)
t=t.split('[node name="EnvironmentArt"')[0].rstrip()+'\n'
t=t.replace('sample_spacing = 1.0','sample_spacing = 0.5\nroad_study_mode = true')
t=re.sub(r'\[gd_scene[^\n]*\]','[gd_scene format=3]',t,count=1)
source.write_text(t,encoding='utf-8')
(ROOT/'resources/tracks/figure_8_road_reconstruction.json').write_text(json.dumps({'stage':'Milestone A only','method':'periodic C2 cubic XZ; sampled quintic elevation Hermite handles','rise_m':8,'ascent_m':195,'descent_m':205,'peak_planar_offset':peak,'horizontal_control_positions_preserved':True,'archive':str(archive.relative_to(ROOT))},indent=2))
print('Road authored: length XZ',distance,'peak',peak,'ascent',195,'descent',205)
