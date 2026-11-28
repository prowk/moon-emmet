# CSS 缩写

`expand_css` 接受用 `+` 连接的声明，不接收样式表或选择器。数值属性为 `m/mt/mr/mb/ml`、`p/pt/pr/pb/pl`、`w/h/fz/lh/op/z`。

margin 和 padding 支持一至四个值：`m10-20`、`p0-1e2r3p`。无显式单位时用 `-` 分隔，首个负值直接加负号，后续负值使用双连字符，如 `m-10--20`；显式单位本身就分隔数值，其后的单个 `-` 是负号，例如 `m1e-2r` 输出 `1em -2rem`。其他数值属性只接受一个值。数值可用小数（包括 `.5`），不支持科学计数法或表达式；`m1e2` 表示 `1em 2px`，不是科学计数法。

单位接受 `px`、`em/e`、`rem/r`、`%/p`、`vh`、`vw`。无后缀的长度默认为 px（包括小数）；零值、line-height、opacity、z-index 默认无单位。padding、width、height、font-size、line-height 拒绝负值；z-index 只接受无单位整数；opacity 只接受无单位数值或百分比。

颜色属性为 `c`（color）、`bgc`（background-color）、`bdc`（border-color），例如 `c#f+bgc#e0+bdc#12345678`。支持 1、2、3、4、6、8 位十六进制，统一小写；单字符重复为三位，双字符重复为六位，其他长度保留，4/8 位保留透明通道。不接受颜色名或 rgb()/hsl()。

固定项为 `d:f/n/b/g/i/ib`（flex/none/block/grid/inline/inline-block）、`pos:a/r/s/f/st`（absolute/relative/static/fixed/sticky）和 `m:a`（margin: auto）。每次输入使用一个完整名称，如 `pos:st`。

错误包含完整输入内从零开始的 Unicode 字符序号；`m10+p-2` 的错误位置为 5。输入不自动去空白，未知属性和单位返回错误。此接口实现限定规则，不验证浏览器支持、数值范围或完整 CSS 合法性。
