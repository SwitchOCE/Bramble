import json,sys,time,subprocess,os,re
from pathlib import Path
ROOT=Path('/home/alex/code/Bramble-ideation-sol');sys.path.insert(0,str(ROOT/'tools/sim'))
import sweep_shards as ss
from lever_sweep import atomic_json,file_sha,utc_now
os.chdir(ROOT)
manifest=json.loads(Path('tools/sim/evidence/caps-screen-manifest.json').read_text())
base=Path('build/sim/caps-screen-fixed');results=base/'results';results.mkdir(parents=True,exist_ok=True)
import tempfile
tempfile.tempdir=str((base/'tmp').resolve());Path(tempfile.tempdir).mkdir(parents=True,exist_ok=True)
progress_path=Path('tools/sim/evidence/caps-screen-progress.json')
progress=json.loads(progress_path.read_text()) if progress_path.exists() else {'version':1,'manifest_sha256':manifest['manifest_sha256'],'completed':{},'started_at':utc_now()}
assert progress['manifest_sha256']==manifest['manifest_sha256']
def checkpoint(message):
 atomic_json(progress_path,progress)
 subprocess.run(['git','add',str(progress_path)],check=True)
 subprocess.run(['git','commit','-m',message],check=True)
for spec in manifest['shards']:
 if spec['kind']!='lobbies':continue
 if spec['id'] in progress['completed']:continue
 dest=results/spec['id'].replace('/','--')
 print(utc_now(),'START',spec['id'],flush=True)
 result=ss.run_shard(manifest,spec['id'],dest,root=ROOT)
 progress['completed'][spec['id']]={'result':str(dest/'result.json'),'result_sha256':result['result_sha256'],'elapsed_seconds':result['elapsed_seconds']}
 print(utc_now(),'DONE',spec['id'],result['elapsed_seconds'],flush=True)
 checkpoint('Checkpoint fixed caps screening '+spec['id'])
inputs=base/'field-inputs'
if not inputs.exists():ss.merge_lobbies(manifest,[results],inputs)
for spec in manifest['shards']:
 if spec['kind']!='field' or spec['id'] in progress['completed']:continue
 dest=results/spec['id'].replace('/','--')
 print(utc_now(),'START',spec['id'],flush=True)
 result=ss.run_shard(manifest,spec['id'],dest,inputs=inputs,root=ROOT)
 progress['completed'][spec['id']]={'result':str(dest/'result.json'),'result_sha256':result['result_sha256'],'elapsed_seconds':result['elapsed_seconds']}
 print(utc_now(),'DONE',spec['id'],result['elapsed_seconds'],flush=True)
 checkpoint('Checkpoint caps field screening '+spec['id'])
merged=base/'merged'
if not merged.exists():ss.merge(manifest,[results],inputs,merged,root=ROOT)
summary={c['id']:json.loads((merged/'stages'/c['id']/'analysis'/'metrics.json').read_text()) for c in manifest['plan']['configs']}
atomic_json(Path('tools/sim/evidence/caps-screen-results.json'),summary)
doc=Path('docs/ideation/evidence/lever-sweep.md')
report=(merged/'report.md').read_text()
report=re.sub(r'\]\(([^)]+)\)',lambda m:']('+os.path.relpath((merged/m[1]).resolve(),doc.parent.resolve())+')' if not m[1].startswith(('http','#','/')) else m[0],report)
with doc.open('a') as stream:stream.write('\n\n## Completed caps-off screening\n\n'+report+'\n')
progress['state']='complete';progress['completed_at']=utc_now()
subprocess.run(['git','add',str(doc),'tools/sim/evidence/caps-screen-results.json'],check=True)
checkpoint('Complete 450-lobby caps screening and full weighted field metrics')
