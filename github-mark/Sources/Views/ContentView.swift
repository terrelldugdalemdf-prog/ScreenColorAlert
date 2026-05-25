import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ColorMonitorViewModel
    @State private var flashOn = false

    private let flashTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            // 目标颜色选择
            HStack {
                Text("目标颜色")
                    .frame(width: 60, alignment: .leading)
                ColorPicker("", selection: $viewModel.config.targetColor)
                    .labelsHidden()
                Spacer()
            }

            // 容差滑块
            HStack {
                Text("颜色容差")
                    .frame(width: 60, alignment: .leading)
                Slider(value: $viewModel.config.colorTolerance, in: 0.01...0.50)
                Text(String(format: "%.2f", viewModel.config.colorTolerance))
                    .frame(width: 36, alignment: .trailing)
                    .font(.system(.body, design: .monospaced))
            }

            // 匹配占比
            HStack {
                Text("匹配占比")
                    .frame(width: 60, alignment: .leading)
                Slider(value: $viewModel.config.minMatchRatio, in: 0.01...0.30)
                Text("\(Int(viewModel.config.minMatchRatio * 100))%")
                    .frame(width: 36, alignment: .trailing)
                    .font(.system(.body, design: .monospaced))
            }

            // 采样步长
            HStack {
                Text("采样密度")
                    .frame(width: 60, alignment: .leading)
                Picker("", selection: $viewModel.config.sampleStep) {
                    Text("高").tag(1)
                    Text("中").tag(4)
                    Text("低").tag(8)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Divider()

            // 监测区域信息
            HStack {
                Text("监测区域")
                    .frame(width: 60, alignment: .leading)
                Text(regionDescription)
                    .foregroundColor(viewModel.hasValidRegion ? .primary : .secondary)
                Spacer()
            }

            // 操作按钮行
            HStack(spacing: 12) {
                Button(action: viewModel.showRegionSelector) {
                    Label("选择区域", systemImage: "rectangle.dashed")
                }
                .disabled(viewModel.state == .monitoring)

                if viewModel.state == .monitoring {
                    Button(action: viewModel.stopMonitoring) {
                        Label("停止监测", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button(action: viewModel.startMonitoring) {
                        Label("开始监测", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasValidRegion)
                }

                Button(action: viewModel.testAlert) {
                    Label("测试警报", systemImage: "speaker.wave.2")
                }
                .disabled(viewModel.state == .monitoring)
            }

            Divider()

            // 音频设置
            VStack(spacing: 10) {
                HStack {
                    Text("警报音量")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $viewModel.config.alertVolume, in: 0.0...1.0)
                    Text("\(Int(viewModel.config.alertVolume * 100))%")
                        .frame(width: 36, alignment: .trailing)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("音频文件")
                        .frame(width: 60, alignment: .leading)
                    Text(viewModel.config.customAudioName ?? "默认嘟声")
                        .foregroundColor(viewModel.config.customAudioURL == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button("选择...") {
                        viewModel.pickAudioFile()
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.state == .monitoring)

                    if viewModel.config.customAudioURL != nil {
                        Button(action: viewModel.clearCustomAudio) {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .disabled(viewModel.state == .monitoring)
                    }
                }
            }

            Divider()

            // 状态指示区
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 28, height: 28)
                        .blur(radius: 6)
                        .opacity(flashOn ? 0.6 : 0)
                }
                .opacity(indicatorOpacity)
                .onReceive(flashTimer) { _ in
                    if viewModel.state == .monitoring, viewModel.isColorDetected {
                        flashOn.toggle()
                    } else {
                        flashOn = false
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var regionDescription: String {
        guard let rect = viewModel.config.selectedRect else {
            return "未选择"
        }
        return "x:\(Int(rect.origin.x)) y:\(Int(rect.origin.y)) \(Int(rect.width))×\(Int(rect.height))"
    }

    private var indicatorColor: Color {
        switch viewModel.state {
        case .monitoring:
            return viewModel.isColorDetected ? .red : .green
        case .idle:
            return .gray
        case .selecting:
            return .blue
        }
    }

    private var indicatorOpacity: Double {
        if viewModel.state == .monitoring, viewModel.isColorDetected {
            return flashOn ? 1.0 : 0.2
        }
        return 1.0
    }

    private var statusTitle: String {
        switch viewModel.state {
        case .idle: return "就绪"
        case .selecting: return "框选中..."
        case .monitoring:
            return viewModel.isColorDetected ? "警报" : "监测中"
        }
    }
}
