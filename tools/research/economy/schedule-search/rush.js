// Every tier-up schedule under the 12 Nov calculator defaults (prices 8/12/16/19/21, discount 1,2,3,4,5).
// Turn T = turn tier 6 is reached. Unit gold = all gold not needed for tier-ups, spent as early as possible.
// Usage: node rush.js [--one-per-turn]
const ONE = process.argv.includes('--one-per-turn');
const base=[8,12,16,19,21], disc=[1,2,3,4,5];
const cum=w=>{let s=0;for(let i=0;i<w;i++)s+=disc[Math.min(i,4)];return s;};
const price=(k,w)=>Math.max(0,base[k]-cum(w)); // k=0 -> tier 2
const inc=[];{let g=5;for(let t=1;t<=20;t++){if(t>1)g+=g>=15?1:2;inc[t]=g;}}
const res=[];
function rec(k,prev,sched){ // k tier-ups done
  if(k===5){evaluate(sched);return;}
  for(let t=(ONE&&sched.length)?prev+1:Math.max(prev,1);t<=14;t++){ rec(k+1,t,[...sched,t]); }
}
function evaluate(s){
  const T=s[4]; const costByTurn=Array(T+1).fill(0); const costs=[];
  for(let k=0;k<5;k++){const w=k===0?s[0]-1:s[k]-s[k-1];const p=price(k,w);costs.push(p);costByTurn[s[k]]+=p;}
  // feasibility with carry-over, and spare gold per turn spent as early as possible
  let need=0; const spare=Array(T+1).fill(0);
  // latest-first: cumulative constraint. spare on turn t = max we can spend at t keeping future OK.
  let bank=0, ok=true; const incT=t=>inc[t];
  // compute required reserve before each turn's spending: R[t] = max over u>=t of (sum cost t..u - sum inc t+1..u)
  for(let t=1;t<=T;t++){
    bank+=incT(t);
    let R=0, c=0, g=0;
    for(let u=t;u<=T;u++){c+=costByTurn[u]; if(u>t)g+=incT(u); R=Math.max(R,c-g);}
    if(bank<R){ok=false;break;}
    spare[t]=bank-R; bank-=spare[t]; bank-=costByTurn[t];
  }
  if(!ok)return;
  const total=spare.reduce((a,b)=>a+b,0);
  res.push({s,T,costs,total,spare:spare.slice(1),tierG:costs.reduce((a,b)=>a+b,0)});
}
rec(0,1,[]);
const byT={};for(const r of res){(byT[r.T]=byT[r.T]||[]).push(r);}
for(const T of Object.keys(byT).map(Number).sort((a,b)=>a-b).slice(0,6)){
  const L=byT[T].sort((a,b)=>b.total-a.total||b.spare.slice(0,4).reduce((x,y)=>x+y,0)-a.spare.slice(0,4).reduce((x,y)=>x+y,0));
  const incSum=inc.slice(1,T+1).reduce((a,b)=>a+b,0);
  console.log(`\nTier 6 on turn ${T}: ${L.length} schedules, income to then ${incSum}`);
  for(const r of L.slice(0,4)) console.log(`  ups on turns ${r.s.join(',')}  prices ${r.costs.join('/')} = ${r.tierG}  unit gold ${r.total}  by turn [${r.spare.join(' ')}]`);
}
