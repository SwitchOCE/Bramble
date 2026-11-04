'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { parseQuestions } = require('../lib/questions');
const { GIT_DIR } = require('./helpers');

// Fixed commits, so answering a question on the live branch doesn't break the test.
const PROTO = '3062811'; // proto/main, 4 Nov 2026
const DESIGN = '0e482fd'; // design/tribes-and-budget, 4 Nov 2026

function show(spec) {
  return execFileSync('git', ['--git-dir=' + GIT_DIR, 'show', spec], { encoding: 'utf8' });
}

test('prototype OWNER-QUESTIONS at 3062811: 16 numbered questions, none answered', () => {
  const r = parseQuestions(show(`${PROTO}:docs/prototype/OWNER-QUESTIONS.md`));
  assert.equal(r.items.length, 16);
  assert.equal(r.count, 16);
  assert.deepEqual(r.items.map((i) => i.id), Array.from({ length: 16 }, (_, i) => String(i + 1)));
  assert.equal(r.items[0].title, 'Filler units.');
});

test('review queue at 0e482fd: B1-B7 plus items 16 and 17; answered summaries do not count', () => {
  const r = parseQuestions(show(`${DESIGN}:docs/design/review-queue.md`));
  assert.deepEqual(r.items.map((i) => i.id), ['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', '16', '17']);
  assert.equal(r.count, 9);
});

test('an item with an answer marker is not open', () => {
  const md = `# Q\n\n1. **One?** Text.\n   **Answer (4 Nov):** yes.\n2. **Two?** Text.\n3. ~~**Three?**~~ dropped.\n- **B1. Four?** Answered: no.\n- plain bullet\n`;
  const r = parseQuestions(md);
  assert.equal(r.items.length, 4);
  assert.equal(r.count, 1);
  assert.equal(r.answered, 3);
});

test('a file without numbered or ID-tagged items gives no count', () => {
  const r = parseQuestions('# Notes\n\n- something\n- something else\n');
  assert.equal(r.count, null);
});

test('numbered lines inside code fences are ignored', () => {
  const r = parseQuestions('1. **Real?**\n\n```\n2. not a question\n```\n');
  assert.equal(r.items.length, 1);
});

test('power-budget at cc5d416: section-scoped and heading anchors', () => {
  const { findQuestion } = require('../lib/questions');
  const q = parseQuestions(show('cc5d416:docs/design/power-budget.md'));
  const first = findQuestion(q, '9.1');
  assert.equal(first.section, '9');
  assert.match(first.title, /^How strong should late spells be\?/);
  assert.match(findQuestion(q, '9.9').title, /^Content rule for stat multiply and consume/);
  assert.match(findQuestion(q, '9.3').title, /^Where should strong shared economy live\?/);
  assert.equal(findQuestion(q, '9.11'), null);
  assert.match(findQuestion(q, '1').title, /^Recurring gold at the measured sink/, 'plain #1 still finds the first numbered item');
  assert.equal(findQuestion(q, '8.1').section, '8');
  const b8 = findQuestion(q, 'B8');
  assert.equal(b8.heading, true);
  assert.match(b8.title, /^Engine SP per gold/);
  assert.ok(!/## 11\./.test(b8.text) && !/Gold table/.test(b8.text), 'the block stops at the next heading of the same or a higher level');
  assert.equal(b8.answered, false);
  assert.match(findQuestion(q, 'B1').title, /^Break-even turn/);
  assert.equal(findQuestion(q, 'B9'), null);
});

test('a heading item is answered by an **Answered marker inside its block only', () => {
  const { findQuestion } = require('../lib/questions');
  const text = '## 10. Answers\n\n### B1. One\nText.\n**Answered (5 Nov 2026):** Yes.\n\n### B2. Two\nText.\n\n## 11. Next\n**Answered** but not in B2.\n';
  const q = parseQuestions(text);
  assert.equal(findQuestion(q, 'B1').answered, true);
  assert.equal(findQuestion(q, 'B2').answered, false);
});
