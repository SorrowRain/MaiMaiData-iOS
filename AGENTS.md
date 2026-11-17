# MaimaiData-iOS 架构与开发规范 (Agent & Developer Guide)

本文档定义了 `MaimaiData-iOS` 的目录职责、设计令牌、标准组件库及核心业务/并发不变量。任何开发者或自动化工具在进行合规改造、UI 调整或功能迭代时，**必须遵守以下规范**，严禁破坏既有分层或引入游离组件。

---

## 1. 目录结构与职责边界

```text
MaimaiData/
├── MaimaiDataApp.swift              # App 入口（注入全局 DataStore，隔离单元测试宿主启动）
├── Theme/
│   └── AppTheme.swift               # 全局设计令牌（品牌色、游戏语义调色板、圆角、间距、语义字阶、页面背景）
├── Components/                      # 跨页面复用的标准 UI 组件（严禁在 Views/ 下定义通用组件）
│   ├── Badges.swift                 # 胶囊标签、统计砖块、难度定数徽章、分类标签、封面框、筛选 Chip
│   ├── Buttons.swift                # 主按钮、行内胶囊按钮、次级玻璃按钮、菜单胶囊、圆形图标按钮
│   ├── Checklist.swift              # 进度表顶部完成度统计卡片与歌曲网格封面格
│   ├── Containers.swift             # 流式布局 FlowLayout、标准卡片 AppCard / AppSectionCard、内嵌分组、全屏图片预览脚手架 PhotoPreviewScaffold
│   ├── Feedback.swift               # iOS 26+ 液态玻璃 / iOS 17+ 毛玻璃自适应封装 appGlass、Toast、错误弹窗、同步横幅
│   └── Forms.swift                  # 标准单行输入框 AppTextField、密码框 AppSecureField、键盘收起工具 KeyboardDismiss
├── Bridges/
│   └── UIKitBridges.swift           # UIKit 桥接能力（相册保存 PhotoLibrarySaver、系统分享面板 ShareSheet、可双指/双击缩放图片容器 ZoomableImageScrollView）
├── Models/
│   ├── SongData.swift               # 曲目与谱面模型、国内 CDN 封面候选地址生成
│   ├── DifficultyType.swift         # 谱面难度枚举及浅色/深色模式对比度适配色彩
│   ├── MaimaiConstants.swift        # 分类、等级、国服/日服版本常量与配色映射
│   ├── RatingCalculator.swift       # 单曲 Rating 换算、目标 Rating 二分反推、全曲库最大物量统计
│   ├── RecordModels.swift           # 水鱼查分器响应模型、成绩模型、进度表统计、筛选条件模型
│   └── Extensions.swift             # Color(hex:) / 自适应色彩扩展、安全下标 Collection[safe:]、版本号按段数值比较 VersionString
├── Services/
│   ├── DataStore.swift              # @Observable 全局状态中心（本地缓存、曲库/拟合定数同步、登录与成绩拉取、B50 拆表）
│   ├── MaimaiAPI.swift              # 网络层（曲库更新、水鱼拟合定数、登录与玩家成绩接口）
│   ├── AccountCredentialStore.swift # Keychain 凭据存储（水鱼账号列表、密码、Cookie）与缓存文件名哈希
│   ├── ImageLoader.swift            # 内存 + 磁盘双层曲绘缓存 CoverImageCache 与异步曲绘组件 CoverImageView
│   ├── Best50Renderer.swift         # Best 50 成绩图离屏并发渲染引擎
│   ├── SongFilter.swift             # 纯函数曲库多维筛选与排序（供 DataStore 与单元测试共用）
│   └── PreferenceKeys.swift         # UserDefaults / Keychain 键名与默认偏好注册
└── Views/                           # 业务页面视图（仅包含页面级组装与页面私有子视图）
    ├── MainTabView.swift            # 底部三栏 Tab 导航
    ├── SongListView.swift           # 曲目列表、搜索栏、搜索历史与已筛选摘要
    ├── SearchFilterSheet.swift      # 等级/定数双滑块、分类、版本与排序筛选弹窗
    ├── SongDetailView.swift         # 曲目详情、难度切换、物量分布与容错扣分计算
    ├── CoverZoomView.swift          # 曲目高清封面全屏预览页
    ├── RatingToolsView.swift        # Rating 与查分主页（玩家总览、工具入口、单曲计算、目标反推）
    ├── ProberView.swift             # B35 / B15 成绩列表与 Best 50 导出预览
    ├── VersionCheckView.swift       # 按国服版本分组的 Master 完成度进度表
    ├── LevelCheckView.swift         # 按定数等级分组的全难度完成度进度表
    ├── FinaleToDxView.swift         # 旧框 (FiNALE) 判定换算 DX 达成率工具
    ├── SettingsView.swift           # 设置与数据同步页
    └── LoginSheet.swift             # 账号管理二级页 AccountManagementView 与添加账号弹窗 LoginSheet
```

