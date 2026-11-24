///|
fn render_nodes(nodes : Array[Element], out : StringBuilder) -> Unit {
  for node in nodes {
    out.write_string("<" + node.tag)
    for (key, value) in node.attributes {
      out.write_string(" " + key)
      if value is Some(v) {
        out.write_string("=\"" + escape_html(v) + "\"")
      }
    }
    out.write_string(">")
    out.write_string(escape_html(node.text))
    render_nodes(node.children, out)
    out.write_string("</" + node.tag + ">")
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
  let out = StringBuilder()
  render_nodes(nodes, out)
  Ok(out.to_string())
}
