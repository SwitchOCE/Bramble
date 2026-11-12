// usage: node sweep.js configs.json   -> results.json, results.md
'use strict';
const { spawn } = require('child_process');
const fs = require('fs'), path = require('path');
const list = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const results = []; let next = 0, running = 0;
const f1 = x => x == null ? "-" : x.toFixed(1), f2 = x => x == null ? "-" : x.toFixed(2);

function row(x) {
  const F = x.r.free, S = x.r.strata.byCap;
  const sp = c => `${f2(S[c].place)}±${f2(S[c].sd)}`;
  return `| ${x.label} | ${f1(F.pT4)} | ${f1(F.pT5)} | ${f1(F.pT6)} | ${f2(F.t6PerLobby)} | ${F.tT5 ?? "-"} | ${F.tT6 ?? "-"} | ${F.placeBy.map(f2).join('/')} | ${f1(F.t6Top4)}/${f1(F.t6Bot4)} | ${F.len.join('/')} | ${F.firstOut} | ${sp(4)} | ${sp(5)} | ${sp(6)} | ${f1(S[5].b78)} vs ${f1(S[4].b78)} | ${f2(F.rusher)} | ${f1(F.econGold)} |`;
}
function write() {
  fs.writeFileSync(path.join(process.cwd(), 'results.json'), JSON.stringify(results, null, 1));
  const h = '| label | %>=T4 | %>=T5 | %T6 | T6/lobby | T5 turn | T6 turn | place by peak (<=3/4/5/6) | T6 among top4 / bottom4 | len p10/50/90 | first out | cap4 place±SD | cap5 place±SD | cap6 place±SD | cap5 7-8% vs cap4 7-8% | rusher place | econ gold |\n|' + '---|'.repeat(17) + '\n';
  const order = list.map(c => c.label);
  fs.writeFileSync(path.join(process.cwd(), 'results.md'), h + results.slice().sort((a, b) => order.indexOf(a.label) - order.indexOf(b.label)).map(row).join('\n') + '\n');
}
function launch() {
  while (running < 4 && next < list.length) {
    const c = list[next++]; running++;
    const ch = spawn(process.execPath, [path.join(__dirname, 'lobby2.js'), JSON.stringify(c.cfg || {}), c.label]);
    let out = ''; ch.stdout.on('data', d => out += d); ch.stderr.on('data', d => process.stderr.write(d));
    ch.on('close', () => {
      running--;
      const m = out.match(/RESULT_JSON:(.*)/);
      if (m) { const j = JSON.parse(m[1]); j.label = c.label; results.push(j); write(); console.log('done', c.label); }
      else console.log('FAILED', c.label);
      if (next >= list.length && running === 0) console.log('all done'); else launch();
    });
  }
}
launch();
