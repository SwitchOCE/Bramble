'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { isAllowed, normalise } = require('../lib/ipallow');

test('allows loopback, LAN and Tailscale IPv4', () => {
  for (const a of ['127.0.0.1', '127.8.9.10', '192.168.4.56', '192.168.0.1', '192.168.255.255', '100.64.0.1', '100.92.26.47', '100.127.255.254']) {
    assert.ok(isAllowed(a), a);
  }
});

test('refuses everything else on IPv4', () => {
  for (const a of ['10.0.0.5', '172.17.0.2', '8.8.8.8', '192.169.0.1', '100.63.255.255', '100.128.0.1', '0.0.0.0', '255.255.255.255']) {
    assert.ok(!isAllowed(a), a);
  }
});

test('IPv4-mapped IPv6 is judged as IPv4, in any spelling', () => {
  assert.ok(isAllowed('::ffff:192.168.4.10'));
  assert.ok(isAllowed('::FFFF:192.168.4.10'));
  assert.ok(isAllowed('::ffff:c0a8:040a'));
  assert.ok(isAllowed('0:0:0:0:0:ffff:c0a8:40a'));
  assert.ok(isAllowed('::ffff:127.0.0.1'));
  assert.ok(isAllowed('::ffff:100.92.26.47'));
  assert.ok(!isAllowed('::ffff:8.8.8.8'));
  assert.ok(!isAllowed('::ffff:0808:0808'));
  assert.ok(!isAllowed('::ffff:10.1.2.3'));
  assert.equal(normalise('::ffff:c0a8:040a').address, '192.168.4.10');
});

test('IPv6: loopback, link-local and unique-local allowed; global refused', () => {
  assert.ok(isAllowed('::1'));
  assert.ok(isAllowed('fe80::1ae9:aee0:ade5:30f3'));
  assert.ok(isAllowed('fe80::1%wlo1'), 'zone id');
  assert.ok(isAllowed('fd69:74fe:2318:1:48c1:d1e2:828:48a9'), 'LAN ULA');
  assert.ok(isAllowed('fd7a:115c:a1e0::4501:1ac1'), 'Tailscale IPv6');
  assert.ok(!isAllowed('2403:5810:74c6:0:ecb:c4ef:2e4b:7276'), 'global unicast, even our own prefix');
  assert.ok(!isAllowed('2001:4860:4860::8888'));
  assert.ok(!isAllowed('::'));
  assert.ok(!isAllowed('::192.168.4.10'), 'deprecated IPv4-compatible form');
  assert.ok(!isAllowed('64:ff9b::c0a8:40a'), 'NAT64 is not the LAN');
});

test('junk is refused', () => {
  for (const a of [undefined, null, '', 'localhost', '192.168.1', '::ffff:999.1.1.1', 'fe80::1::2']) assert.ok(!isAllowed(a), String(a));
});
