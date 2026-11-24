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

///|
/// 编号以最近的显式重复为上下文；基数限制保证转换和反向运算不会溢出。
fn numbered(
  value : String,
  index : Int32,
  total : Int32,
) -> Result[String, ExpansionError] {
  let chars = value.to_array()
  let out = StringBuilder()
  let mut pos = 0
  while pos < chars.length() {
    if chars[pos] != '$' {
      out.write_char(chars[pos])
      pos += 1
      continue
    }
    let start = pos
    while pos < chars.length() && chars[pos] == '$' {
      pos += 1
    }
    let width = pos - start
    let mut base = 1
    let mut reverse = false
    if pos < chars.length() && chars[pos] == '@' {
      pos += 1
      if pos < chars.length() && chars[pos] == '-' {
        reverse = true
        pos += 1
      }
      let digits = pos
      let mut number = 0
      while pos < chars.length() && chars[pos] >= '0' && chars[pos] <= '9' {
        number = number * 10 + chars[pos].to_int() - 48
        if number > 1000000 {
          return Err({ offset: 0, message: "编号基数不能超过 1000000", })
        }
        pos += 1
      }
      if pos > digits {
        base = number
      } else if !reverse {
        return Err({ offset: 0, message: "编号修饰符后缺少基数", })
      }
    }
    let number = (if reverse { total - index + base } else { index + base - 1 }).to_string()
    for _ in 0..<(width - number.length()).max(0) {
      out.write_char('0')
    }
    out.write_string(number)
  }
  Ok(out.to_string())
}
