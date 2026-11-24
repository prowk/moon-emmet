# Moon Emmet

MoonBit 原生的 Emmet 风格 HTML/CSS 缩写引擎。初步版本 `0.1.0`，核心只依赖 MoonBit 标准库。
面向编辑器、在线 IDE、网页开发工具提供可复用库、CLI 和 ESM 导出。

```powershell
moon run cmd/emmet -- --pretty 'nav>ul>li.item$*3>a{链接$}'
moon run cmd/emmet -- --css 'm10+w50p+d:f'
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

本地消费者在 `moon.pkg` 导入 `"prowk/moon-emmet" @engine` 后调用：

```moonbit
match @engine.expand("ul>li.item$*3") {
  Ok(html) => println(html)
  Err(error) => println(error.message)
}
```

- `parse(input)`：返回紧凑 Element 树和重复信息。
- `expand(input)`：返回紧凑 HTML。
- `expand_with_options(input, Options::new(pretty=true, xhtml=false))`：配置缩进和空元素输出。
- `expand_for_editor(input)`：返回 HTML 和 UTF-16 光标位置。
- `expand_css(input)`：返回 CSS 声明。

CLI 支持 `--pretty`、`--xhtml`、`--css`、`--editor`、`--json` 和 `--help`。
必须将缩写作为一个参数传入，PowerShell 推荐单引号，避免 `$` 被 shell 解释。
成功退出码 0，展开失败 1，参数错误 2。错误以 JSON 写到标准输出。

## JavaScript 编辑器接入

需要 MoonBit 工具链和 Node.js 22+，没有 npm 运行时依赖：

```powershell
npm run demo
```

构建产物 `_build/js/release/build/bridge/bridge.js` 为 ESM，导出 `html`、`css`、`editor`。
参数和返回值都是字符串，返回值是 JSON；`ok=false` 时读取 `error` 和 `offset`。
调用示例见 `examples/editor.mjs`。浏览器也可导入同一 ESM，自行提供编辑器界面。

## 开发检查

本地验证环境：moon `0.1.20261104`、moonc `v0.10.20+65efd5b93`、Node `22.14.0`。

```powershell
node scripts/check.mjs
moon info
```

11 个关键测试覆盖结构、错误位置、属性文本、分组、重复预算、格式化、Unicode 光标和 CSS。
检查脚本执行 Wasm-GC/JS 测试、JS 构建与示例，CI 在 push/PR 时运行同一入口。

## 边界与下一步

这是明确限定范围的初步版本。支持范围、资源限制和差异见 `docs/compatibility.md`。
下一步优先加入更多 snippets 和 CSS 属性，再根据实际用例增加少量上游对照。
不会在当前版本声称完整兼容 Emmet、自动生成有效的任意 CSS 或具备完整 IDE 功能。

## 来源与许可证

项目采用 [MIT 许可证](LICENSE)，语法参考 [Emmet](https://github.com/emmetio/emmet) 和 [Emmet 文档](https://docs.emmet.io/)。
