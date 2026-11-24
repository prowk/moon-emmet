import { spawnSync } from 'node:child_process';

// 一次执行必要检查；不安装依赖、不调用外部服务。
const moon = process.platform === 'win32' ? 'moon.exe' : 'moon';
for (const args of [
  ['fmt', '--check'],
  ['check', '--deny-warn'],
  ['test', '--deny-warn'],
  ['test', '--target', 'js', '--deny-warn'],
  ['build', 'bridge', '--target', 'js', '--release'],
]) {
  const result = spawnSync(moon, args, { stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
const demo = spawnSync(process.execPath, ['examples/editor.mjs'], { stdio: 'inherit' });
if (demo.error) throw demo.error;
process.exit(demo.status ?? 1);
