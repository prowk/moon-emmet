# 0.1 兼容范围

本版本是独立编写的 Emmet 风格子集，不是完整 Emmet 的逐行移植或兼容认证。
参考 https://github.com/emmetio/emmet 和 https://docs.emmet.io/abbreviations/syntax/ 。

| 能力 | 当前范围 |
| --- | --- |
| HTML 结构 | 标签、`>`、`+`、`^`、嵌套分组 |
| 元素内容 | `#id`、`.class`、引号/无引号属性、布尔属性、`{文本}` |
| 重复 | `*N`（1–1000），子树重复、分组重复、`$` 和 `$$` 补零编号 |
| 隐式标签 | 默认 div；ul/ol 下 li，table/tbody 下 tr，tr 下 td，select 下 option |
| 输出 | 紧凑/格式化 HTML、XHTML 风格空元素、文本与属性值转义 |
| 编辑器 | 空字符串属性值、空叶元素的光标位置，按最终 HTML 的 UTF-16 单元计数 |
| CSS 数值 | m/mt/mr/mb/ml、p/pt/pr/pb/pl、w/h/fz/lh/op/z |
| CSS 单位 | px、em/e、rem/r、%/p、vh、vw；长度默认 px，零和 lh/op/z 默认无单位 |
| CSS 固定项 | d:f/d:n/d:b/d:g、pos:a/pos:r、m:a；用 `+` 组合声明 |

暂不支持：Lorem、完整 snippet 表、CSS 模糊匹配/多值简写、编号基数和反向编号、JSX、BEM、包裹选区、独立文本节点（如 `p>{text}`）、在分组后直接使用 `>`。
标签名和选择器名当前仅接受 ASCII 字母数字、连字符、冒号、下划线及编号符；输入不自动裁剪空白。
重复节点 `*1` 沿用外层编号。`parse` 保留紧凑树与 repeat_count，渲染阶段才展开。
分组以空 tag 的容器表示。显式属性与 shorthand 不做去重；调用者应避免重复 id/class 声明。

与上游的刻意边界：文本与属性值转义后输出，不提供原始 HTML 插值；未自动给 a/img 补默认属性。
此库不负责 HTML 内容安全策略；调用者自行决定允许的标签和属性。

输入最多 8192 个 Unicode 字符，嵌套最多 64 层，展开树最多 4096 个节点（分组也计数），输出最多 262144 个 UTF-16 单元。
语法错误 offset 是从零开始的 Unicode 字符序号；渲染/预算错误 offset=0，表示整个表达式。
编辑器 tabstops 是 UTF-16 单元索引，不能直接当作语法 offset 使用。

验证采用 8 个关键回归测试和 CLI/ESM 实跑。尚未执行完整上游测试或差分验证，不宣称全量行为一致。
