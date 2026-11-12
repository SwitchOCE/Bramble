const A=[8,14,22,30,38], list=[];
const pr={now:[8,12,16,19,21],A,B:[9,16,25,34,43],C:[10,18,28,38,48],A5lo:[8,14,22,26,38],A5hi:[8,14,22,34,38],A6hi:[8,14,22,30,46],A6vhi:[8,14,22,30,54],A56hi:[8,14,22,34,46],A5lo6hi:[8,14,22,26,46],A4lo:[8,14,19,30,42]};
for(const k in pr) list.push({label:k,cfg:{tierBase:pr[k]}});
list.push({label:'A disc2',cfg:{disc:[2]}},{label:'A disc0',cfg:{disc:[0]}},{label:'A discslow',cfg:{disc:[1,1,2,2,3,3,4,4,5]}});
const fudge={'g1.35':{growth:1.35},'g1.7':{growth:1.7},'sp0.03':{scalePct:0.03},'sp0.08':{scalePct:0.08},'econ0':{econShare:0},'econStrong':{econGold:[0,1,2,2,3,3,4],econPow:0.6},'sigma0.12':{sigma:0.12}};
for(const [n,b] of [['A',A],['A6hi',pr.A6hi]]) for(const k in fudge) list.push({label:n+' '+k,cfg:{tierBase:b,...fudge[k]}});
const od=JSON.parse(JSON.stringify([null,[100],[60,40],[35,40,25],[20,30,32,18],[12,20,28,27,13],[7,13,22,27,21,10]]));od[5]=[14,22,30,27,7];od[6]=[8,15,24,28,20,5];
list.push({label:'A hp34',cfg:{hp:34}},{label:'A hp46',cfg:{hp:46}},{label:'A dmgCap14',cfg:{dmgCap:14}},{label:'A bigBonus5',cfg:{bigBonus:5}},{label:'A incLate2',cfg:{incLate:2}},{label:'A incKnee13',cfg:{incKnee:13}},{label:'A stingyOdds',cfg:{odds:od}});
require('fs').writeFileSync('configs.json',JSON.stringify(list));console.log(list.length);
