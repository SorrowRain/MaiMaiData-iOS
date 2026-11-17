# MaimaiData for iOS

一款使用 SwiftUI 原生开发的舞萌 DX（maimai DX）iOS 工具应用，支持曲库检索、谱面信息与容错分析、Rating 计算与水鱼查分器 Best 50 成绩图生成。

## 主要功能

- **曲库与多维检索**：支持按曲名、别名、谱师、歌曲 ID 搜索，支持按等级、小数定数、歌曲分类、收录版本及收藏状态组合筛选与排序
- **谱面详情与容错参考**：展示各难度定数、水鱼拟合定数、物量分布及 Tap / Hold / Slide / Break 单项容错扣分参考，支持高清曲绘查看与保存
- **水鱼查分器与 Best 50**：支持水鱼查分器账号登录（凭据安全存储于本机 Keychain）、B35 / B15 成绩列表查看与 Best 50 成绩图一键生成导出
- **进度表与实用工具**：内置按版本（牌子进度）与按定数等级分组的完成度统计表、单曲 Rating 计算器、目标 Rating 反推及旧框（FiNALE）分数换算 DX 工具

## 项目结构

```text
MaimaiData/
├── Theme/           # 全局设计令牌（AppTheme：色彩、间距、圆角、语义字阶、背景）
├── Components/      # 标准复用 UI 组件（Badges、Buttons、Checklist、Containers、Feedback、Forms）
├── Bridges/         # UIKit 桥接组件（相册保存、系统分享、双指/双击缩放图片视图）
├── Models/          # 曲目、谱面、难度、水鱼成绩、Rating 算法与通用扩展
├── Services/        # 全局状态 DataStore、网络接口 MaimaiAPI、Keychain 凭据、曲绘缓存、B50 渲染与纯函数筛选
├── Views/           # 各业务页面视图
└── Resources/       # 贴图素材 Assets.xcassets 与离线曲库种子数据 songdata_seed.json
MaimaiDataTests/     # 单元测试（Rating 计算与曲库多维筛选）
```

详细的架构分层、标准组件清单与防回归约束请参见 [AGENTS.md](./AGENTS.md)。

## 构建环境

- iOS 17.0+（iOS 26+ 使用原生 Liquid Glass，iOS 17/18 自动回退为 Material）
- Xcode 26 / 27+（Swift 5.10+），仅支持 iPhone 竖屏

## 致谢与参考

- 功能设计与部分贴图素材参考自 Android 端开源项目 [PaperPig/MaimaiData](https://github.com/PaperPig/MaimaiData)
- 谱面数据与查分接口由 [Diving-Fish（水鱼查分器）](https://github.com/Diving-Fish/maimaidx-prober) 提供
- 高清曲绘镜像源由 [LXNS（落雪咖啡屋）](https://lxns.net/) 与 Diving-Fish 提供
- 曲目别名库来自 [Yuri-YuzuChaN/maimaiDX](https://github.com/Yuri-YuzuChaN/maimaiDX)

## 开源许可

本项目基于 [Apache License 2.0](./LICENSE) 协议开源。
Copyright © 2026 SorrowRain.
