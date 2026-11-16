# MaimaiData for iOS

一款使用 SwiftUI 原生开发的舞萌 DX（maimai DX）iOS 工具应用，支持曲库检索、谱面信息与容错分析、Rating 计算与水鱼查分器 Best 50 成绩图生成。

## 主要功能

- **曲库与多维检索**：支持按曲名、别名、谱师、歌曲 ID 搜索，支持按等级、小数定数、歌曲分类、收录版本及收藏状态组合筛选与排序
- **谱面详情与容错参考**：展示各难度定数、水鱼拟合定数、物量分布及 Tap / Hold / Slide / Break 单项容错扣分参考，支持高清曲绘查看与保存
- **水鱼查分器与 Best 50**：支持水鱼查分器账号登录（凭据安全存储于本机 Keychain）、B35 / B15 成绩列表查看与 Best 50 成绩图一键生成导出
- **进度表与实用工具**：内置按版本（牌子进度）与按定数等级分组的完成度统计表、单曲 Rating 计算器、目标 Rating 反推及旧框（FiNALE）分数换算 DX 工具

## 构建环境

- iOS 17.0+（iOS 26+ 使用 Liquid Glass，更低版本回退为 Material）
- Xcode 26 / 27+（Swift 5.10+）

## 致谢与参考

- 功能设计与部分贴图素材参考自 Android 端开源项目 [PaperPig/MaimaiData](https://github.com/PaperPig/MaimaiData)
- 谱面数据与查分接口由 [Diving-Fish（水鱼查分器）](https://github.com/Diving-Fish/maimaidx-prober) 提供
- 高清曲绘镜像源由 [LXNS（落雪咖啡屋）](https://lxns.net/) 与 Diving-Fish 提供
- 曲目别名库来自 [Yuri-YuzuChaN/maimaiDX](https://github.com/Yuri-YuzuChaN/maimaiDX)

## 开源许可

本项目基于 [Apache License 2.0](./LICENSE) 协议开源。
Copyright © 2026 SorrowRain.
