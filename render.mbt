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
  collect_stops : Bool
  stops : Array[Int32]
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
  total : Int32,
  inline : Bool,
) -> Result[Unit, ExpansionError] {
  for node in nodes {
    for iteration in 1..<=node.repeat_count {
      let (index, total) = if node.explicit_repeat {
        (iteration, node.repeat_count)
      } else {
        (index, total)
      }
      if node.is_text {
        if self.collect_stops && node.text == "" {
          self.stops.push(self.length)
        }
        let text = match numbered(node.text, index, total) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        self.write(escape_html(text))
        continue
      }
      if node.tag == "" {
        match self.nodes(node.children, depth, index, total, inline) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        continue
      }
      let tag = match numbered(node.tag, index, total) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if is_void(tag) && (node.text != "" || node.children.length() > 0) {
        return Err({
          offset: 0,
          message: "空元素不能包含文本或子节点",
        })
      }
      if !inline {
        self.line(depth)
      }
      self.write("<" + tag)
      for (key, value) in node.attributes {
        let key = match numbered(key, index, total) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        self.write(" " + key)
        if value is Some(v) {
          self.write("=\"")
          if self.collect_stops && v == "" {
            self.stops.push(self.length)
          }
          let value = match numbered(v, index, total) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          self.write(escape_html(value) + "\"")
        }
      }
      if is_void(tag) {
        self.write(if self.options.xhtml { " />" } else { ">" })
        continue
      }
      self.write(">")
      if self.collect_stops && node.text == "" && node.children.length() == 0 {
        self.stops.push(self.length)
      }
      let text = match numbered(node.text, index, total) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      self.write(escape_html(text))
      let child_inline = inline || node.text != "" || has_text(node.children)
      match self.nodes(node.children, depth + 1, index, total, child_inline) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      if node.children.length() > 0 && !child_inline {
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
fn render_expansion(
  input : String,
  options : Options,
  collect_stops : Bool,
) -> Result[Expansion, ExpansionError] {
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
    collect_stops,
    stops: [],
  }
  match renderer.nodes(nodes, 0, 1, 1, false) {
    Err(e) => Err(e)
    Ok(_) =>
      if renderer.overflow {
        Err({ offset: 0, message: "输出超过 262144 个 UTF-16 单元", })
      } else {
        Ok({ html: renderer.out.to_string(), tabstops: renderer.stops, })
      }
  }
}

///|
pub fn expand(input : String) -> Result[String, ExpansionError] {
  expand_with_options(input, Options::new())
}

///|
pub fn expand_with_options(
  input : String,
  options : Options,
) -> Result[String, ExpansionError] {
  match render_expansion(input, options, false) {
    Ok(v) => Ok(v.html)
    Err(e) => Err(e)
  }
}

///|
/// 混合内容不能插入格式化空白，否则会改变段落的文本内容。
fn has_text(nodes : Array[Element]) -> Bool {
  nodes.any(node => node.is_text || (node.tag == "" && has_text(node.children)))
}
