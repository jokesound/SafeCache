# SafeCache 0.4.1 安全与启动自检

## 删除边界

- 允许清理：`Library/Caches`；`tmp` 仅在用户主动开启时清理。
- 禁止触达：`Documents`、`Library/Application Support`、Preferences、数据库专用目录以及任何用户自定义路径。
- 删除实现仅使用两个 `unlinkat` 调用点；目录逐级 `openat(... O_NOFOLLOW ...)`，条目用 `fstatat(... AT_SYMLINK_NOFOLLOW)` 检查。
- 符号链接不跟随、不主动删除；非常规文件跳过。
- 每次删除前重新验证 Bundle ID 与数据容器元数据一致。

## 权限边界

- 仅保留 `com.apple.private.security.no-sandbox`。
- 不使用 `platform-application`。
- 不使用 `com.apple.private.security.storage.AppDataContainers`。
- 不使用 `com.apple.private.persona-mgmt`、root helper、`posix_spawn`、`NSTask` 或 shell 执行。
- 不包含 TrollStore 官方文档列出的会导致部分设备启动崩溃的 banned code-signing entitlements。

## 启动隔离

- `viewDidLoad` 不扫描其他 App。
- `viewDidLoad` 不初始化 SettingsStore / NSUserDefaults。
- 首次用户动作“扫描”后才读取白名单及 App 容器。
- 因而若 0.4.1 仍在首屏出现前立即退出，问题应优先定位于 bundle/signature/entitlement/OS 兼容层，而不是缓存扫描逻辑。

## 自动验证

CI 在上传 TIPA 前必须通过：

1. 静态删除 API 审计。
2. POSIX 符号链接逃逸测试。
3. 真正解包生成的 `SafeCache.tipa`。
4. 校验 `Payload/SafeCache.app/Info.plist` 和主二进制存在。
5. 校验图标文件实际位于 App bundle 根目录。
6. 校验 arm64 架构。
7. 用 `ldid -e` 校验最终二进制 entitlement，确保只存在预期的高权限项。

## 本地已执行

- plist 语法检查：通过。
- PNG 尺寸与 RGB 模式检查：通过。
- 静态删除边界审计：通过。
- POSIX 符号链接测试：通过。
- Bash 脚本语法检查：通过。

仍无法在当前环境完成真实 iPhone/UIKit 启动测试；必须通过 GitHub macOS runner 构建后，再由 TrollStore 真机验证。
