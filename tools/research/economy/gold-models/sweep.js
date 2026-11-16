'use strict';
const { avgRuns, BASE, ODDS, income } = require('./model.js');
const mult = (m) => [0,0,5,7,8,11,11].map(c => Math.round(c*m));
const INC = {
  'BG 3..10': { start:3, step:1, cap:10 },
  '+2':       { step:2 },
  '+3':       { step:3 },
  '+2 then +3 from t6': { step:2, accelFrom:5, accelStep:3 },
};
// 1. cumulative income
console.log('Cumulative income by turn');
const T=[1,2,3,4,5,6,7,8,9,10,12,14];
console.log('           '+T.map(t=>String(t).padStart(5)).join(''));
for (const [k,v] of Object.entries(INC)) { const p={...BASE,...v}; let c=0,row=[]; for(let t=1;t<=14;t++){c+=income(p,t); if(T.includes(t)) row.push(c);} console.log(k.padEnd(11).slice(0,11)+row.map(x=>String(x).padStart(5)).join('')); }
for (const [k,v] of Object.entries(INC)) { const p={...BASE,...v}; console.log((k+' per turn').padEnd(24).slice(0,24)+T.map(t=>String(income(p,t)).padStart(4)).join('')); }

// 2. where the gold goes (cumulative to turn 6, 8, 10, 12) on the standard curve
function where(name, over, n=1500) {
  const p={...BASE,...over}; const a=avgRuns(p,n); let cum={inc:0,roll:0,tier:0,fric:0};
  const out=[];
  a.forEach(r=>{cum.inc+=r.inc;cum.roll+=r.rollSpend;cum.tier+=r.tierSpend;
    if([6,8,10,12].includes(Math.round(r.t))){ const intoBoard=r.stock; const fric=cum.inc-cum.roll-cum.tier-r.stock-r.bank;
      out.push(`t${Math.round(r.t)}: inc ${cum.inc.toFixed(0)} | board ${r.stock.toFixed(0)} swaps ${fric.toFixed(0)} rolls ${cum.roll.toFixed(0)} tiers ${cum.tier.toFixed(0)} bank ${r.bank.toFixed(0)} | lag ${(r.tier-r.avgT).toFixed(1)} fit ${r.fit.toFixed(1)} rolls/turn ${r.rolls.toFixed(0)}`);} });
  console.log('\n== '+name); out.forEach(l=>console.log('  '+l));
}
for (const [k,v] of Object.entries(INC)) for (const m of [1,2,3]) where(`${k}, tier costs x${m}`, {...v, tierCost:mult(m)});

// 3. rush: tier whenever affordable, keep only a minimal board (2 units)
function rush(name, over, n=1500){
  const p={...BASE,...over, plan:[0,0,1,1,1,1,1], boardByTurn:()=>2, maxRolls:0};
  const a=avgRuns(p,n); const reach=[]; for(let k=2;k<=6;k++){const r=a.find(r=>r.tier>=k-0.5); reach.push(r?Math.round(r.t):'-');}
  console.log(`rush ${name.padEnd(28)} reaches tier 2..6 on turns ${reach.join(' ')}`);
}
console.log('\nTier rush (buy tiers as soon as affordable, 2-unit board)');
for (const [k,v] of Object.entries(INC)) for (const m of [1,1.5,2,2.5,3]) rush(`${k} x${m}`, {...v, tierCost:mult(m)});
