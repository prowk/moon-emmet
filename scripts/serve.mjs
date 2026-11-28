import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

// 仅开放示例和编译产物；固定 MIME，兼容 Windows 的 .mjs 注册差异。
const root = new URL('../', import.meta.url);
const files = new Map([
  ['/examples/editor.html', 'text/html; charset=utf-8'],
  ['/examples/editor-ui.mjs', 'text/javascript; charset=utf-8'],
  ['/examples/editor-adapter.mjs', 'text/javascript; charset=utf-8'],
  ['/_build/js/release/build/bridge/bridge.js', 'text/javascript; charset=utf-8'],
]);
const port = Number(process.argv[2] ?? 8000);
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('端口必须在 1 到 65535 之间');
const server = createServer(async (request, response) => {
  const path = new URL(request.url, 'http://localhost').pathname;
  if (path === '/favicon.ico') { response.writeHead(204).end(); return; }
  if (path === '/') { response.writeHead(302, { location: '/examples/editor.html' }).end(); return; }
  if (!files.has(path) || !['GET', 'HEAD'].includes(request.method)) {
    response.writeHead(404).end('Not found'); return;
  }
  try {
    const data = await readFile(fileURLToPath(new URL(path.slice(1), root)));
    response.writeHead(200, { 'Content-Type': files.get(path), 'Content-Length': data.length,
      'Cache-Control': 'no-store' });
    response.end(request.method === 'HEAD' ? undefined : data);
  } catch {
    response.writeHead(404).end('File missing; run npm run build first');
  }
});
server.on('error', error => { console.error(error.message); process.exitCode = 1; });
server.listen(port, '127.0.0.1', () => console.log(`http://127.0.0.1:${port}/examples/editor.html`));
