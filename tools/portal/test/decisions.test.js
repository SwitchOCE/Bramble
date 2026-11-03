'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { parseCard, bodyParts, loadDecisions, groupTitle } = require('../lib/decisions');
const { makeGit } = require('../lib/git');
const { createImageStore } = require('../lib/images');
const { GIT_DIR } = require('./helpers');

const FIX = path.join(__dirname, 'fixtures', 'decisions');
const BAD = path.join(__dirname, 'fixtures', 'decisions-bad');
const BRANCHES = ['design-lab/main', 'proto/main', 'main', 'portal/main'];
const read = (dir, n) => fs.readFileSync(path.join(dir, n), 'utf8');

test('the fixture cards parse cleanly', () => {
  for (const n of fs.readdirSync(FIX)) {
    const c = parseCard(read(FIX, n), n, { imageBranches: BRANCHES });
    assert.deepEqual(c.problems, [], n);
    assert.ok(c.headline && c.body, n);
  }
});

test('a card reads every field; "#16" survives comment stripping', () => {
  const text = `---
id: look-direction
group: looks                 # looks | plays | units | prototype | code
size: big                    # big | small
headline: Pick the look
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#16     # repeatable; #<n> or #B1 etc.
source: design/tribes-and-budget:docs/design/review-queue.md#B1
image: design-lab/main:docs/design-lab/game/a.jpg | The shop in Folk Print   # repeatable
option: Folk Print
option: Woodcraft
suggested: folk print
---
Intro.

{image:1}

After.

## Detail
More.
`;
  const c = parseCard(text, 'look-direction.md', { imageBranches: BRANCHES });
  assert.deepEqual(c.problems, []);
  assert.equal(c.group, 'looks');
  assert.equal(c.size, 'big');
  assert.equal(c.sources[0].path, 'docs/prototype/OWNER-QUESTIONS.md');
  assert.equal(c.sources[0].ref, '16');
  assert.equal(c.sources[1].ref, 'B1');
  assert.equal(c.images[0].caption, 'The shop in Folk Print');
  assert.equal(c.images[0].path, 'docs/design-lab/game/a.jpg');
  assert.deepEqual(c.options, ['Folk Print', 'Woodcraft']);
  assert.equal(c.suggested, 'Folk Print', 'matched case-insensitively, stored as the option');
  assert.equal(c.detail, 'More.');
  const parts = bodyParts(c);
  assert.deepEqual(parts.map((p) => (p.image ? `img${p.image.n}` : p.md.trim())), ['Intro.', 'img1', 'After.']);
});

test('pictures the text does not place go at the end', () => {
  const c = parseCard(read(FIX, 'look-direction.md').replace('{image:2}', ''), 'look-direction.md', { imageBranches: BRANCHES });
  const parts = bodyParts(c);
  assert.equal(parts[parts.length - 1].image.n, 2);
});

test('malformed cards are reported in plain words, never thrown', () => {
  const none = parseCard(read(BAD, 'no-header.md'), 'no-header.md');
  assert.equal(none.headline, 'no-header', 'falls back to the file name');
  assert.ok(none.problems.some((p) => /no header/.test(p)));
  assert.equal(none.group, null);
  assert.equal(groupTitle(none.group), 'Other decisions');

  const unclosed = parseCard(read(BAD, 'unclosed.md'), 'unclosed.md');
  assert.ok(unclosed.problems.some((p) => /closing "---"/.test(p)));
  assert.ok(unclosed.problems.some((p) => /no text/.test(p)));

  const b = parseCard(read(BAD, 'broken-fields.md'), 'broken-fields.md', { imageBranches: BRANCHES });
  const all = b.problems.join('\n');
  for (const re of [
    /id "something-else" doesn't match/,
    /"weather" isn't one of the groups/,
    /Size "huge"/,
    /unknown field "colour"/,
    /only one option/,
    /suggested answer "Not an option" isn't one of the options/,
    /source "not a source"/,
    /Picture 1 can't be shown: not in the form branch:path/,
    /Picture 2 can't be shown: it is not a jpg/,
    /Picture 3 can't be shown: pictures aren't shared from the secret\/branch branch/,
    /line I can't read/,
    /no headline/,
    /places picture 7/,
  ]) assert.match(all, re);
  assert.equal(b.size, 'big', 'bad size falls back to big');
  assert.ok(Array.isArray(bodyParts(b)));

  assert.ok(parseCard(null, 'x.md').problems.length, 'an unreadable file is a problem, not a throw');
  assert.ok(parseCard('---\r\nid: crlf\r\ngroup: code\r\nsize: big\r\nheadline: CRLF\r\n---\r\nText.\r\n', 'crlf.md').problems.length === 0, 'CRLF cards parse');
});

