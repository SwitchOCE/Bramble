'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { isAllowed } = require('../lib/ipallow');

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

test('refuses any IPv6 form, including mapped and loopback (IPv4 only)', () => {
  for (const a of ['::1', '::ffff:192.168.4.10', 'fe80::1', 'fd69:74fe:2318:1::1', 'fd7a:115c:a1e0::4501:1ac1', '2403:5810:74c6::1']) {
    assert.ok(!isAllowed(a), a);
  }
});

test('junk is refused', () => {
  for (const a of [undefined, null, '', 'localhost', '192.168.1', '192.168.1.256', ' 192.168.1.1']) assert.ok(!isAllowed(a), String(a));
});
