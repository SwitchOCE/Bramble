const { avgRuns, BASE } = require('./model.js');
const C = {
  '+3 A [8,14,19,24,29] d1':  { step:3, tierCost:[0,0,8,14,19,24,29], discount:1 },
  '+3 B [10,18,23,28,33] d3': { step:3, tierCost:[0,0,10,18,23,28,33], discount:3 },
  '+2 A [7,11,15,18,22] d1':  { step:2, tierCost:[0,0,7,11,15,18,22], discount:1 },
  '+2 B [8,15,19,23,27] d2':  { step:2, tierCost:[0,0,8,15,19,23,27], discount:2 },
  '+2>+3 A [7,11,16,21,26] d1': { step:2, accelFrom:5, accelStep:3, tierCost:[0,0,7,11,16,21,26], discount:1 },
};
for (const [k,v] of Object.entries(C)) {
  const p={...BASE,...v};
  const rush=avgRuns({...p, plan:[0,0,1,1,1,1,1], boardByTurn:()=>2, maxRolls:0},1500);
  const reach=[]; for(let t=2;t<=6;t++){const r=rush.find(r=>r.tier>=t-0.5); reach.push(r?Math.round(r.t):'-');}
  const a=avgRuns(p,1500); let ci=0,ct=0,cr=0; const s=[];
  a.forEach(r=>{ci+=r.inc;ct+=r.tierSpend;cr+=r.rollSpend; const t=Math.round(r.t); if([6,8,10,12,14].includes(t)) s.push(`t${t} tiers ${(100*ct/ci).toFixed(0)}% of gold, lag ${(r.tier-r.avgT).toFixed(1)}, fit ${r.fit.toFixed(1)}, shops ${r.rolls.toFixed(0)}, bank ${r.bank.toFixed(0)}`);});
  console.log(`\n== ${k}: rush reaches tiers 2..6 on turns ${reach.join(' ')}`); s.forEach(x=>console.log('   '+x));
}
