'use strict';
const os = require('node:os');
const path = require('node:path');
const fs = require('node:fs');
const http = require('node:http');

const GIT_DIR = process.env.PORTAL_GIT_DIR || path.join(os.homedir(), 'code/Bramble/.git');

function tmpDir(prefix) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

// Starts the app on an ephemeral loopback port; returns { base, close }.
async function startApp(app) {
  const server = http.createServer(app.handler);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  return { base, close: () => new Promise((r) => server.close(r)) };
}

// Raw request so paths aren't normalised by a client library.
function rawGet(base, rawPath, headers = {}, method = 'GET') {
  const u = new URL(base);
  return new Promise((resolve, reject) => {
    const req = http.request({ host: u.hostname, port: u.port, path: rawPath, method, headers }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks) }));
    });
    req.on('error', reject);
    req.end();
  });
}

module.exports = { GIT_DIR, tmpDir, startApp, rawGet };
