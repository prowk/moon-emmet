///|
test "标签、子节点、同级和返回父层" {
  assert_eq(
    expand("div>p+span^footer"),
    Ok("<div><p></p><span></span></div><footer></footer>"),
  )
}

///|
test "非法表达式有位置" {
  assert_eq(parse("div>"), Err({ offset: 4, message: "需要标签名", }))
}
