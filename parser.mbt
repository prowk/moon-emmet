///|
fn Parser::element(self : Parser) -> Result[Element, ExpansionError] {
  let start = self.pos
  while self.peek() is Some(c) && is_name(c) {
    self.pos += 1
  }
  if start == self.pos {
    return Err(self.fail("需要标签名"))
  }
  self.count += 1
  if self.count > 4096 {
    return Err(self.fail("节点数量超过限制"))
  }
  Ok({ tag: String::from_array(self.chars[start:self.pos]), children: [], })
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
  let roots : Array[Element] = []
  let stack : Array[Array[Element]] = [roots]
  let mut current = roots
  while true {
    let node = match p.element() {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    current.push(node)
    match p.peek() {
      None => break
      Some('>') => {
        p.pos += 1
        if stack.length() >= 64 {
          return Err(p.fail("嵌套超过 64 层"))
        }
        current = node.children
        stack.push(current)
      }
      Some('+') => p.pos += 1
      Some('^') => {
        while p.peek() == Some('^') {
          p.pos += 1
          if stack.length() > 1 {
            ignore(stack.pop())
          }
        }
        current = stack[stack.length() - 1]
      }
      _ => return Err(p.fail("暂不支持的运算符"))
    }
  }
  Ok(roots)
}
