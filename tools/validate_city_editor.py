"""Open the real City scene in the native editor, with a bounded lifetime.
Run separately from performance measurements; this is not a headless substitute.
"""
import argparse,json,os,subprocess
from pathlib import Path

def main():
 parser=argparse.ArgumentParser()
 parser.add_argument('--godot',required=True)
 parser.add_argument('--runs',type=int,default=3)
 parser.add_argument('--report-prefix',default='v061_city_feedback')
 args=parser.parse_args()
 root=Path(__file__).resolve().parents[1]
 env=os.environ.copy()
 env['APPDATA']=str(root/'.godot/sandbox_appdata')
 env['LOCALAPPDATA']=env['APPDATA']
 startup=None
 if os.name=='nt':
  startup=subprocess.STARTUPINFO()
  startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW
  startup.wShowWindow=0
 results=[]
 for i in range(args.runs):
  log=root/'.godot'/f'city_feedback_editor_{i+1}.log'
  try:
   with log.open('w',encoding='utf-8') as stream:
    result=subprocess.run([args.godot,'--editor','--path',str(root),'scenes/tracks/city_square.tscn','--quit-after','180','--disable-crash-handler'],env=env,cwd=root,stdout=stream,stderr=stream,startupinfo=startup,timeout=45)
   errors=[line for line in log.read_text(encoding='utf-8').splitlines() if ('ERROR:' in line or 'WARNING:' in line) and 'root certificate store' not in line]
   results.append({'run':i+1,'exit_code':result.returncode,'unexpected_errors':errors,'passed':result.returncode==0 and not errors})
  except subprocess.TimeoutExpired:
   results.append({'run':i+1,'passed':False,'reason':'45-second editor timeout'})
  print(results[-1],flush=True)
 report={'scene':'scenes/tracks/city_square.tscn','native_editor':True,'runs':results,'passed':all(r['passed'] for r in results)}
 (root/'artifacts'/f'{Path(args.report_prefix).name}_editor.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 return 0 if report['passed'] else 1

if __name__=='__main__':raise SystemExit(main())
