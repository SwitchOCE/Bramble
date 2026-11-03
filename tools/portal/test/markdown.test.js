'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { renderMarkdown, inline } = require('../lib/markdown');

test('escapes raw HTML and attributes', () => {
  const h = renderMarkdown('# <script>alert(1)</script>\n\nHi <img src=x onerror=alert(1)> & "q"\n');
  assert.ok(!h.includes('<script>'));
  assert.ok(!h.includes('<img'));
  assert.ok(h.includes('&lt;script&gt;'));
  assert.ok(h.includes('&amp;'));
});

test('drops HTML comments', () => {
  assert.ok(!renderMarkdown('<!-- status -->\ntext').includes('status'));
});

test('links: http kept, javascript and relative become text', () => {
  assert.match(inline('[a](https://x.org/?a=1&b=2)'), /<a href="https:\/\/x.org\/\?a=1&amp;b=2" rel="noopener noreferrer">a<\/a>/);
  assert.ok(!inline('[a](javascript:alert(1))').includes('href'));
  assert.ok(!inline('[a](rulebook.md)').includes('href'));
  assert.ok(!inline('[a"><b](https://x)').includes('"><b'));
});

test('emphasis, code and nested lists', () => {
  assert.equal(inline('**b** *i* `c*d*`'), '<strong>b</strong> <em>i</em> <code>c*d*</code>');
  assert.equal(inline('snake_case_name'), 'snake_case_name');
  const h = renderMarkdown('1. one\n   - a\n   - b\n2. two\n');
  assert.match(h, /<ol>\s*<li>one\s*<ul>/);
  assert.match(h, /<li>two<\/li>/);
});

test('tables', () => {
  const h = renderMarkdown('| a | b |\n|---|---|\n| 1 | `x|y` |\n');
  assert.match(h, /<th>a<\/th><th>b<\/th>/);
  assert.match(h, /<td><code>x\|y<\/code><\/td>/);
  const al = renderMarkdown('| a | b |\n|:-:|--:|\n| 1 | 2 |\n');
  assert.match(al, /<th class="align-center">a<\/th><th class="align-right">b<\/th>/);
  assert.ok(!al.includes('style='));
});
