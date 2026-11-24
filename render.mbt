///|
fn escape_html(value : String) -> String {
  let out = StringBuilder()
  for c in value {
    match c {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' => out.write_string("&quot;")
      _ => out.write_char(c)
    }
  }
  out.to_string()
}

///|
priv struct Renderer {
  out : StringBuilder
  options : Options
  mut length : Int32
  mut overflow : Bool
}

///|
fn Renderer::write(self : Renderer, text : String) -> Unit {
  if text.length() > 262144 - self.length {
    self.overflow = true
    return
  }
  self.out.write_string(text)
  self.length += text.length()
}

///|
fn Renderer::line(self : Renderer, depth : Int32) -> Unit {
  if self.options.pretty {
    if self.length > 0 {
      self.write("\n")
    }
    for _ in 0..<depth {
      self.write(self.options.indent)
    }
  }
}

///|
fn Renderer::nodes(
  self : Renderer,
  nodes : Array[Element],
  depth : Int32,
  index : Int32,
) -> Result[Unit, ExpansionError] {
  for node in nodes {
    for iteration in 1..<=node.repeat_count {
      let index = if node.repeat_count > 1 { iteration } else { index }
      if node.tag == "" {
        match self.nodes(node.children, depth, index) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        continue
      }
      let tag = numbered(node.tag, index)
      if is_void(tag) && (node.text != "" || node.children.length() > 0) {
        return Err({
          offset: 0,
          message: "空元素不能包含文本或子节点",
        })
      }
      self.line(depth)
      self.write("<" + tag)
      for (key, value) in node.attributes {
        self.write(" " + key)
        if value is Some(v) {
          self.write("=\"" + escape_html(numbered(v, index)) + "\"")
        }
      }
      if is_void(tag) {
        self.write(if self.options.xhtml { " />" } else { ">" })
        continue
      }
      self.write(">")
      self.write(escape_html(numbered(node.text, index)))
      match self.nodes(node.children, depth + 1, index) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      if node.children.length() > 0 {
        self.line(depth)
      }
      self.write("</" + tag + ">")
      if self.overflow {
        return Err({
          offset: 0,
          message: "输出超过 262144 个 UTF-16 单元",
        })
      }
    }
  }
  Ok(())
}

///|
pub fn expand_with_options(
  input : String,
  options : Options,
) -> Result[String, ExpansionError] {
  if options.indent.length() > 8 ||
    options.indent.to_array().any(c => c != ' ' && c != '\t') {
    return Err({
      offset: 0,
      message: "缩进只能是最多 8 个空格或制表符",
    })
  }
  let nodes = match parse(input) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if expanded_size(nodes, 4096) > 4096 {
    return Err({ offset: 0, message: "展开超过 4096 个节点", })
  }
  let renderer = Renderer::{
    out: StringBuilder(),
    options,
    length: 0,
    overflow: false,
  }
  match renderer.nodes(nodes, 0, 1) {
    Err(e) => Err(e)
    Ok(_) =>
      if renderer.overflow {
        Err({ offset: 0, message: "输出超过 262144 个 UTF-16 单元", })
      } else {
        Ok(renderer.out.to_string())
      }
  }
}

///|
pub fn expand(input : String) -> Result[String, ExpansionError] {
  expand_with_options(input, Options::new())
}