---

## 2. 设计系统与组件使用规范

### 2.1 令牌规范 (`AppTheme`)
- **颜色 (`AppTheme` / `AppTheme.Palette`)**：
  - 主题强调色统一使用 `AppTheme.accent` (`#1668DC`)，收藏红心使用 `AppTheme.favoritePink`。
  - 游戏领域色彩（5 种难度色、7 种歌曲分类色、4 种音符色、判定扣分色、完成度统计色）集中在 `AppTheme.Palette` 中，**数值与 maimai DX 街机视觉严格对齐，禁止随意篡改色值**。
- **字阶 (`AppTheme.Typography`)**：
  - 按视觉层级与语义角色定义（20pt Hero -> 17pt Section/Card Title -> 15pt Row/Input -> 12pt Caption/InlineAction -> 11pt Badge）。
  - **禁止**为了消除单个视图里的字面量而在 `Typography` 中堆砌只用一次的机械拼写命名（如 `subheadlineSemiboldMeta` 等），应优先归入既有语义字阶。
- **玻璃质感 (`View.appGlass`)**：
  - 全项目唯一调用 `.glassEffect` 的入口位于 `Components/Feedback.swift` 的 `View.appGlass(in:tint:interactive:)`（iOS 26+ 使用原生液态玻璃，iOS 17/18 自动回退为 `.ultraThinMaterial` + 品牌色着色）。
  - **禁止**在业务视图中散落编写 `#available(iOS 26.0, *)` 的 `glassEffect` 分支，也**禁止**在滚动列表的普通卡片（`AppCard`）上挂载实时材质模糊，以保证列表 120fps 流畅滚动。

### 2.2 标准组件清单 (`Components/`)
修改或新增 UI 时必须复用以下标准组件，**禁止在业务 View 中手写野生替代品，也禁止向标准组件塞入零散的 padding/opacity/font 透传参数**：

| 组件名 | 所在文件 | 用途与规范 |
| :--- | :--- | :--- |
| `AppCard` / `AppSectionCard` | `Containers.swift` | 页面标准卡片与带蓝色竖条标题栏的分组卡片（支持右侧紧凑操作区 `trailing`） |
| `AppInsetGroup` | `Containers.swift` | 卡片内部浅底分组容器（用于表单行、统计格、表格） |
| `PhotoPreviewScaffold` | `Containers.swift` | 全屏黑底图片缩放预览、分享与保存相册通用脚手架 |
| `AppPrimaryButton` / `AppSecondaryButton` | `Buttons.swift` | 底部主操作玻璃按钮与次级操作按钮 |
| `AppInlineButton` / `AppMenuCapsule` | `Buttons.swift` | 卡片标题栏或行内的 12pt 紧凑胶囊按钮与菜单触发器（共享深浅色自适应描边） |
| `AppCircleIconButton` | `Buttons.swift` | 圆形玻璃图标按钮（必须提供 `accessibilityLabel`） |
| `AppTextField` / `AppSecureField` | `Forms.swift` | 标准输入框（内置 50pt 最小高度、整框点击热区 `.contentShape` 与聚焦高亮边框） |
| `AppCapsuleLabel` | `Badges.swift` | 胶囊标签，通过 `Style`（`.count` / `.filter` / `.compact` / `.metric`）区分语义，禁止外传零散内边距 |
| `DifficultyLevelBadge` | `Badges.swift` | 难度定数徽章（自动处理 Re:MASTER 白底紫框与深浅色文字对比度） |
| `GenreCapsuleTag` / `GenreTagChrome` | `Badges.swift` | 歌曲分类与详情页别名胶囊样式 |
| `SongCoverBadgeView` | `Badges.swift` | 统一曲绘封面框（`.compact` 56pt / `.list` 64pt / `.hero` 100pt） |
| `FilterCapsuleChip` | `Badges.swift` | 筛选弹窗与搜索历史中的可点击胶囊 Chip |

