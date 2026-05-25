# ScreenColorAlert（屏幕颜色监测）

macOS 屏幕颜色实时监测工具。框选屏幕任意区域，检测指定颜色出现时触发语音警报。

## 功能

- **自由框选监测区域**：全屏覆盖层拖拽选择
- **实时颜色检测**：像素级 RGB 匹配，容差可调
- **三连嘟警报**：程序合成提示音，音量可调，支持自定义音频
- **防误报机制**：匹配像素占比阈值，单像素噪点不会触发
- **红色消失停止报警**：目标颜色消失后立即终止警报音
- **监测浮窗**：半透明红色边框，可拖拽移动/缩放以调整监测位置

## 系统要求

- macOS 13.0+
- 需授予**屏幕录制**权限（系统设置 → 隐私与安全性）

## 快速开始

```bash
# 仅编译 + 打包 .app
bash build.sh

# 编译 + 打包 .app + 生成 DMG 安装包
bash package.sh
```

## 自定义图标

将 `AppIcon.icns` 文件放到项目根目录，构建脚本会自动嵌入。无图标文件时自动跳过。

## 项目结构

```
Sources/
├── App/ScreenColorAlertApp.swift          # @main 入口
├── Models/MonitorConfig.swift             # 配置数据模型
├── Services/
│   ├── ScreenCaptureService.swift         # 屏幕区域截取
│   ├── ColorDetectionService.swift        # 像素级颜色匹配
│   └── AudioAlertService.swift            # 警报音合成与播放
├── ViewModels/ColorMonitorViewModel.swift # 核心协调器（MVVM）
└── Views/
    ├── ContentView.swift                  # 主窗口界面
    ├── RegionSelectionView.swift          # 框选区域覆盖层
    └── MonitorOverlayView.swift           # 监测浮窗（可拖拽）
```

## 技术栈

- SwiftUI + AppKit（混编）
- MVVM 架构
- Swift Package Manager 构建
- CGWindowListCreateImage 屏幕截取
- AVAudioPlayer 音频播放

## 许可证

MIT
