# API 和宿主接口

MoonBit 调用方在 `moon.mod` 中添加 `prowk/moon-emmet` 依赖，在 `moon.pkg` 中导入 `"prowk/moon-emmet" @engine`。

| 入口 | 结果 |
| --- | --- |
| `parse(input, snippets~)` | `Result[Array[Element], ExpansionError]`，不复制重复子树 |
| `expand(input)` | 紧凑 HTML |
| `expand_with_options(input, options)` | 配置 HTML |
| `expand_for_editor(input, options?)` | `Expansion`，含 html 与 tabstops |
| `expand_css(input)` | CSS 声明字符串 |

`Options::new(pretty=false, indent="  ", xhtml=false, snippets=[])` 控制 HTML 输出；缩进最多八个空格或制表符。模板参数见 [元素模板](snippets.md)。结构树中的空 tag 容器表示分组，`is_text=true` 表示纯文本，`repeat_count` 与 `explicit_repeat` 表示重复语义。解析返回新树，修改它不会影响其他调用；展开入口自行解析输入，目前不接受调用方修改后的树。

所有库入口使用 `Result`，错误字段为 `message` 与 `offset`。语法错误位置为完整缩写中从零开始的 Unicode 字符序号，允许等于输入字符数（末尾缺失内容）。编号、配置、渲染和资源超限错误位置为 0，表示整个表达式。错误不是输出位置。编辑器 `tabstops` 则是最终 HTML 中从零开始的 UTF-16 单元索引，包括格式化、转义和编号产生的长度变化；空属性值和空的非空元素内容提供零宽占位。调用方需要替换选区后，将每个位置加上选区起点。

## JavaScript ESM

`moon build bridge --target js --release` 生成 `_build/js/release/build/bridge/bridge.js`。`html(source)`、`css(source)`、`editor(source)` 保留默认行为；`expand(source, configJson)` 支持可配置调用。参数和返回值均为字符串，返回值需 `JSON.parse`。

```javascript
import { expand } from './_build/js/release/build/bridge/bridge.js';
const result = JSON.parse(expand('card>input:search', JSON.stringify({
  mode: 'editor', pretty: true, xhtml: false, indent: '  ',
  snippets: [{ name: 'card', tag: 'article', attributes: [{ name: 'class', value: 'card' }] }],
})));
```

mode 为 `html`（默认）、`editor` 或 `css`。CSS 模式仅接受 mode，不接受 HTML 配置字段。snippet 含必填 name/tag，可选 attributes/text；属性对象含 name 和可选 value，省略 value 表示布尔属性。配置省略字段使用默认值，字段名区分大小写；未知字段忽略，已知字段类型错误、重复 JSON 键、无效 JSON 和超过限制的配置均报错。配置最多 65536 个 UTF-16 单元，JSON 嵌套最多 16 层，模板还受自身限制约束。

成功结果为 `{ok:true, html}`、`{ok:true, css}` 或 `{ok:true, html, tabstops}`；失败统一为 `{ok:false, error, offset}`。CLI `--json`、编辑器模式及所有错误使用相同字段；普通 HTML/CSS 成功时直接输出文本。退出码 0 表示成功，1 表示展开失败，2 表示参数错误。

## 编辑区域替换示例

执行 `npm run build` 后，在仓库根目录运行 `python -m http.server 8000`，浏览器打开 `http://localhost:8000/examples/editor.html`。输入缩写查看结果，在编辑区域选中缩写后点击展开，再通过“下一个占位”移动光标。示例不请求网络 API，不把生成文本插入页面 DOM；HTTP 服务仅用于加载本地 ESM。

`examples/editor-adapter.mjs` 导出 `expandSelection(text,start,end,options)` 与 `applyToTextarea(textarea,options)`。前者返回新文本、插入内容、绝对占位位置和新选区；后者通过 `setRangeText` 真正替换 textarea 选区。二者都在失败时保留原文；拒绝从代理对中间切开字符。`npm run demo` 在 Node 中验证同一路径，包括中文、表情、模板、格式化和错误结果。宿主负责选区识别、交互和文件保存。
