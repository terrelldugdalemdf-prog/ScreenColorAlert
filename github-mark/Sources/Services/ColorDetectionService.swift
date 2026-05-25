import Cocoa
import CoreGraphics

final class ColorDetectionService {
    func checkForColor(
        in image: CGImage,
        targetColor: NSColor,
        tolerance: Double,
        sampleStep: Int,
        minMatchRatio: Double = 0.05
    ) -> Bool {
        guard let targetRGB = targetColor.usingColorSpace(.deviceRGB) else { return false }

        let targetR = Double(targetRGB.redComponent)
        let targetG = Double(targetRGB.greenComponent)
        let targetB = Double(targetRGB.blueComponent)

        guard let data = pixelData(from: image) else { return false }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bytesPerPixel = image.bitsPerPixel / 8
        let step = max(sampleStep, 1)

        var totalChecked = 0
        var totalMatched = 0

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                guard offset + 2 < data.count else { continue }

                totalChecked += 1

                let r = Double(data[offset]) / 255.0
                let g = Double(data[offset + 1]) / 255.0
                let b = Double(data[offset + 2]) / 255.0

                if abs(r - targetR) <= tolerance,
                   abs(g - targetG) <= tolerance,
                   abs(b - targetB) <= tolerance {
                    totalMatched += 1
                }
            }
        }

        guard totalChecked > 0 else { return false }
        let ratio = Double(totalMatched) / Double(totalChecked)
        return ratio >= minMatchRatio
    }

    private func pixelData(from image: CGImage) -> Data? {
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data else { return nil }
        return Data(bytes: CFDataGetBytePtr(data), count: CFDataGetLength(data))
    }
}
