# MaimaiData for iOS

一款使用 SwiftUI 原生开发的舞萌 DX（maimai DX）iOS 工具应用，提供离线曲库多维检索、谱面物量与容错扣分分析、Rating 计算反推，以及水鱼查分器成绩同步与 Best 50 成绩图导出。

## 功能概览

- **曲库与多维检索**：支持**国服 / 国际服 / 日服**三区服切换；支持按曲名、别名、谱师、歌曲 ID 搜索（内置搜索历史），支持按等级、精确小数定数、歌曲分类、对应区服收录版本及收藏状态组合筛选与多难度排序。
- **谱面详情与容错参考**：展示各难度定数（含升降定数及跨服国服定数对比）、水鱼拟合定数、谱师、物量比例分布条，以及 Tap / Hold / Slide / Break 单项容错损失达成率参考，支持高清曲绘双指缩放预览、分享与保存相册。
- **水鱼查分器与 Best 50**：支持水鱼查分器多账号管理与切换，支持旧版本 B35 / 现行版本 B15 成绩列表查看（支持按日服 / 国际服最新定数与 `AP +1` 新规模拟重排）及 Best 50 成绩图离屏并发渲染导出。
- **进度表与实用工具**：内置按当前区服版本分组的 Master 完成度进度表（牌子查询）、按 1～15 级定数分组的全难度完成度进度表、单曲 Rating 即时计算器与目标总 Rating 达成率反推。

## 环境要求与构建测试

- **运行环境**：iOS 17.0+（iPhone 竖屏；iOS 26+ 原生启用 Liquid Glass 液态玻璃，iOS 17 / 18 自动回退为自适应 Material 材质）
- **开发环境**：Xcode 26+，Swift 5.10+

### 本地开发与命令

1. **打开工程**：直接双击打开 `MaimaiData.xcodeproj` 选择真机或 iOS Simulator 运行。
2. **工程配置同步**（可选）：若安装了 [XcodeGen](https://github.com/yonaskolb/XcodeGen)，在修改 `project.yml` 后可执行 `xcodegen generate` 重新生成工程配置。
3. **命令行构建与测试**：

```bash
# 编译应用与单元测试产物（无需签名，适合本地快速静态校验）
xcodebuild build-for-testing \
  -project MaimaiData.xcodeproj \
  -scheme MaimaiData \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO

# 在指定模拟器上执行单元测试
xcodebuild test \
  -project MaimaiData.xcodeproj \
  -scheme MaimaiData \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 项目架构

```text
MaimaiData/
├── MaimaiDataApp.swift      # 应用入口（注入全局 DataStore，隔离单元测试宿主网络副作用）
├── Theme/                   # 全局设计令牌（AppTheme：色彩、间距、圆角、语义字阶、页面背景）
├── Components/              # 标准复用 UI 组件库（Badges、Buttons、Checklist、Containers、Feedback、Forms）
├── Bridges/                 # UIKit 桥接能力（系统相册保存、分享面板、双指/双击缩放图片容器）
├── Models/                  # 领域模型、难度与版本常量、Rating 换算算法与基础扩展
├── Services/                # 全局状态 DataStore、网络层 MaimaiAPI、Keychain 凭据、曲绘双层缓存、B50 渲染与筛选纯函数
├── Views/                   # 各业务页面视图与页面私有子视图
└── Resources/               # 贴图资源 Assets.xcassets 与内置离线曲库种子 songdata_seed.json
MaimaiDataTests/             # 单元测试（Rating 计算边界与曲库多维筛选排序）
```

> 详细的架构分层边界、设计令牌速查表、标准组件选型清单与防回归红线请查阅 **[AGENTS.md](./AGENTS.md)**。新功能开发前请务必先阅读该规范。

## 数据源与隐私说明

- **离线优先**：应用内置 `songdata_seed.json` 离线曲库种子，首次启动无需联网即可检索曲库；联网时支持按需增量检查曲库与水鱼拟合定数（5 天缓存周期）更新，持久化于应用沙盒 `Application Support/MaimaiData/`。
- **曲绘双层缓存**：曲绘优先从国内高可用 CDN 拉取，采用 `NSCache` 内存缓存 + `Caches/MaimaiCovers/` 磁盘缓存，可在「设置与数据」中随时查看占用并一键清理。
- **凭据安全隔离**：水鱼查分器账号列表、密码与登录 Cookie **仅存储于本机系统 Keychain**（`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`），不写入 `UserDefaults`，也不向水鱼官方接口以外的任何第三方发送；本地成绩缓存文件名经 SHA-256 脱敏处理。

## 致谢与参考

- 功能设计与部分贴图素材参考自 Android 端开源项目 [PaperPig/MaimaiData](https://github.com/PaperPig/MaimaiData)
- 谱面统计数据与玩家查分接口由 [Diving-Fish（水鱼查分器）](https://github.com/Diving-Fish/maimaidx-prober) 提供
- 高清曲绘镜像源由 [LXNS（落雪咖啡屋）](https://lxns.net/) 与 Diving-Fish 提供
- 曲目别名库来自 [Yuri-YuzuChaN/maimaiDX](https://github.com/Yuri-YuzuChaN/maimaiDX)
- 日服与国际服曲库及封面数据源由 [zetaraku/arcade-songs-fetch](https://github.com/zetaraku/arcade-songs-fetch) 提供，曲目底层 ID 映射由 [DXRating](https://github.com/gekichumai/dxrating) 提供

## 开源许可

本项目基于 [Apache License 2.0](./LICENSE) 协议开源。  
Copyright © 2026 SorrowRain.
