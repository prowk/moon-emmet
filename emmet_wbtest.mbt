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
    Ok("<input type=\"text\" disabled>"),
  )
  assert_true(expand("a[href='oops]") is Err(_))
}

///|
test "格式化输出与空元素" {
  assert_eq(
    expand_with_options("ul>li*2", Options::new(pretty=true)),
    Ok("<ul>\n  <li></li>\n  <li></li>\n</ul>"),
  )
  assert_eq(
    expand_with_options("img[src=x]", Options::new(xhtml=true)),
    Ok("<img src=\"x\" />"),
  )
  assert_true(expand("input>span") is Err(_))
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

///|
test "编辑器光标按最终输出 UTF16 定位" {
  let result = expand_for_editor("p{兔😀}+a[href='']")
  guard result is Ok(value) else { fail("应当成功") }
  assert_eq(value.html, "<p>兔😀</p><a href=\"\"></a>")
  assert_eq(value.tabstops, [19, 21])
}

///|
test "CSS 缩写和值单位" {
  assert_eq(
    expand_css("m10+w50p+d:f"),
    Ok("margin: 10px;\nwidth: 50%;\ndisplay: flex;"),
  )
  assert_eq(expand_css("mt-2r+op0.5"), Ok("margin-top: -2rem;\nopacity: 0.5;"))
  assert_true(expand_css("unknown10") is Err(_))
}

///|
test "纯文本节点和混合内容保持空白" {
  let source = "p>{Click }+a[href=x]{here}+{ to continue}"
  let expected = Ok("<p>Click <a href=\"x\">here</a> to continue</p>")
  assert_eq(expand(source), expected)
  assert_eq(expand_with_options(source, Options::new(pretty=true)), expected)
  assert_eq(expand("{你好<&}"), Ok("你好&lt;&amp;"))
  assert_true(expand("{text}>div") is Err(_))
}
