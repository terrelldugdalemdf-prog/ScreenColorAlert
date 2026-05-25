import SwiftUI
import AppKit
import Combine

@MainActor
final class ColorMonitorViewModel: ObservableObject {
    @Published var config = MonitorConfig()
    @Published var state: MonitorState = .idle
    @Published var statusMessage = "就绪"
    @Published var isColorDetected = false

    private let captureService = ScreenCaptureService()
    private let detectionService = ColorDetectionService()
    private let audioService = AudioAlertService()

    private var monitorTimer: Timer?
    private var selectionOverlay: NSWindow?
    private var monitorOverlayWindow: NSWindow?

    var hasValidRegion: Bool {
        config.selectedRect != nil
    }

    // MARK: - Region Selection

    func showRegionSelector() {
        guard let screen = NSScreen.main else { return }

        state = .selecting
        hideMonitorOverlay()

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = NSColor.black.withAlphaComponent(0.35)
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false

        let selectionView = RegionSelectionView(frame: screen.frame)
        selectionView.onSelectionComplete = { [weak self] rect in
            guard let self else { return }
            self.config.selectedRect = rect
            self.state = .idle
            self.statusMessage = "已选择区域: (\(Int(rect.origin.x)), \(Int(rect.origin.y))) \(Int(rect.width))×\(Int(rect.height))"
            self.selectionOverlay?.close()
            self.selectionOverlay = nil
        }
        selectionView.onSelectionCancelled = { [weak self] in
            self?.state = .idle
            self?.statusMessage = "已取消选择"
            self?.selectionOverlay?.close()
            self?.selectionOverlay = nil
        }

        window.contentView = selectionView
        window.makeKeyAndOrderFront(nil)
        selectionOverlay = window
    }

    // MARK: - Monitor Overlay

    private func showMonitorOverlay() {
        guard let rect = config.selectedRect, rect.width > 0, rect.height > 0 else { return }

        hideMonitorOverlay()

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 30, height: 30)

        let overlayView = MonitorOverlayView(frame: NSRect(origin: .zero, size: rect.size))
        overlayView.autoresizingMask = [.width, .height]
        window.contentView = overlayView

        window.makeKeyAndOrderFront(nil)
        monitorOverlayWindow = window
    }

    private func hideMonitorOverlay() {
        monitorOverlayWindow?.orderOut(nil)
        monitorOverlayWindow = nil
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard hasValidRegion else {
            statusMessage = "请先选择监测区域"
            return
        }
        state = .monitoring
        statusMessage = "监测中..."
        isColorDetected = false

        showMonitorOverlay()

        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performCapture()
            }
        }
    }

    func pickAudioFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.config.customAudioURL = url
            self?.config.customAudioName = url.lastPathComponent
        }
    }

    func clearCustomAudio() {
        config.customAudioURL = nil
        config.customAudioName = nil
    }

    func testAlert() {
        syncAudioConfig()
        audioService.playAlert()
    }

    private func syncAudioConfig() {
        audioService.volume = Float(config.alertVolume)
        audioService.customAudioURL = config.customAudioURL
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        hideMonitorOverlay()
        state = .idle
        statusMessage = "已停止监测"
        isColorDetected = false
    }

    private func performCapture() {
        // 从浮窗实时读取位置（用户可能拖动了窗口）
        if let overlay = monitorOverlayWindow {
            config.selectedRect = overlay.frame
        }

        guard let rect = config.selectedRect, rect.width > 0, rect.height > 0 else { return }

        guard let image = captureService.capture(rect: rect) else {
            statusMessage = "截取屏幕失败，请检查屏幕录制权限"
            return
        }

        let found = detectionService.checkForColor(
            in: image,
            targetColor: NSColor(config.targetColor),
            tolerance: config.colorTolerance,
            sampleStep: config.sampleStep,
            minMatchRatio: config.minMatchRatio
        )

        isColorDetected = found
        if found {
            statusMessage = "检测到目标颜色！"
            syncAudioConfig()
            audioService.playAlert()
        } else {
            statusMessage = "监测中..."
            audioService.stopAlert()
        }
    }
}
