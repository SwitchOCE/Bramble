'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { parseStatusBlock, isNothingWaiting, stripStatusBlock } = require('../lib/status');

const good = `# Plan

<!-- status -->
- **Status:** waiting on you
- **Last step done:** Built the thing (4 Nov 2026).
- **Next step:** Build the next thing.
- **Waiting on you:** Play build 4; the 16 questions in \`docs/x.md\`.
<!-- /status -->

Body.`;

test('parses a well-formed block', () => {
  const r = parseStatusBlock(good);
  assert.equal(r.state, 'ok');
  assert.equal(r.status, 'waiting on you');
  assert.equal(r.fields.next, 'Build the next thing.');
  assert.equal(r.fields.lastDone, 'Built the thing (4 Nov 2026).');
  assert.match(r.fields.waiting, /16 questions/);
  assert.deepEqual(r.problems, []);
});

test('accepts every status word, case-insensitively', () => {
  for (const w of ['active', 'Waiting on you', 'PAUSED', 'done']) {
    const r = parseStatusBlock(good.replace('waiting on you', w));
    assert.equal(r.state, 'ok', w);
    assert.equal(r.status, w.toLowerCase());
  }
});

test('missing block is reported, not guessed', () => {
  const r = parseStatusBlock('# Plan\n\nNo block here.\n- **Status:** active\n');
  assert.equal(r.state, 'missing');
  assert.equal(r.status, null);
});

test('unreadable file is reported as missing', () => {
  assert.equal(parseStatusBlock(null).state, 'missing');
});

test('no closing marker is malformed', () => {
  const r = parseStatusBlock(good.replace('<!-- /status -->', ''));
  assert.equal(r.state, 'malformed');
  assert.match(r.problems[0], /closing/);
});

test('unknown status word is malformed and yields no status', () => {
  const r = parseStatusBlock(good.replace('waiting on you', 'blocked'));
  assert.equal(r.state, 'malformed');
  assert.equal(r.status, null);
  assert.ok(r.problems.some((p) => /blocked/.test(p)));
  assert.equal(r.fields.next, 'Build the next thing.', 'other fields still shown');
});

test('a missing label is malformed', () => {
  const r = parseStatusBlock(good.replace(/- \*\*Next step:\*\*.*\n/, ''));
  assert.equal(r.state, 'malformed');
  assert.ok(r.problems.some((p) => /Next step.*missing/.test(p)));
  assert.equal(r.status, 'waiting on you');
});

test('empty value, duplicate and stray lines are malformed', () => {
  assert.equal(parseStatusBlock(good.replace('Build the next thing.', '')).state, 'malformed');
  const dup = parseStatusBlock(good.replace('<!-- /status -->', '- **Status:** done\n<!-- /status -->'));
  assert.equal(dup.state, 'malformed');
  assert.equal(dup.status, 'waiting on you', 'first value kept');
  assert.equal(parseStatusBlock(good.replace('<!-- /status -->', 'Some prose\n<!-- /status -->')).state, 'malformed');
  assert.equal(parseStatusBlock(good.replace('**Next step:**', '**Next:**')).state, 'malformed');
});

test('CRLF files parse', () => {
  assert.equal(parseStatusBlock(good.replace(/\n/g, '\r\n')).state, 'ok');
});

test('nothing-waiting detection', () => {
  assert.ok(isNothingWaiting('Nothing yet.'));
  assert.ok(isNothingWaiting('Nothing.'));
  assert.ok(!isNothingWaiting('Play build 4.'));
  assert.ok(!isNothingWaiting('Nothing works until you answer question 3 about the hand and the pool.'));
});

test('stripStatusBlock removes only the block', () => {
  const s = stripStatusBlock(good);
  assert.ok(!s.includes('Status:'));
  assert.ok(s.includes('Body.'));
});

test('"In short" is optional, and read when present', () => {
  assert.equal(parseStatusBlock(good).fields.inShort, undefined);
  const withIt = parseStatusBlock(good.replace('- **Last step done:**', '- **In short:** Playable: a full game against bots.\n- **Last step done:**'));
  assert.equal(withIt.state, 'ok');
  assert.equal(withIt.fields.inShort, 'Playable: a full game against bots.');
  const empty = parseStatusBlock(good.replace('- **Last step done:**', '- **In short:**\n- **Last step done:**'));
  assert.equal(empty.state, 'malformed', 'an empty "In short" is reported');
  assert.equal(empty.fields.inShort, undefined);
});
