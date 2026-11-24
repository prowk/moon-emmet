///|
fn render_nodes(
  nodes : Array[Element],
  out : StringBuilder,
  index : Int32,
) -> Unit {
  for node in nodes {
    for iteration in 1..<=node.repeat_count {
      let index = if node.repeat_count > 1 { iteration } else { index }
      if node.tag == "" {
        render_nodes(node.children, out, index)
        continue
      }
      out.write_string("<" + node.tag)
      for (key, value) in node.attributes {
        out.write_string(" " + key)
        if value is Some(v) {
          out.write_string("=\"" + escape_html(numbered(v, index)) + "\"")
        }
      }
      out.write_string(">")
      out.write_string(escape_html(numbered(node.text, index)))
      render_nodes(node.children, out, index)
      out.write_string("</" + numbered(node.tag, index) + ">")
    }
  }
}

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
pub fn expand(input : String) -> Result[String, ExpansionError] {
  let nodes = match parse(input) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if expanded_size(nodes, 4096) > 4096 {
    return Err({ offset: 0, message: "展开超过 4096 个节点", })
  }
  let out = StringBuilder()
  render_nodes(nodes, out, 1)
  Ok(out.to_string())
}
