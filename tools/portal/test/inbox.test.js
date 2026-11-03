'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { Readable } = require('node:stream');
const { createInbox, decisionState, readForm } = require('../lib/inbox');
const { tmpDir } = require('./helpers');

test('a write is one complete JSON record, created with its folder, no temp file left', async () => {
  const dir = path.join(tmpDir('portal-inbox-'), 'nested', 'inbox');
  const inbox = createInbox(dir);
  const rec = await inbox.write({ kind: 'answer', decisionId: 'look-direction', choice: 'Folk Print', note: 'Lighter black.', userAgent: 'UA' }, new Date('2026-11-04T10:15:00.123Z'));
  const names = fs.readdirSync(dir);
  assert.deepEqual(names, [`${rec.id}.json`]);
  assert.match(rec.id, /^20261104T101500Z-answer-look-direction-[0-9a-f]{6}$/);
  const onDisk = JSON.parse(fs.readFileSync(path.join(dir, names[0]), 'utf8'));
  assert.deepEqual(Object.keys(onDisk), ['id', 'time', 'kind', 'decisionId', 'choice', 'note', 'userAgent']);
  assert.equal(onDisk.time, '2026-11-04T10:15:00.123Z');
  assert.equal(onDisk.choice, 'Folk Print');
});

test('bad kinds and ids are refused', async () => {
  const inbox = createInbox(tmpDir('portal-inbox-'));
  await assert.rejects(inbox.write({ kind: 'delete', decisionId: 'x' }));
  await assert.rejects(inbox.write({ kind: 'answer', decisionId: '../x' }));
});

test('state: open, then waiting, then done with the handled summary; a newer answer is waiting again', async () => {
  const dir = tmpDir('portal-inbox-');
  const inbox = createInbox(dir);
  const card = { id: 'look-direction', sourcesAnswered: false };
  assert.equal(decisionState(card, (await inbox.read()).records).state, 'open');

  const rec = await inbox.write({ kind: 'answer', decisionId: card.id, choice: 'Woodcraft' }, new Date('2026-11-04T10:00:00Z'));
  let st = decisionState(card, (await inbox.read()).records);
  assert.equal(st.state, 'waiting');
  assert.equal(st.answer.choice, 'Woodcraft');

  fs.writeFileSync(path.join(dir, `${rec.id}.handled.json`), JSON.stringify({ handledAt: '2026-11-04T11:00:00Z', by: 'design-lab agent', summary: 'Woodcraft is now the base look.' }));
  st = decisionState(card, (await inbox.read()).records);
  assert.equal(st.state, 'done');
  assert.equal(st.summary, 'Woodcraft is now the base look.');
  assert.equal(st.handled.by, 'design-lab agent');

  await inbox.write({ kind: 'answer', decisionId: card.id, choice: 'Folk Print' }, new Date('2026-11-04T12:00:00Z'));
  st = decisionState(card, (await inbox.read()).records);
  assert.equal(st.state, 'waiting', 'changing your mind needs an agent again');
  assert.equal(st.answer.choice, 'Folk Print');
});

test('state: a source marked answered counts as done, unless a newer answer waits', async () => {
  const inbox = createInbox(tmpDir('portal-inbox-'));
  const card = { id: 'seed', sourcesAnswered: true };
  assert.equal(decisionState(card, []).state, 'done');
  assert.equal(decisionState(card, []).bySource, true);
  await inbox.write({ kind: 'accept-small', decisionId: 'seed', choice: 'Random' });
  assert.equal(decisionState(card, (await inbox.read()).records).state, 'waiting');
});

test('a broken handled file still counts as handled; junk files are skipped', async () => {
  const dir = tmpDir('portal-inbox-');
  const inbox = createInbox(dir);
  const rec = await inbox.write({ kind: 'answer', decisionId: 'x', note: 'n' });
  fs.writeFileSync(path.join(dir, `${rec.id}.handled.json`), '{ nope');
  fs.writeFileSync(path.join(dir, 'junk.json'), '[1,2]');
  fs.writeFileSync(path.join(dir, '.half.tmp'), '{');
  const r = await inbox.read();
  assert.equal(r.records.length, 1);
  assert.ok(r.records[0].handled);
  assert.equal(decisionState({ id: 'x' }, r.records).state, 'done');
  assert.equal(r.problems.length, 2);
});

test('reading a missing inbox folder is empty, not an error', async () => {
  const r = await createInbox(path.join(tmpDir('portal-inbox-'), 'none')).read();
  assert.deepEqual(r.records, []);
});

function fakeReq(body, headers) {
  const r = Readable.from([Buffer.from(body)]);
  r.headers = headers;
  return r;
}

test('form bodies: parsed, size-limited, form type only', async () => {
  const f = await readForm(fakeReq('choice=Folk+Print&note=a%26b', { 'content-type': 'application/x-www-form-urlencoded; charset=UTF-8' }));
  assert.equal(f.get('choice'), 'Folk Print');
  assert.equal(f.get('note'), 'a&b');
  await assert.rejects(readForm(fakeReq('x'.repeat(100), { 'content-type': 'application/x-www-form-urlencoded' }), 50), (e) => e.status === 413);
  await assert.rejects(readForm(fakeReq('x', { 'content-type': 'application/x-www-form-urlencoded', 'content-length': '99999' }), 50), (e) => e.status === 413);
  await assert.rejects(readForm(fakeReq('{}', { 'content-type': 'application/json' })), (e) => e.status === 415);
});
