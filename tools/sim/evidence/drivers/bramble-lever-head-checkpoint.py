import json,sys,time,subprocess,os,shutil
from pathlib import Path
ROOT=Path('/home/alex/code/Bramble-ideation-sol');sys.path.insert(0,str(ROOT/'tools/sim'));os.chdir(ROOT)
import sweep_shards as ss
import strength_gate as sg
from check_lines import head_to_head,line_outcome_rates
from lever_sweep import atomic_json,file_sha,digest,utc_now,run_command,combine_csv,validate_players
plan_path=Path('tools/sim/evidence/lever-build-strength-plan.json');plan=json.loads(plan_path.read_text());sg.validate_plan(plan)
manifest=json.loads(Path('tools/sim/evidence/caps-screen-manifest.json').read_text())
assert plan['source_fingerprint']==manifest['plan']['source_fingerprint']
base=Path('build/sim/lever-strength');base.mkdir(parents=True,exist_ok=True)
progress_path=Path('tools/sim/evidence/lever-build-strength-progress.json')
progress=json.loads(progress_path.read_text()) if progress_path.exists() else {'version':1,'plan_sha256':digest(plan),'completed':{},'started_at':utc_now()}
assert progress['plan_sha256']==digest(plan)
# Gate collection follows the completed caps-screen protocol, never a partial screen.
caps=json.loads(Path('tools/sim/evidence/caps-screen-progress.json').read_text());assert caps['state']=='complete'
def checkpoint(message):
 atomic_json(progress_path,progress)
 subprocess.run(['git','add',str(progress_path)],check=True)
 subprocess.run(['git','commit','-m',message],check=True)
for build in plan['builds']:
 for comparison in build['comparisons']:
  name=build['id']+'-'+comparison['id'];chunks=[]
  for offset in range(0,80,20):
   key=name+'-'+str(offset);folder=base/key;prefix=folder/'bench';chunks.append(Path(str(prefix)+'.players.csv'))
   if key in progress['completed']:continue
   ss.verify_checkout(manifest,ROOT);assert file_sha(plan['profiles'])==plan['profiles_sha256']
   folder.mkdir(parents=True,exist_ok=False);config=folder/'config.json';atomic_json(config,build['overrides'])
   args=['suite=head_to_head','games=20',f"first_seed={comparison['first_seed']+offset}",f'out={prefix.resolve()}',f"lines={(ROOT/plan['profiles']).resolve()}",f'config={config.resolve()}',f"candidate={comparison['candidate']}",'incumbent=hard_field','capture=off']
   invocation=ss.godot_command('bench.gd',args,420,ROOT);atomic_json(folder/'invocation.json',invocation)
   started=time.monotonic();print(utc_now(),'START',key,flush=True)
   run_command(invocation,folder/'godot.log',427,ROOT)
   ss.verify_checkout(manifest,ROOT);assert json.loads(config.read_text())==build['overrides']
   validate_players(Path(str(prefix)+'.players.csv'),comparison['first_seed']+offset,20,True,comparison['candidate'],'hard_field')
   progress['completed'][key]={'elapsed_seconds':time.monotonic()-started,'players_sha256':file_sha(chunks[-1]),'log_sha256':file_sha(folder/'godot.log'),'invocation_sha256':file_sha(folder/'invocation.json')}
   print(utc_now(),'DONE',key,progress['completed'][key]['elapsed_seconds'],flush=True)
   checkpoint('Checkpoint frozen lever strength '+key)
  players=base/(name+'.players.csv');combine_csv(chunks,players)
  metadata={'completed':True,'plan_sha256':digest(plan),'source_commit':plan['source_commit'],'source_fingerprint':plan['source_fingerprint'],'profiles_sha256':plan['profiles_sha256'],'config_sha256':digest(build['overrides']),'players_sha256':file_sha(players),'chunks':{k:v for k,v in progress['completed'].items() if k.startswith(name+'-')},'config':build['overrides'],'candidate':comparison['candidate'],'incumbent':'hard_field'}
  atomic_json(base/(name+'.run.json'),metadata)
  report=head_to_head(players,{**comparison,'seed_range':[comparison['first_seed'],comparison['first_seed']+79]});report['outcome_rates']=line_outcome_rates(players)
  atomic_json(base/(name+'.result.json'),report)
  dest=Path('tools/sim/evidence/lever-build-heads');dest.mkdir(exist_ok=True)
  for suffix in ['players.csv','run.json','result.json']:shutil.copy2(base/(name+'.'+suffix),dest/(name+'.'+suffix))
  subprocess.run(['git','add',str(dest)],check=True);checkpoint('Record complete lever comparison '+name)
report=sg.summarize(plan,base);out=Path('tools/sim/evidence/lever-build-strength-gate.json');atomic_json(out,report)
progress['state']='complete';progress['completed_at']=utc_now();progress['passes']=report['passes']
doc=Path('docs/ideation/evidence/lever-sweep.md')
with doc.open('a') as stream:
 stream.write('\n\n## Lever-build strength gate: complete\n\n| Build | Candidate | Mean placement gain | 95% seed-cluster interval | Lobby wins |\n|---|---|---:|---|---|\n')
 for name,b in report['builds'].items():
  for key,r in b['comparisons'].items():stream.write(f"| {name} | {r['candidate']} | {r['mean_place_gain']:+.3f} | [{r['ci95'][0]:+.3f}, {r['ci95'][1]:+.3f}] | {r['wins']['candidate']}/160 |\n")
 stream.write('\nPrimary best-line gate '+('passes' if report['passes'] else 'does not pass')+'. Mixture comparisons remain separate diagnostics; wins and placement describe different aspects of variance. No samples were extended or profiles tuned. [Full gate and provenance](../../../tools/sim/evidence/lever-build-strength-gate.json).\n')
execution=Path('tools/sim/evidence/scale-run-execution.json');record=json.loads(execution.read_text());record.update(state='complete',completed_at=utc_now(),lever_build_gate_passes=report['passes'],gate_sha256=file_sha(out));atomic_json(execution,record)
subprocess.run(['git','add',str(out),str(doc),str(execution)],check=True);checkpoint('Complete both lever-build strength gates with frozen blind comparisons')
print(utc_now(),'ALL COMPLETE',report['passes'],flush=True)
