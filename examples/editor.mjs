import { html, css, editor, expand } from '../_build/js/release/build/bridge/bridge.js';
import assert from 'node:assert/strict';
import { expandSelection } from './editor-adapter.mjs';

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

// 实际替换带中文和非 BMP 字符的文档选区，校验文档前后内容和绝对光标位置。
const prefix = '说明😀\n';
const abbreviation = 'a[href=""]';
const document = prefix + abbreviation + '\n结尾';
const edit = expandSelection(document, prefix.length, prefix.length + abbreviation.length);
assert.equal(edit.ok, true);
assert.equal(edit.text, prefix + '<a href=""></a>\n结尾');
assert.deepEqual(edit.tabstops, [prefix.length + 9, prefix.length + 11]);
assert.equal(edit.selectionStart, prefix.length + 9);
assert.equal(expandSelection('😀', 1, 2).ok, false);
assert.equal(expandSelection('div>', 0, 4).ok, false);
const custom = JSON.parse(expand('card>input:search', JSON.stringify({
  mode: 'editor', pretty: true, snippets: [{ name: 'card', tag: 'article', attributes: [{ name: 'class', value: 'card' }] }],
})));
assert.equal(custom.ok, true);
assert.match(custom.html, /<article class="card">\n  <input type="search">\n<\/article>/);
assert.equal(JSON.parse(expand('img', '{"xhtml":true}')).html, '<img src="" alt="" />');
for (const config of ['null', '{"pretty":1}', '{"mode":"typo"}', '{"pretty":true,"pretty":false}', '{"mode":"css","pretty":true}']) {
  assert.equal(JSON.parse(expand('div', config)).ok, false);
}
console.log('编辑器替换、配置和 Unicode 位置验证通过');
