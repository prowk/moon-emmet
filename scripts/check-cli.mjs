import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';

// 直接执行构建产物，检查退出码和 stdout 协议，避免 moon run 包装掩盖差异。
const executable = '_build/js/release/build/cmd/emmet/emmet.js';
function run(args, status) {
  const result = spawnSync(process.execPath, [executable, ...args], { encoding: 'utf8' });
  if (result.error) throw result.error;
  assert.equal(result.status, status, result.stderr || result.stdout);
  return result.stdout.trim();
}
assert.equal(JSON.parse(run(['--css', '--json', 'm10-20+c#fff'], 0)).css, 'margin: 10px 20px;\ncolor: #fff;');
assert.deepEqual(JSON.parse(run(['--editor', 'p{中😀}+a[href=""]'], 0)).tabstops, [19, 21]);
assert.equal(run(['--xhtml', 'br'], 0), '<br />');
assert.equal(run(['--pretty', 'ul>li*2'], 0), '<ul>\n  <li></li>\n  <li></li>\n</ul>');
for (const args of [[], ['--unknown'], ['div', 'p'], ['--css', '--pretty', 'm1']]) {
  const result = JSON.parse(run(args, 2));
  assert.equal(result.ok, false);
  assert.equal(result.offset, 0);
}
assert.deepEqual(JSON.parse(run(['--css', 'm10+p-2'], 1)),
  { ok: false, error: '该 CSS 属性不接受负值', offset: 5 });
assert.equal(JSON.parse(run(['div>'], 1)).offset, 4);
assert.match(run(['--help'], 0), /用法/);
console.log('CLI 输出、错误位置与退出码验证通过');
