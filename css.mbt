///|
/// 初版只处理明确列出的 CSS 缩写，未知属性直接报错。
pub fn expand_css(input : String) -> Result[String, ExpansionError] {
  if input.length() == 0 || input.length() > 8192 {
    return Err({ offset: 0, message: "CSS 输入长度应为 1 到 8192", })
  }
  let result : Array[String] = []
  for token in input.split("+") {
    let token = token.to_owned()
    let fixed = match token {
      "d:f" => Some("display: flex;")
      "d:n" => Some("display: none;")
      "d:b" => Some("display: block;")
      "d:g" => Some("display: grid;")
      "pos:a" => Some("position: absolute;")
      "pos:r" => Some("position: relative;")
      "m:a" => Some("margin: auto;")
      _ => None
    }
    if fixed is Some(value) {
      result.push(value)
      continue
    }
    let chars = token.to_array()
    let mut pos = 0
    while pos < chars.length() && chars[pos] >= 'a' && chars[pos] <= 'z' {
      pos += 1
    }
    let key = String::from_array(chars[:pos])
    let property = match key {
      "m" => "margin"
      "mt" => "margin-top"
      "mr" => "margin-right"
      "mb" => "margin-bottom"
      "ml" => "margin-left"
      "p" => "padding"
      "pt" => "padding-top"
      "pr" => "padding-right"
      "pb" => "padding-bottom"
      "pl" => "padding-left"
      "w" => "width"
      "h" => "height"
      "fz" => "font-size"
      "lh" => "line-height"
      "op" => "opacity"
      "z" => "z-index"
      _ =>
        return Err({
          offset: 0,
          message: "不支持的 CSS 属性缩写: " + key,
        })
    }
    let start = pos
    if pos < chars.length() && chars[pos] == '-' {
      pos += 1
    }
    while pos < chars.length() &&
          ((chars[pos] >= '0' && chars[pos] <= '9') || chars[pos] == '.') {
      pos += 1
    }
    let number = String::from_array(chars[start:pos])
    let value = @string.parse_double(number[:]) catch {
      _ => return Err({ offset: start, message: "CSS 数值无效", })
    }
    if !value.is_finite() {
      return Err({ offset: start, message: "CSS 数值必须有限", })
    }
    let suffix = String::from_array(chars[pos:])
    let unit = if suffix == "" {
      if key == "op" || key == "z" || key == "lh" || value == 0.0 {
        ""
      } else {
        "px"
      }
    } else {
      match suffix {
        "p" | "%" => "%"
        "e" | "em" => "em"
        "r" | "rem" => "rem"
        "px" | "vh" | "vw" => suffix
        _ => return Err({ offset: pos, message: "不支持的 CSS 单位", })
      }
    }
    result.push(property + ": " + number + unit + ";")
  }
  Ok(result.join("\n"))
}
