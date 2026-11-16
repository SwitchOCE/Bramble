const { avgRuns, BASE } = require('./model.js');
const C = {
  '+3 A, +20% econ':            { step:3, tierCost:[0,0,8,14,19,24,29], econPct:20 },
  '+2 A, +20% econ':            { step:2, tierCost:[0,0,7,11,15,18,22], econPct:20 },
  '+3 at 0.7x income [7,12,16,20,24]': { step:3, tierCost:[0,0,7,12,16,20,24] },
  '+2 at 0.7x income [6,10,13,15,18]': { step:2, tierCost:[0,0,6,10,13,15,18] },
};
for (const [k,v] of Object.entries(C)) {
  const p={...BASE,...v};
  const rush=avgRuns({...p, plan:[0,0,1,1,1,1,1], boardByTurn:()=>2, maxRolls:0},1500);
  const reach=[]; for(let t=2;t<=6;t++){const r=rush.find(r=>r.tier>=t-0.5); reach.push(r?Math.round(r.t):'-');}
  const a=avgRuns(p,1500); let ci=0,ct=0; const s=[];
  a.forEach(r=>{ci+=r.inc;ct+=r.tierSpend; const t=Math.round(r.t); if([4,6,8,10,12].includes(t)) s.push(`t${t}: tiers ${(100*ct/ci).toFixed(0)}%, lag ${(r.tier-r.avgT).toFixed(1)}, fit ${r.fit.toFixed(1)}, shops ${r.rolls.toFixed(0)}, bank ${r.bank.toFixed(0)}`);});
  console.log(`\n== ${k}: rush tiers 2..6 on turns ${reach.join(' ')}`); s.forEach(x=>console.log('   '+x));
}
