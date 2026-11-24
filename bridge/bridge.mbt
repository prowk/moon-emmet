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
