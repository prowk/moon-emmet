///|
test "标签、子节点、同级和返回父层" {
  assert_eq(
    expand("div>p+span^footer"),
    Ok("<div><p></p><span></span></div><footer></footer>"),
  )
}

///|
test "非法表达式有位置" {
  assert_eq(parse("div>"), Err({ offset: 4, message: "分组不能为空", }))
}

///|
test "选择器、属性、文本与隐式标签" {
  assert_eq(
    expand("ul>.item{你好<&}"),
    Ok("<ul><li class=\"item\">你好&lt;&amp;</li></ul>"),
  )
  assert_eq(
    expand("input[type=text disabled]"),
    Ok("<input type=\"text\" disabled></input>"),
  )
  assert_true(expand("a[href='oops]") is Err(_))
}

///|
test "括号分组保持层级" {
  assert_eq(
    expand("div>(header>p)+footer"),
    Ok("<div><header><p></p></header><footer></footer></div>"),
  )
  assert_true(expand("(a+b") is Err(_))
  assert_true(expand("a+") is Err(_))
}

///|
test "重复子树、分组与编号" {
  assert_eq(
    expand("ul>li.item$$*2>a{链接$}"),
    Ok(
      "<ul><li class=\"item01\"><a>链接1</a></li><li class=\"item02\"><a>链接2</a></li></ul>",
    ),
  )
  assert_eq(expand("(b+i)*2"), Ok("<b></b><i></i><b></b><i></i>"))
  assert_true(expand("div*1000>span*1000") is Err(_))
}
