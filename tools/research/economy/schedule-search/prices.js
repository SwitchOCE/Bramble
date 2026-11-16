// For each price set: best unit gold for each turn tier 6 is reached, plus three steady lines.
// Usage: node prices.js '{"A":[8,14,22,30,38]}' [--one-per-turn] [--flat=3]
//   --one-per-turn  at most one tier-up a turn;  --flat=N  discount of N every turn waited instead of 1,2,3,4,5
const ONE = process.argv.includes('--one-per-turn');
const flatArg = process.argv.find(a => a.startsWith('--flat='));
const disc = flatArg ? [Number(flatArg.split('=')[1])] : [1,2,3,4,5];
const cum=w=>{let s=0;for(let i=0;i<w;i++)s+=disc[Math.min(i,disc.length-1)];return s;};
const inc=[];{let g=5;for(let t=1;t<=20;t++){if(t>1)g+=g>=15?1:2;inc[t]=g;}}
function evalS(base,s){
  const T=s[4],cbt=Array(T+1).fill(0),costs=[];
  for(let k=0;k<5;k++){const w=k===0?s[0]-1:s[k]-s[k-1];const p=Math.max(0,base[k]-cum(w));costs.push(p);cbt[s[k]]+=p;}
  let bank=0;const spare=[];
  for(let t=1;t<=T;t++){bank+=inc[t];let R=0,c=0,g=0;for(let u=t;u<=T;u++){c+=cbt[u];if(u>t)g+=inc[u];R=Math.max(R,c-g);}
    if(bank<R)return null;spare.push(bank-R);bank-=spare.at(-1)+cbt[t];}
  return {s,T,costs,tier:costs.reduce((a,b)=>a+b,0),unit:spare.reduce((a,b)=>a+b,0)};
}
function best(base,maxT=14){
  const out={};
  const rec=(k,prev,s)=>{if(k===5){const r=evalS(base,s);if(r&&(!out[r.T]||r.unit>out[r.T].unit))out[r.T]=r;return;}
    for(let t=(ONE&&s.length)?prev+1:Math.max(prev,1);t<=maxT;t++)rec(k+1,t,[...s,t]);};
  rec(0,1,[]);return out;
}
const sets=JSON.parse(process.argv.slice(2).find(a=>!a.startsWith('--')));
for(const [name,base] of Object.entries(sets)){
  const b=best(base);const Ts=Object.keys(b).map(Number).sort((a,b)=>a-b);
  console.log(`\n== ${name}: ${base.join('/')}`);
  for(const T of Ts.slice(0,6)){const r=b[T];console.log(`  T${T}: turns ${r.s.join(',')} prices ${r.costs.join('/')} tier ${r.tier} unit ${r.unit} (income ${r.tier+r.unit})`);}
  for(const s of [[2,4,6,8,10],[3,5,7,9,11],[2,4,7,10,13]]){const r=evalS(base,s);console.log(`  steady ${s.join(',')}: `+(r?`prices ${r.costs.join('/')} tier ${r.tier} unit ${r.unit}`:'not affordable'));}
}
