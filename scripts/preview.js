const { spawn } = require('child_process');
const path = require('path');

// 1. 静的Web配信サーバー (serve_web.js) を起動
console.log('[Preview] 1/2: Starting static web server on port 8085...');
require('./serve_web');

// 2. Cloudflare Tunnel を起動
console.log('[Preview] 2/2: Starting Cloudflare Tunnel (pointing to 127.0.0.1:8085)...');

const npxCmd = process.platform === 'win32' ? 'npx.cmd' : 'npx';
const tunnel = spawn(npxCmd, ['--yes', 'cloudflared', 'tunnel', '--url', 'http://127.0.0.1:8085'], {
  stdio: ['ignore', 'pipe', 'pipe'],
  shell: true,
});

let urlFound = false;

function scanOutput(data) {
  const text = data.toString();
  // Cloudflare Tunnel の quick tunnel URL パターンを検出
  const match = text.match(/https:\/\/[a-zA-Z0-9-]+\.trycloudflare\.com/);
  if (match && !urlFound) {
    urlFound = true;
    const url = match[0];
    console.log('\n=============================================================');
    console.log(' PFC Health Tracker - Mobile Preview is READY!');
    console.log(` iPhone / スマホ接続先 URL: ${url}`);
    console.log('=============================================================\n');
  }
}

tunnel.stdout.on('data', scanOutput);
tunnel.stderr.on('data', scanOutput);

tunnel.on('close', (code) => {
  console.log(`[Preview] Cloudflare Tunnel exited with code ${code}`);
  process.exit(code);
});

process.on('SIGINT', () => {
  tunnel.kill();
  process.exit(0);
});
