'use strict';
// Client allow-list: loopback, the home LAN and Tailscale, nothing else.
// IPv4-mapped IPv6 addresses (::ffff:a.b.c.d, in dotted or hex form) are
// judged as the IPv4 address they carry.

const net = require('node:net');

const V4_RANGES = [
  ['127.0.0.0', 8], // loopback
  ['192.168.0.0', 16], // home LAN
  ['100.64.0.0', 10], // Tailscale (CGNAT range)
];
const V6_RANGES = [
  ['::1', 128], // loopback
  ['fe80::', 10], // link-local: same network segment only, never routed
  ['fd00::', 8], // unique local addresses: the LAN's own IPv6 and Tailscale's fd7a:115c:a1e0::/48
];

const list = new net.BlockList();
for (const [a, p] of V4_RANGES) list.addSubnet(a, p, 'ipv4');
for (const [a, p] of V6_RANGES) list.addSubnet(a, p, 'ipv6');

// Returns { family: 4|6, address } with zone IDs removed and mapped
// addresses unwrapped, or null if it isn't an IP address.
function normalise(addr) {
  if (typeof addr !== 'string' || !addr) return null;
  let a = addr.trim();
  if (a.startsWith('[') && a.endsWith(']')) a = a.slice(1, -1);
  const zone = a.indexOf('%');
  if (zone !== -1) a = a.slice(0, zone);
  const fam = net.isIP(a);
  if (fam === 4) return { family: 4, address: a };
  if (fam !== 6) return null;
  const mapped = unmapV4(a);
  if (mapped) return { family: 4, address: mapped };
  return { family: 6, address: a.toLowerCase() };
}

// ::ffff:1.2.3.4 or ::ffff:0102:0304 (any spelling of the zero prefix).
function unmapV4(a) {
  const words = expandV6(a);
  if (!words) return null;
  for (let i = 0; i < 5; i++) if (words[i] !== 0) return null;
  if (words[5] !== 0xffff) return null;
  return [words[6] >> 8, words[6] & 255, words[7] >> 8, words[7] & 255].join('.');
}

// Expands an IPv6 address into 8 16-bit words.
function expandV6(a) {
  let s = a.toLowerCase();
  let tail = [];
  const v4 = /(\d+\.\d+\.\d+\.\d+)$/.exec(s);
  if (v4) {
    const parts = v4[1].split('.').map(Number);
    if (parts.some((n) => n > 255)) return null;
    tail = [(parts[0] << 8) | parts[1], (parts[2] << 8) | parts[3]];
    s = s.slice(0, -v4[1].length);
    if (s.endsWith(':') && !s.endsWith('::')) s = s.slice(0, -1);
  }
  const halves = s.split('::');
  if (halves.length > 2) return null;
  const parse = (h) => (h ? h.split(':').map((w) => parseInt(w, 16)) : []);
  const head = parse(halves[0]);
  const rest = halves.length === 2 ? parse(halves[1]) : [];
  const fill = 8 - tail.length - head.length - rest.length;
  if (halves.length === 1 && fill !== 0) return null;
  if (fill < 0) return null;
  const words = [...head, ...new Array(halves.length === 2 ? fill : 0).fill(0), ...rest, ...tail];
  if (words.length !== 8 || words.some((w) => Number.isNaN(w) || w < 0 || w > 0xffff)) return null;
  return words;
}

function isAllowed(addr) {
  const n = normalise(addr);
  if (!n) return false;
  return list.check(n.address, n.family === 4 ? 'ipv4' : 'ipv6');
}

module.exports = { isAllowed, normalise, V4_RANGES, V6_RANGES };
