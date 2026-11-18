# MaimaiData 双端原生协同开发总规范 (Dual-Native Anti-Drift Guide)

本目录承载舞萌 DX 查分与曲库工具的双端纯原生工程：
- **iOS 端 (SwiftUI)**：`./MaimaiData-iOS/`（详见 `./MaimaiData-iOS/AGENTS.md`）
- **Android 端 (Jetpack Compose)**：`./MaimaiData-Android/`（详见 `./MaimaiData-Android/AGENTS.md`）
- **共享业务与接口契约**：`./SHARED_SPEC.md`

---

## 防偏移铁律（任何新需求或 Bug 修复必读）

由于双端采用 **SwiftUI + Jetpack Compose 1:1 镜像同构架构**（不共享编译期二进制，但 39 个源码文件按目录、命名与职责一一对应），后续任何迭代**必须严格执行以下流程，严禁凭记忆单边脑补**：

1. **改前双端对照阅读**：
   - 修改任意页面或服务前，**必须同时读取** `MaimaiData-iOS` 与 `MaimaiData-Android` 中对应的同名源码文件（例如改详情页时必须同时读取 `SongDetailView.swift` 与 `SongDetailView.kt`），确认当前卡片层级、分段栏文案、字段顺序完全一致后再动手。
   - 若调用子 Agent 分工，必须在 Prompt 中明确要求子 Agent **直接读取另一端对应源码逐块对齐**，禁止在 Prompt 中用模糊摘要代替源码对照。
2. **公共组件先行**：
   - 新增或改造跨页面控件（如卡片、内嵌行、胶囊按钮、滑条 `AppSlider`、输入框等）必须下沉至双端各自的 `Components/` / `components/`，严禁在单个 `Views/` 页面手写一次性样式。
3. **同回合双端同步交付与测试**：
   - 除非用户明确指定“只改单端平台特性”，否则所有功能增删、文案微调、算分/筛选/牌子规则变更必须在同一回合同步落地双端，并分别执行：
     - iOS：`xcodebuild test` 零警告通过
     - Android：`./gradlew testDebugUnitTest assembleDebug` 零警告通过
   - 若涉及数据源、节流阈值、算分公式或牌子规则变更，同步更新 `./SHARED_SPEC.md` 与双端对等的单元测试用例。
