///|
fn Parser::sequence(
  p : Parser,
  parent : String,
  depth : Int32,
) -> Result[Array[Element], ExpansionError] {
  if depth >= 64 {
    return Err(p.fail("嵌套超过 64 层"))
  }
  let roots : Array[Element] = []
  let parents = [parent]
  let stack : Array[Array[Element]] = [roots]
  let mut current = roots
  while true {
    if p.peek() == None || p.peek() == Some(')') {
      return Err(p.fail("分组不能为空"))
    }
    let node = if p.peek() == Some('(') {
      p.pos += 1
      let children = match
        p.sequence(parents[parents.length() - 1], depth + stack.length()) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      if p.peek() != Some(')') {
        return Err(p.fail("分组括号未闭合"))
      }
      p.pos += 1
      Element::{
        tag: "",
        is_text: false,
        repeat_count: 1,
        explicit_repeat: false,
        attributes: [],
        text: "",
        children,
      }
    } else {
      match p.element(parents[parents.length() - 1]) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
    }
    if p.peek() == Some('*') {
      p.pos += 1
      let mut n = 0
      let start = p.pos
      while p.peek() is Some(c) && c >= '0' && c <= '9' {
        n = n * 10 + c.to_int() - 48
        p.pos += 1
        if n > 1000 {
          return Err(p.fail("重复次数不能超过 1000"))
        }
      }
      if p.pos == start || n == 0 {
        return Err(p.fail("重复次数应为 1 到 1000"))
      }
      node.repeat_count = n
      node.explicit_repeat = true
    }
    current.push(node)
    match p.peek() {
      None | Some(')') => break
      Some('>') => {
        if node.is_text || node.tag == "" {
          return Err(p.fail("文本或分组后的子节点运算尚未支持"))
        }
        p.pos += 1
        if depth + stack.length() >= 64 {
          return Err(p.fail("嵌套超过 64 层"))
        }
        current = node.children
        stack.push(current)
        parents.push(node.tag)
      }
      Some('+') => {
        p.pos += 1
        if p.peek() == None || p.peek() == Some(')') {
          return Err(p.fail("运算符后缺少节点"))
        }
      }
      Some('^') => {
        while p.peek() == Some('^') {
          p.pos += 1
          if stack.length() > 1 {
            ignore(stack.pop())
            ignore(parents.pop())
          }
        }
        current = stack[stack.length() - 1]
      }
      _ => return Err(p.fail("暂不支持的运算符"))
    }
  }
  Ok(roots)
}

///|
pub fn parse(input : String) -> Result[Array[Element], ExpansionError] {
  let chars = input.to_array()
  if chars.length() == 0 || chars.length() > 8192 {
    return Err({
      offset: 0,
      message: "输入长度应为 1 到 8192 个字符",
    })
  }
  let p = Parser::{ chars, pos: 0, count: 0, }
  let result = match p.sequence("", 0) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if p.pos != chars.length() {
    return Err(p.fail("意外的右括号"))
  }
  Ok(result)
}
