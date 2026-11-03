'use strict';
// Client allow-list: loopback, the home LAN and Tailscale, IPv4 only.
// The server listens on 0.0.0.0 alone, so every client address is a plain
// IPv4 string; anything else is refused.

const net = require('node:net');

const V4_RANGES = [
  ['127.0.0.0', 8], // loopback
  ['192.168.0.0', 16], // home LAN
  ['100.64.0.0', 10], // Tailscale (CGNAT range)
];

const list = new net.BlockList();
for (const [a, p] of V4_RANGES) list.addSubnet(a, p, 'ipv4');

function isAllowed(addr) {
  return typeof addr === 'string' && net.isIPv4(addr) && list.check(addr, 'ipv4');
}

module.exports = { isAllowed, V4_RANGES };
