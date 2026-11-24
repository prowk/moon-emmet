///|
/// HTML 属性保留首次出现的位置，后续显式值覆盖旧值；class 合并去重。
fn set_attribute(
  attrs : Array[(String, String?)],
  key : String,
  value : String?,
) -> Unit {
  for i in 0..<attrs.length() {
    let (old_key, old_value) = attrs[i]
    if old_key.to_lower() == key.to_lower() {
      if key.to_lower() == "class" {
        let classes : Array[String] = []
        for
          part in (old_value.unwrap_or("") + " " + value.unwrap_or("")).split(
            " ",
          ) {
          let part = part.to_owned()
          if part != "" && !classes.contains(part) {
            classes.push(part)
          }
        }
        attrs[i] = (old_key, Some(classes.join(" ")))
      } else {
        attrs[i] = (old_key, value)
      }
      return
    }
  }
  attrs.push((key, value))
}

///|
fn default_attributes(tag : String) -> Array[(String, String?)] {
  match tag {
    "a" => [("href", Some(""))]
    "img" => [("src", Some("")), ("alt", Some(""))]
    "input" => [("type", Some("text"))]
    "form" => [("action", Some(""))]
    _ => []
  }
}