test('loading from a folder resolves pictures from git and ignores README', async () => {
  const git = makeGit(GIT_DIR);
  const resolve = (n) => git.resolveBranch(n);
  const r = await loadDecisions({ git, resolve, dir: FIX, images: createImageStore(git), imageBranches: BRANCHES });
  assert.deepEqual(r.problems, []);
  assert.equal(r.cards.length, fs.readdirSync(FIX).length);
  const look = r.cards.find((c) => c.id === 'look-direction');
  assert.match(look.images[0].blobId, /^[0-9a-f]{40}$/);
  assert.deepEqual(look.images[0].size, { width: 1688, height: 780 });
  assert.equal(look.sources[0].found, true);

  const bad = await loadDecisions({ git, resolve, dir: BAD, images: createImageStore(git), imageBranches: BRANCHES });
  assert.deepEqual(bad.cards.map((c) => c.id).sort(), ['broken-fields', 'no-header', 'unclosed']);
});

test('a card counts as answered only when every source question is marked answered', async () => {
  const files = {
    'q.md': '1. **One.** Open?\n2. **Two.** Done?\n   **Answered (5 Nov 2026):** Yes.\n- **B1. Bee.** Open?\n',
  };
  const git = {
    showFile: async (sha, p) => files[p] ?? null,
    listDir: async () => null,
    objectId: async () => null,
    blob: async () => Buffer.alloc(0),
  };
  const resolve = async (n) => (n === 'b' ? { name: 'b', sha: 'x' } : null);
  const tmp = fs.mkdtempSync(path.join(require('node:os').tmpdir(), 'portal-cards-'));
  const card = (id, ...sources) =>
    fs.writeFileSync(path.join(tmp, `${id}.md`), `---\nid: ${id}\ngroup: code\nsize: big\nheadline: H\n${sources.map((s) => `source: ${s}\n`).join('')}---\nText.\n`);
  card('answered', 'b:q.md#2');
  card('open', 'b:q.md#1');
  card('mixed', 'b:q.md#2', 'b:q.md#B1');
  card('missing', 'b:q.md#9');
  card('nobranch', 'nope:q.md#2');
  card('none');
  card('withdoc', 'b:q.md#2', 'b:q.md');
  const r = await loadDecisions({ git, resolve, dir: tmp, images: createImageStore(git), imageBranches: [], questionFiles: [{ id: 'ws', title: 'Things', path: 'q.md', branch: 'b' }] });
  const by = Object.fromEntries(r.cards.map((c) => [c.id, c]));
  assert.equal(by.answered.sourcesAnswered, true);
  assert.equal(by.open.sourcesAnswered, false);
  assert.equal(by.mixed.sourcesAnswered, false);
  assert.equal(by.missing.sourcesAnswered, false);
  assert.equal(by.missing.sources[0].found, false);
  assert.equal(by.nobranch.sourcesAnswered, false);
  assert.equal(by.none.sourcesAnswered, false);
  assert.equal(by.withdoc.sourcesAnswered, true, 'a source with no number is background, not a question');
  assert.equal(by.withdoc.sources[1].background, true);
  assert.equal(by.answered.sources[0].title, 'Two.');
  assert.deepEqual(by.answered.sources[0].workstream, { id: 'ws', title: 'Things' });
});
