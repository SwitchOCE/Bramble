const { ODDS } = require('./model.js');
const TFT = { L3:[75,25,0,0,0], L4:[55,30,15,0,0], L5:[45,33,20,2,0], L6:[30,40,25,5,0], L7:[19,30,40,10,1], L8:[18,25,32,22,3], L9:[10,20,25,35,10], L10:[5,10,20,40,25] };
const atLeast1 = (p, slots=5) => 1 - Math.pow(1 - p/100, slots);
for (const [name, tab] of Object.entries(ODDS)) {
  console.log('\n'+name+'  (per tier: top-tier % per slot | P(>=1 top-tier unit in a 5-slot shop) | P(>=1 of top two tiers) | shops to see one SPECIFIC unit of the top tier, n=8/12/16 such units in a lobby | specific tier-1 unit, n=12)');
  for (let T=2; T<=6; T++) {
    const o = tab[T]; const top=o[T-1], top2=o[T-1]+o[T-2];
    const spec = n => (1/atLeast1(top/n)).toFixed(1);
    console.log(`  tier ${T}: ${String(top).padStart(3)}% | ${(100*atLeast1(top)).toFixed(0).padStart(3)}% | ${(100*atLeast1(top2)).toFixed(0).padStart(3)}% | ${spec(8)} / ${spec(12)} / ${spec(16)} | ${(1/atLeast1(o[0]/12)).toFixed(1)}`);
  }
}
console.log('\nTFT (long-standing table, 5 slots): top-cost-at-level');
for (const [L,o] of Object.entries(TFT)) { let k=o.length-1; while(o[k]===0)k--; console.log(`  ${L}: cost ${k+1} at ${o[k]}% -> P(>=1)/shop ${(100*atLeast1(o[k])).toFixed(0)}%; 4- or 5-cost ${(100*atLeast1(o[3]+o[4])).toFixed(0)}%`); }
// BG with its own shop sizes (units 3,4,4,5,5,6)
const bgSlots=[0,3,4,4,5,5,6];
console.log('\nBG with its real unit slots:'); for (let T=2;T<=6;T++){const top=ODDS.bg[T][T-1]; console.log(`  tier ${T}: ${top}% x ${bgSlots[T]} slots -> P(>=1 top)/shop ${(100*atLeast1(top,bgSlots[T])).toFixed(0)}%`);}
// rolls affordable with current schedule
const price = n => n<15?1:2+Math.floor((n-15)/5);
console.log('\nShops a player sees if they put G gold into rolls (current schedule 15 at 1, then +1 per 5):');
for (const G of [5,10,15,20,25,30,40,50]) { let g=G,n=0; while(g>=price(n)){g-=price(n);n++;} console.log(`  ${G} gold -> ${n} shops`); }
