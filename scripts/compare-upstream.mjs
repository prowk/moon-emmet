import assert from 'node:assert/strict';
import emmet from 'emmet';
import { html, css } from '../_build/js/release/build/bridge/bridge.js';

// 用共同支持的配置比较真实上游结果；不把上游全部能力纳入兼容承诺。
const options = { 'output.format': false, 'output.field': (_index, placeholder) => placeholder,
  'stylesheet.floatUnit': 'px' };
const markup = [
  'div>p+span^footer', 'div>(header>p)+footer', '(b+i)*2',
  'ul>.item$*3', 'li.item$$@-3*2', 'ul*2>li{项目$}*1',
  'p>{点击 }+a[href=/docs]{文档}+{ 继续}', 'img[src=photo.png alt=图片]',
  'input:email[type=search name="" id=""]', 'div[title="你好😀"]>span{正文}',
];
for (const source of markup) {
  const actual = JSON.parse(html(source));
  assert.equal(actual.ok, true, source);
  assert.equal(actual.html, emmet(source, { type: 'markup', options }), source);
}
// 仅规范化声明之间的换行；属性、数值、单位和声明顺序必须一致。
const declarations = value => value.split(';').map(part => part.trim()).filter(Boolean).join(';');
const styles = ['m10+w50p+d:f', 'm10-20+p0-1e2r3p', 'm-10--20',
  'fz1.5+lh1.5+op0.5+z-1', 'c#fc0+bgc#e0+bdc#abc', 'pos:f+d:ib'];
for (const source of styles) {
  const actual = JSON.parse(css(source));
  assert.equal(actual.ok, true, source);
  assert.equal(declarations(actual.css), declarations(emmet(source, { type: 'stylesheet', options })), source);
}
// 明确保留的差异：输出转义、布尔属性样式和未知 CSS 的严格拒绝。
assert.equal(JSON.parse(html('p{<&}')).html, '<p>&lt;&amp;</p>');
assert.equal(JSON.parse(html('input[disabled]')).html, '<input type="text" disabled>');
assert.equal(JSON.parse(css('unknown10')).ok, false);
console.log(`Emmet 2.4.11 对照通过：${markup.length} 个 HTML、${styles.length} 个 CSS 用例`);
