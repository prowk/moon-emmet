///|
/// 错误也以 JSON 写到标准输出，退出码区分用法错误和展开错误。
fn error(message : String, code : Int32, offset~ : Int32 = 0) -> Unit {
  let value : Json = { "ok": false, "error": message, "offset": offset }
  println(value.stringify())
  @env.exit(code)
}

///|
fn main {
  let args = @env.args()
  let mut input : String? = None
  let mut pretty = false
  let mut xhtml = false
  let mut css = false
  let mut editor = false
  let mut json = false
  for i in 1..<args.length() {
    match args[i] {
      "--help" | "-h" => {
        println(
          "Moon Emmet 0.1.0 MVP（未发布）\n用法: emmet [--pretty] [--xhtml] [--css | --editor] [--json] '缩写'\n示例: --css 'm10-20+c#fff'\n错误以 JSON 输出，offset 为 Unicode 字符序号；退出码: 0 成功，1 展开失败，2 参数错误。",
        )
        return
      }
      "--pretty" => pretty = true
      "--xhtml" => xhtml = true
      "--css" => css = true
      "--editor" => editor = true
      "--json" => json = true
      value => {
        if value.has_prefix("--") {
          error("未知选项: " + value, 2)
        }
        if input is Some(_) {
          error("只接受一个缩写，请用引号包裹", 2)
        }
        input = Some(value)
      }
    }
  }
  guard input is Some(source) else {
    error("缺少缩写；使用 --help 查看用法", 2)
    return
  }
  if css && (editor || pretty || xhtml) {
    error("--css 不能与 HTML 输出选项组合", 2)
  }
  if css {
    match @engine.expand_css(source) {
      Ok(value) =>
        if json {
          let result : Json = { "ok": true, "css": value }
          println(result.stringify())
        } else {
          println(value)
        }
      Err(e) => error(e.message, 1, offset=e.offset)
    }
  } else if editor {
    match
      @engine.expand_for_editor(
        source,
        options=@engine.Options::new(pretty~, xhtml~),
      ) {
      Ok(value) => {
        let result : Json = {
          "ok": true,
          "html": value.html,
          "tabstops": value.tabstops,
        }
        println(result.stringify())
      }
      Err(e) => error(e.message, 1, offset=e.offset)
    }
  } else {
    match
      @engine.expand_with_options(source, @engine.Options::new(pretty~, xhtml~)) {
      Ok(value) =>
        if json {
          let result : Json = { "ok": true, "html": value }
          println(result.stringify())
        } else {
          println(value)
        }
      Err(e) => error(e.message, 1, offset=e.offset)
    }
  }
}
