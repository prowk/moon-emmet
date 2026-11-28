///|
/// 仅处理明确列出的 CSS 缩写，错误位置是完整输入的 Unicode 字符序号。
pub fn expand_css(input : String) -> Result[String, ExpansionError] {
  if input.to_array().length() == 0 || input.to_array().length() > 8192 {
    return Err({
      offset: 0,
      message: "CSS 输入长度应为 1 到 8192 个字符",
    })
  }
  let result : Array[String] = []
  let mut offset = 0
  for part in input.split("+") {
    let token = part.to_owned()
    match css_declaration(token, offset) {
      Ok(value) => result.push(value)
      Err(e) => return Err(e)
    }
    offset += token.to_array().length() + 1
  }
  Ok(result.join("\n"))
}

///|
fn css_declaration(
  token : String,
  offset : Int32,
) -> Result[String, ExpansionError] {
  let fixed = match token {
    "d:f" => Some("display: flex;")
    "d:n" => Some("display: none;")
    "d:b" => Some("display: block;")
    "d:g" => Some("display: grid;")
    "d:i" => Some("display: inline;")
    "d:ib" => Some("display: inline-block;")
    "pos:a" => Some("position: absolute;")
    "pos:r" => Some("position: relative;")
    "pos:s" => Some("position: static;")
    "pos:f" => Some("position: fixed;")
    "pos:st" => Some("position: sticky;")
    "m:a" => Some("margin: auto;")
    _ => None
  }
  if fixed is Some(value) {
    return Ok(value)
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
    "c" => "color"
    "bgc" => "background-color"
    "bdc" => "border-color"
    _ =>
      return Err({ offset, message: "不支持的 CSS 属性缩写: " + key, })
  }
  if key == "c" || key == "bgc" || key == "bdc" {
    if pos >= chars.length() || chars[pos] != '#' {
      return Err({
        offset: offset + pos,
        message: "颜色值需要 # 和十六进制数字",
      })
    }
    let start = pos + 1
    pos = start
    while pos < chars.length() {
      let c = chars[pos]
      if !((c >= '0' && c <= '9') ||
        (c >= 'a' && c <= 'f') ||
        (c >= 'A' && c <= 'F')) {
        return Err({
          offset: offset + pos,
          message: "无效的十六进制颜色",
        })
      }
      pos += 1
    }
    let hex = String::from_array(chars[start:pos]).to_lower()
    let color = match hex.length() {
      1 => hex + hex + hex
      2 => hex + hex + hex
      3 | 4 | 6 | 8 => hex
      _ =>
        return Err({
          offset: offset + start,
          message: "颜色应为 1、2、3、4、6 或 8 位十六进制数字",
        })
    }
    return Ok(property + ": #" + color + ";")
  }
  let values : Array[String] = []
  while true {
    let (value, end) = match css_number(chars, pos, key, offset) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    values.push(value)
    pos = end
    if pos == chars.length() {
      break
    }
    if key != "m" && key != "p" {
      return Err({
        offset: offset + pos,
        message: "仅 margin/padding 支持用 - 分隔多值",
      })
    }
    if values.length() >= 4 {
      return Err({
        offset: offset + pos,
        message: "margin/padding 最多接受四个值",
      })
    }
    let previous = chars[pos - 1]
    let explicit_unit = (previous >= 'a' && previous <= 'z') || previous == '%'
    if explicit_unit {
      // 显式单位已经分隔数值，后续 - 是负号，与 Emmet 的输入方式一致。
      if chars[pos] != '-' &&
        chars[pos] != '.' &&
        !(chars[pos] >= '0' && chars[pos] <= '9') {
        return Err({ offset: offset + pos, message: "CSS 多值分隔无效", })
      }
    } else if chars[pos] == '-' {
      pos += 1
    } else {
      return Err({
        offset: offset + pos,
        message: "CSS 多值需要 - 或显式单位分隔",
      })
    }
  }
  Ok(property + ": " + values.join(" ") + ";")
}

///|
fn css_number(
  chars : Array[Char],
  start : Int32,
  key : String,
  offset : Int32,
) -> Result[(String, Int32), ExpansionError] {
  let mut pos = start
  if pos < chars.length() && chars[pos] == '-' {
    pos += 1
  }
  let mut digits = 0
  let mut dots = 0
  while pos < chars.length() &&
        ((chars[pos] >= '0' && chars[pos] <= '9') || chars[pos] == '.') {
    if chars[pos] == '.' {
      dots += 1
    } else {
      digits += 1
    }
    pos += 1
  }
  if digits == 0 || dots > 1 || (pos > start && chars[pos - 1] == '.') {
    return Err({ offset: offset + start, message: "CSS 数值无效", })
  }
  let number = String::from_array(chars[start:pos])
  let value = @string.parse_double(number[:]) catch {
    _ => return Err({ offset: offset + start, message: "CSS 数值无效", })
  }
  if !value.is_finite() {
    return Err({ offset: offset + start, message: "CSS 数值必须有限", })
  }
  let unit_start = pos
  while pos < chars.length() &&
        ((chars[pos] >= 'a' && chars[pos] <= 'z') || chars[pos] == '%') {
    pos += 1
  }
  let suffix = String::from_array(chars[unit_start:pos])
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
      _ =>
        return Err({
          offset: offset + unit_start,
          message: "不支持的 CSS 单位",
        })
    }
  }
  if key == "z" && (unit != "" || number.contains(".")) {
    return Err({
      offset: offset + start,
      message: "z-index 只接受无单位整数",
    })
  }
  if key == "op" && unit != "" && unit != "%" {
    return Err({
      offset: offset + unit_start,
      message: "opacity 只接受无单位数值或百分比",
    })
  }
  if (
      key.has_prefix("p") ||
      key == "w" ||
      key == "h" ||
      key == "fz" ||
      key == "lh"
    ) &&
    value < 0.0 {
    return Err({
      offset: offset + start,
      message: "该 CSS 属性不接受负值",
    })
  }
  Ok((number + unit, pos))
}
