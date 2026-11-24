///|
fn Parser::name(self : Parser) -> String {
  let start = self.pos
  while self.peek() is Some(c) && (is_name(c) || c == '$') {
    self.pos += 1
  }
  String::from_array(self.chars[start:self.pos])
}

///|
fn Parser::element(
  self : Parser,
  parent : String,
) -> Result[Element, ExpansionError] {
  if self.peek() == Some('{') {
    let text = match self.read_text() {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    self.count += 1
    if self.count > 4096 {
      return Err(self.fail("节点数量超过限制"))
    }
    return Ok({
      tag: "",
      is_text: true,
      repeat_count: 1,
      attributes: [],
      text,
      children: [],
    })
  }
  let name = self.name()
  if name == "" &&
    self.peek() != Some('.') &&
    self.peek() != Some('#') &&
    self.peek() != Some('[') {
    return Err(self.fail("需要标签名"))
  }
  let (name, input_type) = match name {
    "bq" => ("blockquote", None)
    "btn" => ("button", None)
    "input:text" => ("input", Some("text"))
    "input:email" => ("input", Some("email"))
    "input:password" => ("input", Some("password"))
    "input:checkbox" => ("input", Some("checkbox"))
    "input:radio" => ("input", Some("radio"))
    "input:submit" => ("input", Some("submit"))
    _ => (name, None)
  }
  let tag = if name != "" {
    name
  } else {
    match parent {
      "ul" | "ol" => "li"
      "tr" => "td"
      "table" | "tbody" | "thead" | "tfoot" => "tr"
      "select" | "optgroup" => "option"
      _ => "div"
    }
  }
  if tag[0] >= '0' && tag[0] <= '9' {
    return Err(self.fail("标签不能以数字开头"))
  }
  let attrs = default_attributes(tag)
  if input_type is Some(kind) {
    set_attribute(attrs, "type", Some(kind))
  }
  let mut text = ""
  while true {
    match self.peek() {
      Some('.') | Some('#') => {
        let op = self.chars[self.pos]
        self.pos += 1
        let value = self.name()
        if value == "" {
          return Err(self.fail("选择器不能为空"))
        }
        if op == '.' {
          set_attribute(attrs, "class", Some(value))
        } else {
          set_attribute(attrs, "id", Some(value))
        }
      }
      Some('[') =>
        match self.read_attributes(attrs) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      Some('{') =>
        match self.read_text() {
          Ok(v) => text += v
          Err(e) => return Err(e)
        }
      _ => break
    }
  }
  self.count += 1
  if self.count > 4096 {
    return Err(self.fail("节点数量超过限制"))
  }
  Ok({
    tag,
    is_text: false,
    repeat_count: 1,
    attributes: attrs,
    text,
    children: [],
  })
}

///|
fn Parser::read_text(self : Parser) -> Result[String, ExpansionError] {
  self.pos += 1
  let out = StringBuilder()
  let mut depth = 1
  while self.peek() is Some(c) {
    self.pos += 1
    if c == '\\' {
      guard self.peek() is Some(next) else {
        return Err(self.fail("转义未结束"))
      }
      out.write_char(next)
      self.pos += 1
      continue
    }
    if c == '{' {
      depth += 1
    }
    if c == '}' {
      depth -= 1
    }
    if depth == 0 {
      return Ok(out.to_string())
    }
    out.write_char(c)
  }
  Err(self.fail("文本大括号未闭合"))
}

///|
fn Parser::read_attributes(
  self : Parser,
  attrs : Array[(String, String?)],
) -> Result[Unit, ExpansionError] {
  self.pos += 1
  while true {
    while self.peek() == Some(' ') {
      self.pos += 1
    }
    if self.peek() == Some(']') {
      self.pos += 1
      return Ok(())
    }
    let key = self.name()
    if key == "" {
      return Err(self.fail("需要属性名或右方括号"))
    }
    let mut value : String? = None
    if self.peek() == Some('=') {
      self.pos += 1
      let out = StringBuilder()
      if self.peek() is Some(quote) && (quote == '\'' || quote == '"') {
        self.pos += 1
        while self.peek() is Some(c) && c != quote {
          self.pos += 1
          if c == '\\' {
            guard self.peek() is Some(next) else {
              return Err(self.fail("转义未结束"))
            }
            out.write_char(next)
            self.pos += 1
          } else {
            out.write_char(c)
          }
        }
        if self.peek() != Some(quote) {
          return Err(self.fail("属性引号未闭合"))
        }
        self.pos += 1
      } else {
        while self.peek() is Some(c) && c != ' ' && c != ']' {
          out.write_char(c)
          self.pos += 1
        }
      }
      value = Some(out.to_string())
    }
    set_attribute(attrs, key, value)
    if self.peek() != Some(' ') && self.peek() != Some(']') {
      return Err(self.fail("属性之间需要空格"))
    }
  } nobreak {
    Ok(())
  }
}
