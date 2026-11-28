import { expand } from '../_build/js/release/build/bridge/bridge.js';

// textarea 和 JS 字符串索引均为 UTF-16；禁止从代理对中间切开字符。
function validBoundary(text, index) {
  return Number.isInteger(index) && index >= 0 && index <= text.length && !(
    index > 0 && index < text.length &&
    text.charCodeAt(index - 1) >= 0xd800 && text.charCodeAt(index - 1) <= 0xdbff &&
    text.charCodeAt(index) >= 0xdc00 && text.charCodeAt(index) <= 0xdfff
  );
}

export function expandSelection(text, start, end, options = {}) {
  if (typeof text !== 'string' || !validBoundary(text, start) ||
      !validBoundary(text, end) || end < start) {
    return { ok: false, error: '选区必须是有效的 UTF-16 字符边界', offset: 0 };
  }
  const config = { mode: 'editor', ...options };
  const result = JSON.parse(expand(text.slice(start, end), JSON.stringify(config)));
  if (!result.ok) return result;
  const insertion = result.html ?? result.css;
  const tabstops = (result.tabstops ?? []).map(index => start + index);
  const caret = tabstops[0] ?? start + insertion.length;
  return { ...result, text: text.slice(0, start) + insertion + text.slice(end),
    insertion, tabstops, selectionStart: caret, selectionEnd: caret };
}

// 用户明确选中要展开的缩写；失败时不改变文档和选区。
export function applyToTextarea(textarea, options = {}) {
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const result = expandSelection(textarea.value, start, end, options);
  if (result.ok) {
    textarea.setRangeText(result.insertion, start, end, 'end');
    textarea.setSelectionRange(result.selectionStart, result.selectionEnd);
    textarea.focus();
  }
  return result;
}