---

## 3. 核心业务、并发与平台规范（防回归必读）

1. **曲绘封面源与缓存 (`SongData.coverCandidateURLs` & `CoverImageCache`)**：
   - 官方源 `maimaidx.jp` 的 TLS 证书链不完整，在 iOS `URLSession` 下会因 SSL 验证失败直接报错。
   - 必须保持使用国内高可用 CDN 源：`https://assets2.lxns.net/maimai/jacket/{baseJacketId}.png` 优先，水鱼 5 位补零地址 `https://www.diving-fish.com/covers/{paddedId}.png` 兜底，缓存 Key 统一按 `jacket_{baseJacketId}` 归并。
2. **搜索框中文输入法防闪屏 (`SongFilterCriteria.isActive` & `SongListView`)**：
   - `SongFilterCriteria.isActive` **绝对不能包含 `!keyword.isEmpty`**。中文输入法选词上屏瞬间会先清空拼音再填入汉字，若 `keyword` 计入 `isActive` 会导致“已筛选”卡片在选词瞬间反复挂载/卸载引起列表跳动。
   - 搜索历史卡片的展开/收起统一由 `.onChange(of: isSearchFocused)` 驱动平滑过渡，并在 `onDisappear` 中无动画重置焦点，避免键盘弹起时直接点进详情页再返回出现布局跳动。
3. **水鱼凭据安全与登录态一致性 (`AccountCredentialStore` & `DataStore`)**：
   - 水鱼密码、Cookie 与已保存账号列表**只能存入 Keychain**（`AccountCredentialStore`），本地成绩缓存文件名使用 `records_\(username.sha256Hex).json`。
   - `DataStore.loginAndSyncRecords` 必须区分**登录请求本身失败**与**登录成功后拉取成绩失败**（`MaimaiAPIError.recordSyncFailedAfterLogin`），严禁在断网未登录成功时向用户误报“登录已成功”。
   - 同步成绩返回时应始终更新 `divingFishNickname`，由 `displayPlayerName` 根据 `useDivingFishNickname` 开关决定最终展示的昵称。
4. **下拉刷新防取消与缓存竞态防护 (`DataStore`)**：
   - `DataStore.performFetchRecordsWithCurrentCookie()` 内部使用非结构化 `Task` 承载网络请求，防止 SwiftUI `.refreshable` 在视图状态刷新瞬间取消底层 `URLSession` 任务（报 `NSURLErrorCancelled`）。
   - 切换账号异步回填本地缓存（`restoreCachedRecords`）受单调递增令牌 `recordsEpoch` 保护，绝不能覆盖网络刚拉回的新数据。
5. **导航栈与图片缩放 (`RatingToolsView` & `ZoomableImageScrollView`)**：
   - “Rating 与查分”页的二级工具页（`ProberView`、`VersionCheckView`、`LevelCheckView`）内点击歌曲跳转详情页，统一复用根视图 `RatingToolsView` 的 `.navigationDestination(for: SongData.self)`，禁止在子页面内重复注册同类型 `navigationDestination`。
   - `ZoomableImageScrollView` 的 `UIImageView` 必须同时绑定 `contentLayoutGuide`（四边）与 `frameLayoutGuide`（宽高）共 6 条约束，确保初始自适应居中且支持 1.0x–4.5x 双指/双击缩放。
6. **工程配置同步 (`project.yml` & `MaimaiData.xcodeproj`)**：
   - 修改构建配置、Target 属性或增删文件时，必须同时保持 `project.yml` 与 `MaimaiData.xcodeproj/project.pbxproj` 一致。
   - 当前工程固定为 **iPhone 竖屏应用**（`TARGETED_DEVICE_FAMILY = 1`），最低系统版本 `iOS 17.0`。
   - `MaimaiDataApp` 启动时通过 `XCTestConfigurationFilePath` 环境变量跳过 `store.bootstrap()`，确保单元测试宿主环境纯净、不触发真实网络请求。
