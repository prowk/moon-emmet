import { expand } from '../_build/js/release/build/bridge/bridge.js';
import { applyToTextarea } from './editor-adapter.mjs';

const element = id => document.getElementById(id);
const area = element('document');
let stops = [];
let stopIndex = 0;
const options = () => element('mode').value === 'css'
  ? { mode: 'css' } : { mode: 'editor', pretty: element('pretty').checked };
function show(result) {
  element('output').textContent = result.ok ? result.html ?? result.css : '';
  element('status').textContent = result.ok
    ? `完成。占位位置（UTF-16）：${(result.tabstops ?? []).join(', ') || '无'}`
    : `错误：${result.error}（缩写字符位置 ${result.offset}）`;
}
function preview() {
  show(JSON.parse(expand(element('source').value, JSON.stringify(options()))));
}
element('preview').addEventListener('click', preview);
element('replace').addEventListener('click', () => {
  const result = applyToTextarea(area, options());
  show(result);
  stops = result.ok ? result.tabstops : [];
  stopIndex = 0;
  element('next').disabled = stops.length < 2;
});
element('next').addEventListener('click', () => {
  stopIndex += 1;
  area.focus();
  area.setSelectionRange(stops[stopIndex], stops[stopIndex]);
  element('next').disabled = stopIndex + 1 >= stops.length;
});
// 用户编辑后旧位置失效，避免将光标移到过期的偏移。
area.addEventListener('input', () => { stops = []; element('next').disabled = true; });
area.setSelectionRange(area.value.indexOf('a['), area.value.indexOf('\n结束'));
preview();
