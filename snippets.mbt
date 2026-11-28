///|
/// 单元素模板，不执行原始 HTML 或递归缩写；显式输入属性优先。
pub struct Snippet {
  name : String
  tag : String
  attributes : Array[(String, String?)]
  text : String
}

///|
pub fn Snippet::new(
  name : String,
  tag : String,
  attributes~ : Array[(String, String?)] = [],
  text~ : String = "",
) -> Snippet {
  { name, tag, attributes: attributes.copy(), text, }
}

///|
/// 此表按本库使用场景独立维护，不导入上游 snippet 数据。
fn builtin_snippet(name : String) -> Snippet? {
  match name {
    "bq" => Some(Snippet::new(name, "blockquote"))
    "btn" => Some(Snippet::new(name, "button"))
    "btn:s" =>
      Some(Snippet::new(name, "button", attributes=[("type", Some("submit"))]))
    "btn:r" =>
      Some(Snippet::new(name, "button", attributes=[("type", Some("reset"))]))
    "input:text"
    | "input:email"
    | "input:password"
    | "input:checkbox"
    | "input:radio"
    | "input:submit"
    | "input:number"
    | "input:search"
    | "input:date"
    | "input:hidden" => {
      let kind = name.split(":").to_array()[1].to_owned()
      Some(Snippet::new(name, "input", attributes=[("type", Some(kind))]))
    }
    "link:css" =>
      Some(
        Snippet::new(name, "link", attributes=[
          ("rel", Some("stylesheet")),
          ("href", Some("")),
        ]),
      )
    "script:src" =>
      Some(Snippet::new(name, "script", attributes=[("src", Some(""))]))
    "form:get" | "form:post" => {
      let form_method = name.split(":").to_array()[1].to_owned()
      Some(
        Snippet::new(name, "form", attributes=[("method", Some(form_method))]),
      )
    }
    "meta:vp" =>
      Some(
        Snippet::new(name, "meta", attributes=[
          ("name", Some("viewport")),
          ("content", Some("width=device-width, initial-scale=1.0")),
        ]),
      )
    _ => None
  }
}

///|
fn find_snippet(name : String, snippets : Array[Snippet]) -> Snippet? {
  // 同名调用方定义覆盖内置项，数组中后面的定义优先。
  for i = snippets.length() - 1; i >= 0; i = i - 1 {
    if snippets[i].name == name {
      return Some(snippets[i])
    }
  }
  builtin_snippet(name)
}

///|
fn validate_snippets(snippets : Array[Snippet]) -> Result[Unit, ExpansionError] {
  let mut size = 0
  if snippets.length() > 128 {
    return Err({ offset: 0, message: "自定义 snippet 不能超过 128 项", })
  }
  for snippet in snippets {
    if snippet.name == "" ||
      !snippet.name.to_array().all(is_name) ||
      snippet.tag == "" ||
      !snippet.tag.to_array().all(is_name) ||
      (snippet.tag[0] >= '0' && snippet.tag[0] <= '9') {
      return Err({ offset: 0, message: "snippet 名称或标签无效", })
    }
    size += snippet.name.length() + snippet.tag.length() + snippet.text.length()
    if snippet.attributes.length() > 64 {
      return Err({ offset: 0, message: "snippet 属性不能超过 64 项", })
    }
    for (key, value) in snippet.attributes {
      if key == "" || !key.to_array().all(is_name) {
        return Err({ offset: 0, message: "snippet 属性名无效", })
      }
      size += key.length() + value.unwrap_or("").length()
    }
    if size > 8192 {
      return Err({
        offset: 0,
        message: "snippet 配置超过 8192 个 UTF-16 单元",
      })
    }
  }
  Ok(())
}
