const { avg, BASE, income, curve } = require('./model2.js');
const CANDS = { A:[0,0,8,12,16,19,21], B:[0,0,9,14,18,21,23], C:[0,0,10,15,19,22,25] };
const pr = (B,k)=>Math.max(0,B-[0,2,5,9,14][k]);
for (const [n,c] of Object.entries(CANDS)) {
  console.log(`\n== ${n}: base ${c.slice(2).join('/')}`);
  console.log('  price after waiting 1/2/3/4 turns:'); for (let k=2;k<=6;k++) console.log(`    tier ${k}: ${c[k]} -> ${[1,2,3,4].map(w=>pr(c[k],w)).join(' / ')}`);
  const p={...BASE,tierCost:c};
  // policies
  const rush={...p, policy:()=>true, boardByTurn:()=>2, maxRolls:0};
  const fast={...p, policy:()=>true};       // tier whenever affordable, still fill the board after
  for (const [pn,pp] of [['rush (2-unit board)',rush],['tier when affordable',fast],['every 2 turns (2,4,6,8,10)',p],['every 2 turns from 3 (3,5,7,9,11)',{...p,policy:curve([0,0,3,5,7,9,11])}]]) {
    const a=avg(pp,1500); const reach=[]; for(let t=2;t<=6;t++){const r=a.find(r=>r.tier>=t-0.5); reach.push(r?Math.round(r.t):'-');}
    let ci=0,ct=0,cr=0,b2b=0; const s=[]; a.forEach(r=>{ci+=r.inc;ct+=r.tierSpend;cr+=r.rollSpend;b2b+=r.b2b; const t=Math.round(r.t); if([4,6,8,10,12].includes(t)) s.push(`t${t} lag ${(r.tier-r.avgT).toFixed(1)} fit ${r.fit.toFixed(1)} units ${r.units.toFixed(1)} shops ${r.rolls.toFixed(0)} bank ${r.bank.toFixed(0)}`);});
    console.log(`  ${pn.padEnd(32)} tiers 2..6 on ${reach.join(' ')} | tiers ${(100*ct/ci).toFixed(0)}% of gold to t14, rolls ${(100*cr/ci).toFixed(0)}% | back-to-back ups ${b2b.toFixed(2)}/game`);
    if (pn.startsWith('every 2 turns (')|| pn.startsWith('tier when')) s.forEach(x=>console.log('      '+x));
  }
}
