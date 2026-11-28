# MVP 构建与首次发布准备

项目计划在完成 MVP 后首次发布 `v0.1.0`，当前尚未正式发布。`moon.mod` 的 `0.1.0` 是首次发布的目标版本号，用于开发构建、打包与预检；代码推送、生成 ZIP 和通过预检均不表示已正式发行。

需要 MoonBit 工具链、Node.js 22+ 和 Python 3。CI 固定 moonc/core `0.10.20+65efd5b93`；本地已验证 moon `0.1.20261104` 和 Node `22.14.0`。核心支持 JS、Wasm-GC，ESM 桥接仅构建 JS。构建无需 npm 运行时依赖；完整开发检查的上游对照需要 `npm ci --ignore-scripts`。

```powershell
npm ci --ignore-scripts
npm run check
npm run check:package
moon package --list
moon publish --dry-run
```

`check:package` 生成 `_build/publish/prowk-moon-emmet-0.1.0.zip`，核对必要元数据和归档文件，从 ZIP 提取源码后创建独立消费者，通过公开接口在 JS、Wasm-GC 下检查展开、模板、紧凑树和光标位置，并从归档源码构建桥接。结果写入 `_build/publish/verification.json`。验证工作区保留在 `_build/publish/consumer-*`，方便复现；检查不要求 Mooncakes 登录，也不创建公开 release。

本地源码使用 `moon.work`：将解压后的库放在 `library`，消费者放在 `consumer`，工作区根目录写入 `members = ["library", "consumer"]`。消费者 `moon.mod` 中声明 `import { "prowk/moon-emmet@0.1.0" }`，由工作区解析本地模块；`moon.pkg` 导入 `"prowk/moon-emmet" @engine` 后调用。该工作区示例不依赖注册表中存在这个版本；正式首发后才可按实际发布版本从注册表安装。

`moon publish --dry-run` 会进一步向 Mooncakes 进行服务端预检，不创建发布版本；需要网络访问和适用的注册表登录。预检通过仅说明提交的数据可接受，不代表版本已发行。完成 MVP 并决定正式首发时，重新执行检查、确认账号命名空间和 `0.1.0` 版本号后，再运行 `moon publish`。普通 CI 只验证本地归档与消费者，不依赖发布凭据，也不执行正式发布。

项目使用 MIT 许可证。缩写核心和小型元素模板表独立编写，参考 Emmet 的公开语法；Emmet 2.4.11 仅作为 MIT 许可的开发期对照依赖，通过锁文件固定安装。公共包仅包含源码、示例与技术文档；打包以项目忽略规则为准，构建产物与本地辅助目录不进入归档。
