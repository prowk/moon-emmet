///|
pub struct Options {
  pretty : Bool
  indent : String
  xhtml : Bool
  snippets : Array[Snippet]
}

///|
pub fn Options::new(
  pretty~ : Bool = false,
  indent~ : String = "  ",
  xhtml~ : Bool = false,
  snippets~ : Array[Snippet] = [],
) -> Options {
  { pretty, indent, xhtml, snippets: snippets.copy(), }
}

///|
fn is_void(tag : String) -> Bool {
  [
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param",
    "source", "track", "wbr",
  ].contains(tag.to_lower())
}
