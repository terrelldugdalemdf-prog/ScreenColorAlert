import SwiftUI
import CoreGraphics

struct MonitorConfig {
    var selectedRect: CGRect?
    // 默认红色取自 test.png 精确采样值：RGB(55,13,9)
    var targetColor: Color = Color(red: 55.0 / 255.0, green: 13.0 / 255.0, blue: 9.0 / 255.0)
    var colorTolerance: Double = 0.08
    var sampleStep: Int = 4
    var minMatchRatio: Double = 0.05
    var alertVolume: Double = 0.8
    var customAudioURL: URL?
    var customAudioName: String?
}

enum MonitorState {
    case idle
    case selecting
    case monitoring
}
