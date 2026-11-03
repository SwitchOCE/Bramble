'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { parseQuestions } = require('../lib/questions');
const { GIT_DIR } = require('./helpers');

function show(spec) {
  return execFileSync('git', ['--git-dir=' + GIT_DIR, 'show', spec], { encoding: 'utf8' });
}

test('prototype OWNER-QUESTIONS: 16 numbered questions, none answered', () => {
  const r = parseQuestions(show('proto/main:docs/prototype/OWNER-QUESTIONS.md'));
  assert.equal(r.items.length, 16);
  assert.equal(r.count, 16);
  assert.deepEqual(r.items.map((i) => i.id), Array.from({ length: 16 }, (_, i) => String(i + 1)));
  assert.equal(r.items[0].title, 'Filler units.');
});

test('review queue: B1-B7 plus items 16 and 17; answered summaries do not count', () => {
  const r = parseQuestions(show('design/tribes-and-budget:docs/design/review-queue.md'));
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
