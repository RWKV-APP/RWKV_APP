# 比赛申请表填写内容

## 10. 项目概述 - 必填

RWKV App 是一款在端侧设备上离线运行大语言模型的 AI 应用，支持 iOS/Android/Windows/macOS/Linux 多平台。产品功能包括：多轮 AI 对话、文本转语音（TTS）、视觉理解、角色扮演、代码补全等，所有计算在本地完成，无需网络连接。用途：为个人用户提供完全离线的 AI 助手服务，保护数据隐私，降低 AI 使用成本。技术水平：采用 RWKV 架构实现高效推理，支持 NPU/GPU/CPU 多硬件加速；使用 Flutter 跨平台框架，一套代码覆盖多平台；通过 Dart FFI 实现与 C++ 推理引擎的高效通信。应用场景：个人 AI 助手、离线办公辅助、隐私敏感场景的 AI 应用、教育学习工具、开发者代码助手等。市场前景：随着边缘 AI 和隐私保护需求增长，端侧 AI 应用市场前景广阔；本项目已上架 Google Play 和 App Store，获得用户认可，具备良好的商业化潜力。

## 11. 预期效果 (Expected Outcome) - 必填

本项目通过将大语言模型部署到端侧设备，实现完全离线的 AI 应用体验。经济效益：降低 AI 服务成本，无需云端服务器，大幅减少云服务费用；提升用户体验，离线运行消除网络延迟，响应速度更快；保护数据安全，本地处理避免数据上传，保护用户隐私。社会效益：推动边缘 AI 普及，让普通用户以低成本体验大语言模型；促进技术民主化，开源架构使更多开发者参与 AI 应用开发；提升数字包容性，支持多平台让不同设备用户都能使用；优化资源利用，充分利用设备本地算力，减少云端资源消耗。突出案例：已在 Google Play 和 App Store 上架获得用户好评；支持多语言界面服务全球用户；支持多种模型切换实现个性化体验。

## 12. 资质荣誉 (Qualifications and Honors) - 必填

- 项目已在 Google Play Store 和 Apple App Store 正式上架
- 开源项目，GitHub 上获得社区关注和贡献
- 支持多平台部署（iOS/Android/Windows/macOS/Linux），展现跨平台技术能力
- 项目采用 Apache 2.0 开源协议，促进技术共享

## 13. 方案特色 (Solution Features) - 必填（100 字以内）

完全离线运行大语言模型，支持 NPU/GPU/CPU 多硬件加速。跨平台 Flutter 架构，一套代码覆盖 iOS/Android/Windows/macOS/Linux。集成聊天、语音合成、视觉理解等 AI 能力，用户可自由切换模型，无需网络即可享受 AI 服务。

## 14. 项目已使用或计划使用的基于骁龙的软硬件平台、工具及运行环境 - 必填

本项目计划在 Android 平台上充分利用骁龙处理器的 AI 能力：

- 计划使用骁龙处理器的 Hexagon DSP/NPU 进行模型推理加速
- 计划集成 Qualcomm AI Engine (QNN SDK) 以优化 RWKV 模型在骁龙平台上的性能
- 计划利用骁龙平台的统一内存架构（Unified Memory Architecture）优化大模型权重加载
- 计划支持骁龙 8 系列处理器的 AI 加速能力，实现更高效的端侧推理

## 15. 项目目前已使用 | 已实现运行的其他非骁龙软硬件平台、工具及运行环境 - 必填

**已实现的平台：**

- iOS 平台：使用 Apple Neural Engine (ANE) 和 Metal 框架进行 GPU 加速
- Android 平台：使用 Android Neural Networks API (NNAPI) 支持多种芯片厂商的 NPU/GPU 加速
- Windows/macOS/Linux 平台：使用 CPU 和 GPU（如 CUDA、Metal）进行推理
- Flutter 框架：跨平台 UI 框架，支持多平台部署
- C++推理引擎：基于 RWKV 架构的本地推理引擎，支持多种硬件加速

**技术栈：**

- Dart FFI：用于 Dart 与 C++引擎的高效通信
- Hugging Face：作为模型权重来源
- Riverpod：状态管理框架

## 16. 程序框架 - 必填（上传文件，至多 9 个）

建议上传以下文件：

1. 项目架构图（展示 Flutter UI 层、Dart FFI 层、C++推理引擎层的关系）
2. RWKV 模型推理流程图
3. 多平台部署架构图
4. 硬件加速适配架构图（NPU/GPU/CPU）
5. 项目 GitHub 仓库链接截图或 README 文件

## 17. 流程图 (选填) - 可选

建议上传：

- 模型加载流程图
- 推理请求处理流程图
- 多轮对话状态管理流程图

## 18. 方案视频展示或在视频网站链接 (选填) - 可选

可填写：

- GitHub 项目地址：https://github.com/RWKV-APP/RWKV_APP
- Google Play 链接：https://play.google.com/store/apps/details?id=com.rwkvzone.chat
- App Store 链接：https://apps.apple.com/us/app/rwkv-chat/id6740192639

## 19. 是否在开发 AI 应用中曾用过高通的开发工具? - 必填

目前尚未使用过高通的开发工具，但计划在后续版本中集成：

- 计划使用 Qualcomm AI Engine (QNN SDK) 优化模型推理性能
- 计划使用 Hexagon DSP/NPU 进行模型加速
- 计划使用 SNPE (Snapdragon Neural Processing Engine) 进行模型转换和优化
- 计划探索 QAI AppBuilder 等工具提升开发效率

## 20. 是否有使用过高通平台的手机或 PC 做过 AI 应用开发的经历? - 必填

目前主要使用 Apple 设备（iPhone、Mac）和通用 Android 设备进行开发测试。计划在获得骁龙平台设备后，针对骁龙处理器的 AI 能力进行专门优化，充分利用 Hexagon DSP/NPU 等硬件加速单元，提升 RWKV 模型在骁龙平台上的推理性能和能效比。
