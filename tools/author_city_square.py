"""Trace authoring only. Pixel stations follow the supplied overhead reference.
Godot bakes these handles into authoritative Curve3D resources before modeling.
"""
from pathlib import Path
import json,math,sys
R=Path(__file__).resolve().parents[1]
out=R/'resources/tracks/city_square'
out.mkdir(parents=True,exist_ok=True)
target=out/'layout.json'
if target.exists() and '--replace-generated' not in sys.argv:raise SystemExit('Review author edits before --replace-generated')
xy=[(360,365),(360,300),(360,240),(360,205),(338,190),(330,168),(333,142),(348,127),(373,128),(389,141),(400,155),(435,155),(465,155),(465,112),(475,104),(510,104),(540,113),(558,133),(560,163),(560,182),(600,182),(630,182),(630,220),(630,250),(630,270),(630,294),(625,320),(615,343),(615,375),(615,400),(650,400),(695,400),(735,400),(742,414),(740,443),(729,463),(709,475),(680,477),(647,476),(617,465),(590,465),(565,465),(535,465),(485,465),(465,465),(455,447),(430,445),(413,452),(390,452),(360,452),(360,420),(360,365)]
def pos(p,y):return [(p[0]-520)*.75,y,(p[1]-300)*.75]
def elevation(i,p):
 if i<=3 or i>=49:return 2+8.5*max(0,min(1,(452-p[1])/247))
 if i<=10:return 10.5
 if i<19:return 10.5-2.3*(i-10)/9
 if i<=24:return 8.2 # Replaced by actual station-based stair profiles.
 if i<27:return 2.8-.8*(i-24)/3
 return 2
points=[pos(p,elevation(i,p)) for i,p in enumerate(xy)]
data={'reference':'references/tracks/City Square/1 - Circuit layout/City_Square_overhead_map.png','metres_per_pixel':.75,'origin_px':[520,300],'points':points,'pixel_points':xy,'fountain_center':pos((360,155),10.5),'branch_entry_index':19,'branch_exit_index':24,'inner_pixels':[(560,182),(560,220),(560,250),(560,270),(600,270),(630,270)],'fountain_entry_index':3,'fountain_exit_index':10,'fountain_alternate_pixels':[(360,205),(382,190),(395,173),(400,155)],'checkpoints':[0,2,3,11,18,25,28,31,34,38,41,44,48,50],'wood_start_index':27,'wood_end_index':42}
target.write_text(json.dumps(data,indent=2))
print('CITY_TRACE',len(points),'main control points')
