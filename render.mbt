///|
fn render_nodes(nodes : Array[Element], out : StringBuilder) -> Unit {
  for node in nodes {
    out.write_string("<" + node.tag + ">")
    render_nodes(node.children, out)
    out.write_string("</" + node.tag + ">")
  }
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
