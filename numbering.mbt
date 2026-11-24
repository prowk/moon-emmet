///|
/// 连续美元符号决定编号宽度，重复子树沿用最近一层的编号。
fn numbered(value : String, index : Int32) -> String {
  let chars = value.to_array()
  let out = StringBuilder()
  let mut pos = 0
  while pos < chars.length() {
    if chars[pos] == '$' {
      let start = pos
      while pos < chars.length() && chars[pos] == '$' {
        pos += 1
      }
      let num = index.to_string()
      for _ in 0..<(pos - start - num.length()).max(0) {
        out.write_char('0')
      }
      out.write_string(num)
    } else {
      out.write_char(chars[pos])
      pos += 1
    }
  }
  out.to_string()
}

///|
/// 在真正复制字符串前计算展开规模，避免重复相乘耗尽资源。
fn expanded_size(nodes : Array[Element], budget : Int32) -> Int32 {
  let mut total = 0
  for node in nodes {
    let children = expanded_size(node.children, budget)
    if children > budget {
      return budget + 1
    }
    let cost = (children + 1) * node.repeat_count
    if cost > budget - total {
      return budget + 1
    }
    total += cost
  }
  total
}
