import json,sys,time,subprocess,os,hashlib
from pathlib import Path
ROOT=Path('/home/alex/code/Bramble-ideation-sol');os.chdir(ROOT);sys.path.insert(0,str(ROOT/'tools/sim'))
from lever_sweep import atomic_json,file_sha,utc_now
import sweep_shards as ss
progress_path=Path('tools/sim/evidence/caps-screen-progress.json');base=ROOT/'build/sim/caps-screen-fixed';inputs=base/'field-inputs'
print(utc_now(),'Waiting for all nine frozen lobby shards and global field inputs',flush=True)
while True:
 progress=json.loads(progress_path.read_text())
 if sum('lobbies-' in k for k in progress['completed'])==9 and (inputs/'inputs.json').exists():break
 time.sleep(10)
fresh=Path('/tmp/bramble-harness-fresh-shard');manifest_path=fresh/'tools/sim/evidence/caps-screen-manifest.json';manifest=json.loads(manifest_path.read_text());dest=base/'results/caps-both--field-r06'
if 'caps-both/field-r06' not in progress['completed']:
 assert not (fresh/'.godot').exists(),'fresh-cache proof must start without an import cache'
 print(utc_now(),'Running first field shard on detached fresh checkout',flush=True)
 command=[sys.executable,str(fresh/'tools/sim/sweep_shards.py'),'--root',str(fresh),'run',str(manifest_path),'caps-both/field-r06','--inputs',str(inputs),'--out',str(dest)]
 with Path('/tmp/bramble-fresh-field.log').open('w') as stream:subprocess.run(command,stdout=stream,stderr=subprocess.STDOUT,check=True,timeout=1000)
 result=json.loads((dest/'result.json').read_text());progress=json.loads(progress_path.read_text())
 progress['completed']['caps-both/field-r06']={'result':str((dest/'result.json').relative_to(ROOT)),'result_sha256':result['result_sha256'],'elapsed_seconds':result['elapsed_seconds'],'fresh_checkout':str(fresh),'fresh_cache_before_run':False}
 atomic_json(progress_path,progress)
 subprocess.run(['git','add',str(progress_path)],check=True);subprocess.run(['git','commit','-m','Verify a complete caps field shard on a fresh checkout'],check=True)
 print(utc_now(),'Fresh field shard complete',result['elapsed_seconds'],flush=True)
print(utc_now(),'Resuming remaining frozen field shards and merge',flush=True)
with Path('/tmp/bramble-caps-fixed-continuation.log').open('w') as stream:subprocess.run([sys.executable,'/tmp/bramble-caps-checkpoint.py'],stdout=stream,stderr=subprocess.STDOUT,check=True)
print(utc_now(),'Caps screening complete; starting predeclared lever-build gates',flush=True)
with Path('/tmp/bramble-lever-head-pipeline.log').open('w') as stream:subprocess.run([sys.executable,'/tmp/bramble-lever-head-checkpoint.py'],stdout=stream,stderr=subprocess.STDOUT,check=True)
print(utc_now(),'Caps screening and lever-build gates COMPLETE',flush=True)
