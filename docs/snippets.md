# 元素模板

`Snippet` 是单元素模板，支持标签、默认属性及文本。它与普通元素一样支持选择器、重复、编号和 `>` 子节点，不执行原始 HTML，也不递归调用其他模板。

```moonbit
let snippets = [
  @engine.Snippet::new("card", "article", attributes=[("class", Some("card"))]),
]
let options = @engine.Options::new(snippets~)
let result = @engine.expand_with_options("card.active>h2{标题}", options)
```

同一份 `Options` 也可传入 `expand_for_editor`；`parse(input, snippets~)` 返回应用模板后的紧凑树。

优先级为元素默认属性、模板属性、输入中显式属性。普通同名属性后值覆盖前值；class 按输入顺序合并去重。自定义模板覆盖同名内置模板，同名自定义项取数组最后一项；名称大小写敏感。模板文本先于输入文本输出，文本和属性值均转义，值中的 `$` 使用正常编号规则。

内置项：`bq`、`btn`、`btn:s`、`btn:r`、`input:text/email/password/checkbox/radio/submit/number/search/date/hidden`、`link:css`、`script:src`、`form:get`、`form:post`、`meta:vp`。斜线写法仅用于列举，每个输入使用一个完整名称，例如 `input:email`。`link:css` 的 href 和 `script:src` 的 src 默认为空，`meta:vp` 默认内容为 `width=device-width, initial-scale=1.0`。

自定义项最多 128 个，每项最多 64 个属性，总配置最多 8192 个 UTF-16 单元。名称、标签和属性名限定 ASCII 字母数字、连字符、冒号和下划线；标签不能以数字开头。无效配置返回 `offset=0`，不会修改输入位置或无限递归。模板内容仍受节点、输出和 HTML 空元素限制约束。
