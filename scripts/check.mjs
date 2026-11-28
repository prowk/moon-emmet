import { spawnSync } from 'node:child_process';

// 一次执行必要检查；上游对照依赖由 npm ci 安装，运行检查时不请求外部服务。
const moon = process.platform === 'win32' ? 'moon.exe' : 'moon';
for (const args of [
  ['fmt', '--check'],
  ['check', '--deny-warn'],
  ['test', '--deny-warn'],
  ['test', '--target', 'js', '--deny-warn'],
  ['build', 'bridge', '--target', 'js', '--release'],
  ['build', 'cmd/emmet', '--target', 'js', '--release'],
]) {
  const result = spawnSync(moon, args, { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
for (const script of ['examples/editor.mjs', 'scripts/check-cli.mjs', 'scripts/compare-upstream.mjs']) {
  const result = spawnSync(process.execPath, [script], { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
