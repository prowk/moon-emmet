///|
/// 以 JSON 字符串跨越 JS 边界，不向宿主泄漏 MoonBit 内部枚举表示。
pub fn html(source : String) -> String {
  let value : Json = match @engine.expand(source) {
    Ok(html) => { "ok": true, "html": html }
    Err(e) => { "ok": false, "error": e.message, "offset": e.offset }
  }
  value.stringify()
}

///|
pub fn css(source : String) -> String {
  let value : Json = match @engine.expand_css(source) {
    Ok(css) => { "ok": true, "css": css }
    Err(e) => { "ok": false, "error": e.message, "offset": e.offset }
  }
  value.stringify()
}

///|
pub fn editor(source : String) -> String {
  let value : Json = match @engine.expand_for_editor(source) {
    Ok(v) => { "ok": true, "html": v.html, "tabstops": v.tabstops }
    Err(e) => { "ok": false, "error": e.message, "offset": e.offset }
  }
  value.stringify()
}

///|
#derive(@json.FromJson)
priv struct BridgeAttribute {
  name : String
  value : String?
}

///|
#derive(@json.FromJson)
priv struct BridgeSnippet {
  name : String
  tag : String
  attributes : Array[BridgeAttribute]?
  text : String?
}

///|
#derive(@json.FromJson)
priv struct BridgeConfig {
  mode : String?
  pretty : Bool?
  xhtml : Bool?
  indent : String?
  snippets : Array[BridgeSnippet]?
}

///|
fn invalid_config(message : String) -> String {
  let value : Json = { "ok": false, "error": message, "offset": 0 }
  value.stringify()
}

///|
/// 可配置宿主入口，配置与结果均使用 JSON，保留三个简单入口的兼容性。
pub fn expand(source : String, config : String) -> String {
  if config.length() > 65536 {
    return invalid_config("配置超过 65536 个 UTF-16 单元")
  }
  let json = @json.parse(
    config[:],
    max_nesting_depth=16,
    reject_duplicate_keys=true,
  ) catch {
    _ => return invalid_config("配置不是有效 JSON 对象")
  }
  let config : BridgeConfig = @json.from_json(json) catch {
    _ => return invalid_config("配置字段类型无效")
  }
  let mode = config.mode.unwrap_or("html")
  if mode == "css" {
    if config.pretty != None ||
      config.xhtml != None ||
      config.indent != None ||
      config.snippets is Some(_) {
      return invalid_config("CSS 模式不接受 HTML 输出配置")
    }
    return css(source)
  }
  if mode != "html" && mode != "editor" {
    return invalid_config("mode 应为 html、css 或 editor")
  }
  let snippets = config.snippets
    .unwrap_or([])
    .map(s => {
      @engine.Snippet::new(
        s.name,
        s.tag,
        attributes=s.attributes.unwrap_or([]).map(a => (a.name, a.value)),
        text=s.text.unwrap_or(""),
      )
    })
  let options = @engine.Options::new(
    pretty=config.pretty.unwrap_or(false),
    xhtml=config.xhtml.unwrap_or(false),
    indent=config.indent.unwrap_or("  "),
    snippets~,
  )
  let value : Json = if mode == "editor" {
    match @engine.expand_for_editor(source, options~) {
      Ok(v) => { "ok": true, "html": v.html, "tabstops": v.tabstops }
      Err(e) => { "ok": false, "error": e.message, "offset": e.offset }
    }
  } else {
    match @engine.expand_with_options(source, options) {
      Ok(html) => { "ok": true, "html": html }
      Err(e) => { "ok": false, "error": e.message, "offset": e.offset }
    }
  }
  value.stringify()
}
