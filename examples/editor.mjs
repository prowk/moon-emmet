import { html, css, editor } from '../_build/js/release/build/bridge/bridge.js';

// 模拟编辑器调用，核心计算来自 MoonBit 编译产物。
for (const [fn, source] of [
  [html, 'nav>ul>li.item$*3>a{链接$}'],
  [css, 'm10+w50p+d:f'],
  [editor, 'a[href=""]'],
  [html, 'div>'],
]) {
  const result = JSON.parse(fn(source));
  console.log(JSON.stringify({ source, ...result }));
}
