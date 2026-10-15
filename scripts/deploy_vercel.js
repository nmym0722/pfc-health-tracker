const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');

function getVercelToken() {
  if (process.env.VERCEL_TOKEN) return process.env.VERCEL_TOKEN;

  // secrets_memo.txt から自動取得
  const secretsPath = 'C:\\devlop\\toiecapps\\secrets_memo.txt';
  if (fs.existsSync(secretsPath)) {
    const text = fs.readFileSync(secretsPath, 'utf8');
    const match = text.match(/### 7\.\s*Vercel Access Token[\s\S]*?- \*\*Token\*\*:\s*([^\r\n]+)/);
    if (match && match[1]) {
      return match[1].trim();
    }
  }

  // %APPDATA%\com.vercel.cli\Data\auth.json からフォールバック
  const authPath = path.join(process.env.APPDATA || '', 'com.vercel.cli/Data/auth.json');
  if (fs.existsSync(authPath)) {
    try {
      const auth = JSON.parse(fs.readFileSync(authPath, 'utf8'));
      if (auth.token) return auth.token;
    } catch (_) {}
  }

  throw new Error('Vercel Access Token not found in env, secrets_memo.txt, or auth.json');
}

const TOKEN = getVercelToken();
const TEAM_ID = 'team_ypGFKekem6id7A5XuQecBTKt';
const PROJECT_ID = 'prj_vw3WSevTwSSmV06hZSKuTqiAhCHm';
const PROJECT_NAME = 'pfc-tracker';
const WEB_DIR = path.resolve(__dirname, '../build/web');

function request(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      const chunks = [];
      res.on('data', (d) => chunks.push(d));
      res.on('end', () => {
        const resBody = Buffer.concat(chunks).toString();
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(resBody));
          } catch (_) {
            resolve(resBody);
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${resBody}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

function getFiles(dir, base = '') {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    if (file === '.vercel') continue;
    const fullPath = path.join(dir, file);
    const relPath = path.posix.join(base, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      results = results.concat(getFiles(fullPath, relPath));
    } else {
      const content = fs.readFileSync(fullPath);
      const sha = crypto.createHash('sha1').update(content).digest('hex');
      results.push({
        file: relPath,
        size: stat.size,
        sha,
        content,
      });
    }
  }
  return results;
}

async function uploadFile(file) {
  const options = {
    hostname: 'api.vercel.com',
    path: `/v2/files?teamId=${TEAM_ID}`,
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
      'Content-Type': 'application/octet-stream',
      'Content-Length': file.size,
      'x-vercel-digest': file.sha,
    },
  };
  return request(options, file.content);
}

async function main() {
  console.log('[Vercel Deploy] Scanning files in build/web...');
  const files = getFiles(WEB_DIR);
  console.log(`[Vercel Deploy] Found ${files.length} files. Uploading to Vercel...`);

  const concurrency = 5;
  for (let i = 0; i < files.length; i += concurrency) {
    const batch = files.slice(i, i + concurrency);
    await Promise.all(batch.map(f => uploadFile(f).catch(e => {
      if (e.message.includes('409') || e.message.includes('already exists')) return;
      throw e;
    })));
    process.stdout.write(`\r[Vercel Deploy] Upload progress: ${Math.min(i + concurrency, files.length)} / ${files.length}`);
  }
  console.log('\n[Vercel Deploy] All files uploaded. Creating deployment...');

  const deployPayload = JSON.stringify({
    name: PROJECT_NAME,
    project: PROJECT_ID,
    target: 'production',
    files: files.map(f => ({
      file: f.file,
      sha: f.sha,
      size: f.size,
    })),
  });

  const deployOptions = {
    hostname: 'api.vercel.com',
    path: `/v13/deployments?teamId=${TEAM_ID}`,
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(deployPayload),
    },
  };

  const result = await request(deployOptions, deployPayload);
  console.log('\n=============================================================');
  console.log(' Vercel Production Deployment SUCCESS!');
  console.log(` Deployment URL: https://${result.url}`);
  console.log(` Production URL: https://pfc-tracker-tau.vercel.app/`);
  console.log('=============================================================\n');
}

main().catch(err => {
  console.error('\n[Vercel Deploy] Error:', err.message);
  process.exit(1);
});
