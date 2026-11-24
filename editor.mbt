///|
/// 光标位置对应最终 HTML 字符串的 UTF-16 单元索引，适合 JS 编辑器。
pub(all) struct Expansion {
  html : String
  tabstops : Array[Int32]
}

///|
pub fn expand_for_editor(
  input : String,
  options? : Options,
) -> Result[Expansion, ExpansionError] {
  render_expansion(input, options.unwrap_or(Options::new()), true)
}
