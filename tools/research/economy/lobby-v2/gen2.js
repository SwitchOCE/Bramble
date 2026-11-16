const l=[['now',[8,12,16,19,21]],['N6a',[8,12,16,19,26]],['N6b',[8,12,16,19,31]],['M1',[8,12,17,22,27]],['M1b',[8,12,17,22,32]],['M2',[8,13,19,25,31]],['A',[8,14,22,30,38]]].map(([label,t])=>({label,cfg:{tierBase:t}}));
const M1=[8,12,17,22,27];
l.push({label:'A weakSpell',cfg:{spellPct:0.18}},{label:'M1 g1.35',cfg:{tierBase:M1,growth:1.35}},{label:'M1 g1.7',cfg:{tierBase:M1,growth:1.7}},{label:'M1 econ0',cfg:{tierBase:M1,econShare:0}},{label:'M1 econStrong',cfg:{tierBase:M1,econGold:[0,1,2,2,3,3,4],econPow:0.6}},{label:'M1 hp34',cfg:{tierBase:M1,hp:34}},{label:'M1 bigBonus5',cfg:{tierBase:M1,bigBonus:5}},{label:'now hp34',cfg:{tierBase:[8,12,16,19,21],hp:34}});
require('fs').writeFileSync('configs2.json',JSON.stringify(l));console.log(l.length);
