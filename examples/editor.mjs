import { html, css, editor } from '../_build/js/release/build/bridge/bridge.js';
import assert from 'node:assert/strict';

// 模拟编辑器调用，核心计算来自 MoonBit 编译产物。
for (const [fn, source] of [
  [html, 'nav>ul>li.item$*3>a{链接$}'],
  [css, 'm10+w50p+d:f'],
  [editor, 'a[href=""]'],
  [html, 'div>'],
]) {
  const result = JSON.parse(fn(source));
  // 同时检查宿主边界，避免示例只打印结果却掩盖接口错误。
  assert.equal(result.ok, source !== 'div>');
  if (fn === editor) {
    assert.deepEqual(result.tabstops, [9, 11]);
    assert.equal(result.html, '<a href=""></a>');
  }
  if (!result.ok) assert.equal(result.offset, 4);
  console.log(JSON.stringify({ source, ...result }));
}
