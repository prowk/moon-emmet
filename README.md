# Moon Emmet

MoonBit 原生的 Emmet 风格 HTML/CSS 缩写引擎。当前为面向首次发布 `v0.1.0` 的 MVP 开发版本，尚未正式发布，核心只依赖 MoonBit 标准库。
面向编辑器、在线 IDE、网页开发工具提供可复用库、CLI 和 ESM 导出。

```powershell
moon run cmd/emmet -- --pretty 'nav>ul>li.item$*3>a{链接$}'
moon run cmd/emmet -- --css 'm10-20+p8+c#fff+d:f'
moon run cmd/emmet -- --editor 'a[href=""]'
```

第一条输出：

```html
<nav>
  <ul>
    <li class="item1">
      <a href="">链接1</a>
    </li>
    <li class="item2">
      <a href="">链接2</a>
    </li>
    <li class="item3">
      <a href="">链接3</a>
    </li>
  </ul>
</nav>
```

## 库接口

消费者在 `moon.mod` 声明依赖，在 `moon.pkg` 导入 `"prowk/moon-emmet" @engine` 后调用；本地源码接入可使用包含两个模块的 `moon.work`，见[发布与验证](docs/releasing.md)。

```moonbit
match @engine.expand("ul>li.item$*3") {
  Ok(html) => println(html)
  Err(error) => println(error.message)
}
```

- `parse(input, snippets~)`：返回紧凑 Element 树和重复信息。
- `expand(input)`：返回紧凑 HTML。
- `expand_with_options(input, Options::new(pretty=true, xhtml=false))`：配置缩进和空元素输出。
- `expand_for_editor(input)`：返回 HTML 和 UTF-16 光标位置。
- `expand_css(input)`：返回 CSS 声明。

支持纯文本节点与混合内容，例如 `p>{点击 }+a[href=/docs]{文档}+{ 继续}`；
常用 a/img/input/form 自动补默认属性，显式值可覆盖；class 自动合并去重。
`li.item$$@-3*2` 生成 item04、item03，独立的 `*1` 也会重置内部编号。
内置表单、样式表等常用元素模板，也支持通过 `Snippet::new` 和 `Options::new(snippets~)` 扩展或覆盖，见[元素模板](docs/snippets.md)。
CSS 支持 margin/padding 一至四值、常用单位、负值和小数，以及 color/background-color/border-color 的十六进制颜色，见 [CSS 规则](docs/css.md)。

CLI 支持 `--pretty`、`--xhtml`、`--css`、`--editor`、`--json` 和 `--help`。
必须将缩写作为一个参数传入，PowerShell 推荐单引号，避免 `$` 被 shell 解释。
成功退出码 0，展开失败 1，参数错误 2。JSON 成功结果含 `ok:true` 和 html/css；编辑器结果还含 tabstops。错误统一为 `{ok:false,error,offset}`，写到标准输出。Node CLI 和 Wasm-GC CLI 使用同一协议。

## JavaScript 编辑器接入

需要 MoonBit 工具链和 Node.js 22+，没有 npm 运行时依赖：

```powershell
npm run demo
npm run serve
```

构建产物 `_build/js/release/build/bridge/bridge.js` 为 ESM，导出 `html`、`css`、`editor` 和可配置的 `expand(source, configJson)`。
参数和返回值都是字符串，返回值是 JSON；`ok=false` 时读取 `error` 和 `offset`。
调用示例见 `examples/editor.mjs`。`npm run serve` 启动本地示例，打开 `http://127.0.0.1:8000/examples/editor.html`，可输入缩写、查看结果、选区替换并跳转光标。完整配置、错误和位置约定见 [API 文档](docs/api.md)。

## 开发检查

本地验证环境：moon `0.1.20261104`、moonc `v0.10.20+65efd5b93`、Node `22.14.0`。

```powershell
npm ci --ignore-scripts
npm run check
npm run check:package
moon info
```

14 个关键测试在 Wasm-GC/JS 后端验证结构、错误位置、属性文本、分组、预算、格式化、Unicode 光标、模板和 CSS；另有 CLI/ESM 集成验证及与 Emmet 2.4.11 的 16 个范围内对照。Emmet 仅为锁定的开发依赖，不参与运行时展开。CI 在 push/PR 时运行同一检查与独立消费者的发布包验证。

## 兼容范围

支持范围、资源限制、对照配置及差异见[兼容说明](docs/compatibility.md)。本库实现常用 Emmet 子集，不提供完整上游 snippets、完整 CSS 解析或完整 IDE。

## 来源与许可证

项目采用 [MIT 许可证](LICENSE)，语法参考 [Emmet](https://github.com/emmetio/emmet) 和 [Emmet 文档](https://docs.emmet.io/)。
