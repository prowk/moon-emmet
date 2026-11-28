# v0.1.0 MVP 兼容范围

本文描述计划首次发布的 v0.1.0 MVP 范围，当前仍为未正式发布的开发源码。本库是独立编写的 Emmet 风格子集，不是完整 Emmet 的逐行移植或兼容认证。
参考 https://github.com/emmetio/emmet 和 https://docs.emmet.io/abbreviations/syntax/ 。

| 能力 | 当前范围 |
| --- | --- |
| HTML 结构 | 标签、`>`、`+`、`^`、嵌套分组 |
| 元素内容 | `#id`、`.class`、引号/无引号属性、布尔属性、`{文本}`、独立文本节点与混合内容 |
| 重复 | `*N`（1–1000），子树重复、分组重复、`$` 和 `$$` 补零编号、`$@N` 基数和 `$@-N` 反向编号 |
| 隐式标签 | 默认 div；ul/ol 下 li，table/tbody/thead/tfoot 下 tr，tr 下 td，select/optgroup 下 option |
| 输出 | 紧凑/格式化 HTML、XHTML 风格空元素、文本与属性值转义 |
| 模板 | 常用内置元素模板；自定义单元素标签、属性、文本；后定义覆盖内置项，显式属性最后生效 |
| 编辑器 | 空字符串属性值、空叶元素的光标位置，按最终 HTML 的 UTF-16 单元计数 |
| CSS 数值 | m/mt/mr/mb/ml、p/pt/pr/pb/pl、w/h/fz/lh/op/z |
| CSS 单位 | px、em/e、rem/r、%/p、vh、vw；长度默认 px，零和 lh/op/z 默认无单位 |
| CSS 多值 | margin/padding 一至四值，连字符或显式单位分隔，负号规则见 [CSS 文档](css.md) |
| CSS 颜色 | c/bgc/bdc，1/2 位简写和 3/4/6/8 位十六进制 |
| CSS 固定项 | d:f/n/b/g/i/ib、pos:a/r/s/f/st、m:a；用 `+` 组合声明 |

暂不支持：Lorem、完整 snippet 表、CSS 模糊匹配、JSX、BEM、将现有文本包裹在缩写内、在分组后直接使用 `>`。编辑器示例提供将选中的缩写替换为展开文本，不是上游 Wrap with Abbreviation 操作。
标签名和选择器名当前仅接受 ASCII 字母数字、连字符、冒号、下划线及编号符；输入不自动裁剪空白。
显式 `*1` 也建立独立编号上下文；未显式重复的子节点继承最近的重复上下文。编号基数范围为 0–1000000。`parse` 保留紧凑树与 repeat_count，渲染阶段才展开。
分组以空 tag 的容器表示；独立文本节点同时带 is_text=true。格式化模式不会向混合内容插入额外空白。属性按 HTML 名称忽略大小写去重，后来的值覆盖旧值；class 按输入顺序合并去重。

与上游的刻意边界：文本与属性值转义后输出，不提供原始 HTML 插值。a/img/input/form 带常用默认属性，显式值优先；本库仅补少量默认属性，例如 input 不自动添加 name/id。布尔属性输出为裸属性，XHTML 选项仅改变空元素闭合风格。内置和自定义模板见 [snippets](snippets.md)。
CSS 的 z-index 只接受无单位整数，opacity 只接受无单位数值或百分比；padding/width/height/font-size/line-height 拒绝负值。
此库不负责 HTML 内容安全策略；调用者自行决定允许的标签和属性。

输入最多 8192 个 Unicode 字符，嵌套最多 64 层，展开树最多 4096 个节点（分组也计数），输出最多 262144 个 UTF-16 单元。
语法错误 offset 是从零开始的 Unicode 字符序号（CSS 为完整组合输入中的位置）；配置、编号、渲染及预算错误 offset=0，表示整个表达式。
编辑器 tabstops 是 UTF-16 单元索引，不能直接当作语法 offset 使用。

## 验证与对照

`npm ci --ignore-scripts && npm run check` 运行 14 个关键回归测试（Wasm-GC 和 JS 各一次）、Node CLI 输出与退出码、ESM 配置、实际文档选区替换及 Unicode 光标检查。另通过 `npm run check:package` 从真实发布 ZIP 创建独立工作区，在两个后端以公开 API 消费本库并构建 ESM 桥接。

`scripts/compare-upstream.mjs` 调用锁定的 npm 开发依赖 Emmet 2.4.11，实时比较 10 个 HTML 和 6 个 CSS 用例，覆盖层级、分组、编号、混合内容、显式默认属性、Unicode、多值和颜色。HTML 关闭格式化并将上游编辑器占位替换为默认文本；CSS 将上游浮点默认单位设为 px，与本库规则一致，仅忽略声明之间的换行。属性、结构、值、单位及顺序必须一致。

明确保留的差异另作断言：本库转义文本、使用裸布尔属性，并拒绝未知 CSS；十六进制颜色除 1/2 位简写外保留输入长度，不自动压缩。未运行完整上游测试，不宣称全量兼容或完整的浏览器 CSS 校验。上游代码与数据不随运行时库导入，自定义模板不支持递归展开或原始 HTML。
