# SafeCache 0.4.1

一个面向 TrollStore 的极简 iPhone 缓存清理器。目标不是“清得最狠”，而是**删除边界尽可能小、用户每次都明确知道自己选了什么**。

## 界面

- 首页顶部显示可清理标准缓存总量。
- App 按缓存占用从大到小排列。
- 点按 App 选择/取消；选中后显示蓝色勾选状态。
- 左滑 App 可加入或移出白名单。
- 白名单显示绿色盾牌，永远不会被批量选中。
- “批量”支持：全选有缓存 App、取消全部、把已选加入白名单。
- 底部实时显示“已选几个 App / 约多少空间”。
- `tmp` 是独立开关，默认关闭。
- 默认白名单包含微信 `com.tencent.xin`。

## 删除范围

默认仅允许：

```text
<App Data Container>/Library/Caches/*
```

只有用户主动开启 `tmp` 后，才额外允许：

```text
<App Data Container>/tmp/*
```

**代码没有提供以下删除能力：**

- `Documents`
- `Library/Application Support`
- `Library/Preferences`
- 数据库
- App 整体数据
- Keychain
- 任意用户输入路径

## 安全设计

1. 扫描阶段只读取目录和大小，不删除任何内容。
2. 清理前再次核验“数据容器路径 ↔ Bundle ID”，App 重装/更新造成容器变化时会拒绝旧扫描结果。
3. 删除不是 `rm -rf`，也不使用 `NSFileManager removeItemAtPath:`。
4. 从 App 容器目录开始，用目录文件描述符逐级打开 `Library → Caches`；每一级都带 `O_NOFOLLOW`。
5. 子项用 `fstatat(..., AT_SYMLINK_NOFOLLOW)` 检查。
6. 遇到符号链接直接跳过，既不跟随，也不删除链接本身。
7. 只删除普通文件和清空后的普通目录；socket、FIFO、device 等非常规对象全部跳过。
8. 真正的删除调用只有 `unlinkat`，并且相对于已经安全打开的目录 FD 执行。
9. 不申请 root helper，不使用 `com.apple.private.persona-mgmt`，不执行 shell 命令。
10. 白名单保存在本机 `NSUserDefaults`，批量选择会主动排除白名单。

## 自动安全检查

GitHub Actions 在正式编译前会先运行：

```bash
./scripts/static_audit.sh
```

它会阻止以下代码进入构建：

- 清理核心以外出现新的删除 API；
- `posix_spawn` / `system()` / `NSTask`；
- root helper 权限；
- Cleaner 源码引用 `Documents`、`Application Support`、`Preferences`。

随后还会编译并执行 `tests/posix_safety_test.c`：创建一个缓存目录，并放入指向缓存目录外的符号链接，确认清理后外部文件没有受到影响。

## 权限

`SafeCache.entitlements` 仅保留：

```xml
<key>com.apple.private.security.no-sandbox</key>
<true/>
<key>com.apple.private.security.storage.AppDataContainers</key>
<true/>
```

没有 root helper / persona 权限。

> 这是一个高权限 TrollStore 工具。即便删除边界已经尽量收紧，也建议第一次只选择一个不重要的 App 测试，并在清理前退出目标 App。

## GitHub Actions 编译

1. 新建 GitHub 仓库。
2. 把本项目全部文件上传到仓库根目录。
3. 打开 `Actions` → `Build SafeCache` → `Run workflow`。
4. 构建成功后，在该次运行的 `Artifacts` 下载 `SafeCache-TrollStore`。
5. 解压得到 `SafeCache.tipa`，用 TrollStore 安装。

Actions 使用 `waruhachi/theos-action@v2.6.3` 配置 Theos，然后执行静态审计、安全测试和 Theos 构建。

## 当前验证状态

已在本地完成：

- 源码删除调用静态审计：通过；
- 符号链接逃逸测试：通过；
- `Info.plist` / entitlements XML 解析：通过；
- Bundle ID 一致性检查：通过。

当前环境没有 iOS SDK，因此**尚未在这里完成真正的 iOS 编译及真机 TrollStore 运行测试**。GitHub Actions 会承担下一阶段的实际编译验证。

## 0.3 真机启动兼容修订

- 加入完整 SpringBoard App Icon 资源与 `CFBundleIcons` 配置。
- 补全 `CFBundleInfoDictionaryVersion`、`CFBundleSupportedPlatforms`、`UIDeviceFamily`、`MinimumOSVersion`。
- 固定使用 iOS 16.5 SDK 构建，部署目标仍为 iOS 14.0。
- **启动时不再自动扫描其他 App**。App 能先完整进入 UI，用户主动点击左上角扫描后才读取缓存目录。
- 扫描入口增加 Objective-C 异常兜底；若读取异常，只显示错误，不进入清理逻辑。
- 删除边界未扩大：仍只有 `Library/Caches`，`tmp` 仍默认关闭。

## 0.4 自检修订

- 首屏不再初始化 `NSUserDefaults` / 白名单存储；首次启动仅创建 UIKit 界面。用户主动扫描后才初始化设置与读取其他 App 容器。
- 权限进一步缩减为仅 `com.apple.private.security.no-sandbox`；不包含 `platform-application`、`AppDataContainers`、root helper 或 persona 权限。
- 增加旧式 `CFBundleIconFiles` 兼容项，同时保留 `CFBundleIcons`。
- CI 新增“成品 TIPA 审计”：解包后强制验证 App bundle、可执行文件、Info.plist、图标是否真的进入 bundle 根目录、arm64 架构及最终二进制 entitlements。
- 这意味着 GitHub Actions 绿色不仅代表“编译成功”，还代表成品包结构已通过检查。
