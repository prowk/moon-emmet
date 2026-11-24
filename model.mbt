///|
/// 错误位置使用从零开始的 Unicode 字符序号。
#derive(Debug, Eq)
pub(all) struct ExpansionError {
  offset : Int32
  message : String
}

///|
/// 可供编辑器直接检查的 HTML 树。
#derive(Debug, Eq)
pub(all) struct Element {
  tag : String
  is_text : Bool
  mut explicit_repeat : Bool
  mut repeat_count : Int32
  attributes : Array[(String, String?)]
  text : String
  children : Array[Element]
}

///|
priv struct Parser {
  chars : Array[Char]
  mut pos : Int32
  mut count : Int32
}

///|
fn Parser::peek(self : Parser) -> Char? {
  if self.pos < self.chars.length() {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
fn Parser::fail(self : Parser, message : String) -> ExpansionError {
  { offset: self.pos, message, }
}

///|
fn is_name(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '-' ||
  c == ':' ||
  c == '_'
}

///|
pub extend ExpansionError with Eq::{equal, not_equal}

///|
pub extend ExpansionError with Debug::{to_repr}

///|
pub extend Element with Eq::{equal, not_equal}

///|
pub extend Element with Debug::{to_repr}
