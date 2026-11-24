///|
pub struct Options {
  pretty : Bool
  indent : String
  xhtml : Bool
}

///|
pub fn Options::new(
  pretty~ : Bool = false,
  indent~ : String = "  ",
  xhtml~ : Bool = false,
) -> Options {
  { pretty, indent, xhtml, }
}

///|
fn is_void(tag : String) -> Bool {
  [
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param",
    "source", "track", "wbr",
  ].contains(tag.to_lower())
}
