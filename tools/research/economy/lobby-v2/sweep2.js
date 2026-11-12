// usage: node sweep2.js configs2.json [7,11,23]  -> results2.json, results2.md (mean over seeds)
'use strict';
const { spawn } = require('child_process');
const fs = require('fs'), path = require('path');
const list = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const seeds = (process.argv[3] || '7,11,23').split(',').map(Number);
const jobs = []; for (const c of list) for (const s of seeds) jobs.push({ c, s });
const results = []; let next = 0, running = 0;
const nn = a => a.filter(x => x != null && !isNaN(x));
const mean = a => { a = nn(a); return a.length ? a.reduce((x, y) => x + y, 0) / a.length : null; };
const f = (x, d = 1) => x == null ? '-' : x.toFixed(d);
const rng = (a, d = 1) => { a = nn(a); return a.length ? `${f(mean(a), d)} [${f(Math.min(...a), d)}-${f(Math.max(...a), d)}]` : '-'; };
function row(label) {
  const rs = results.filter(x => x.label === label).map(x => x.r);
  const F = k => rs.map(r => r.free[k]), S = (c, k) => rs.map(r => r.strata.byCap[c][k]);
  const pb = i => f(mean(rs.map(r => r.free.placeBy[i])), 2);
  const sp = c => `${f(mean(S(c, 'place')), 2)}±${f(mean(S(c, 'sd')), 2)}`;
  const caps = [4, 5, 6].map(c => rs.reduce((a, r) => a + r.free.capDist[c], 0)).join('/');
  const ln = i => f(mean(rs.map(r => r.free.len[i])), 0);
  return `| ${label} (n=${rs.length}) | ${rng(F('pT4'))} | ${rng(F('pT5'))} | ${rng(F('pT6'))} | ${rng(F('t6PerLobby'), 2)} | ${f(mean(F('tT4')))} | ${f(mean(F('tT5')))} | ${f(mean(F('tT6')))} | ${pb(0)}/${pb(1)}/${pb(2)}/${pb(3)} | ${f(mean(F('t6Top4')))}/${f(mean(F('t6Bot4')))} | ${ln(0)}/${ln(1)}/${ln(2)} | ${f(mean(F('firstOut')))} | ${f(mean(F('out45')))} | ${sp(4)} | ${sp(5)} | ${sp(6)} | ${f(mean(S(5, 'reach')))} | ${f(mean(S(6, 'reach')))} | ${f(mean(S(5, 'b78')))} vs ${f(mean(S(4, 'b78')))} | ${f(mean(F('rusher')), 2)} | ${f(mean(F('econGold')))} | ${caps} |`;
}
function write() {
  fs.writeFileSync(path.join(process.cwd(), 'results2.json'), JSON.stringify(results, null, 1));
  const h = '| label | %>=T4 | %>=T5 | %T6 | T6/lobby | T4 turn | T5 turn | T6 turn | place by peak (<=3/4/5/6) | T6 among top4 / bottom4 | len p10/50/90 | first out | out-turn 4th-5th | cap4 place±SD | cap5 place±SD | cap6 place±SD | cap5 reach% | cap6 reach% | cap5 7-8% vs cap4 7-8% | rusher place | econ gold | free survivors cap4/5/6 (sum) |\n|' + '---|'.repeat(22) + '\n';
  const labels = list.map(c => c.label).filter(l => results.some(x => x.label === l));
  fs.writeFileSync(path.join(process.cwd(), 'results2.md'), h + labels.map(row).join('\n') + '\n');
}
function launch() {
  while (running < 4 && next < jobs.length) {
    const { c, s } = jobs[next++]; running++;
    const ch = spawn(process.execPath, [path.join(__dirname, 'lobby2.js'), JSON.stringify({ ...(c.cfg || {}), seed: s }), c.label + ' s' + s]);
    let out = ''; ch.stdout.on('data', d => out += d); ch.stderr.on('data', d => process.stderr.write(d));
    ch.on('close', () => {
      running--;
      const m = out.match(/RESULT_JSON:(.*)/);
      if (m) { const j = JSON.parse(m[1]); j.label = c.label; j.seed = s; results.push(j); write(); console.log('done', c.label, s); }
      else console.log('FAILED', c.label, s);
      if (next >= jobs.length && running === 0) console.log('all done'); else launch();
    });
  }
}
launch();
