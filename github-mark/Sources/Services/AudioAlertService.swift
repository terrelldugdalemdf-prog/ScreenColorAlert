import AVFoundation
import AppKit

final class AudioAlertService {
    var volume: Float = 0.8
    var customAudioURL: URL?

    private var player: AVAudioPlayer?
    private var lastAlertTime: Date = .distantPast
    private let throttleInterval: TimeInterval = 1.5
    private var pendingWorkItems: [DispatchWorkItem] = []

    func playAlert() {
        let now = Date()
        guard now.timeIntervalSince(lastAlertTime) >= throttleInterval else { return }
        lastAlertTime = now

        cancelPendingBeeps()

        for delay in [0.0, 0.25, 0.5] {
            let item = DispatchWorkItem { [weak self] in
                self?.playBeep()
            }
            pendingWorkItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
    }

    func stopAlert() {
        cancelPendingBeeps()
        player?.stop()
    }

    private func cancelPendingBeeps() {
        for item in pendingWorkItems {
            item.cancel()
        }
        pendingWorkItems.removeAll()
    }

    private func playBeep() {
        if let url = customAudioURL,
           FileManager.default.fileExists(atPath: url.path),
           let p = try? AVAudioPlayer(contentsOf: url) {
            player = p
        } else {
            player = makeBeepPlayer()
        }
        player?.volume = volume
        player?.play()
    }

    private func makeBeepPlayer() -> AVAudioPlayer? {
        let sampleRate = 44100
        let duration: Float = 0.12
        let frequency: Float = 880
        let numSamples = Int(Float(sampleRate) * duration)

        var samples = [Int16](repeating: 0, count: numSamples)
        for i in 0..<numSamples {
            let t = Float(i) / Float(sampleRate)
            let envelope: Float = 1.0 - (Float(i) / Float(numSamples))
            let value = sin(2.0 * .pi * frequency * t) * envelope * 0.6
            samples[i] = Int16(value * Float(Int16.max))
        }

        let dataSize = numSamples * 2
        var wav = Data()
        wav.append(contentsOf: "RIFF".utf8)
        wav.append(uint32: UInt32(36 + dataSize))
        wav.append(contentsOf: "WAVE".utf8)

        wav.append(contentsOf: "fmt ".utf8)
        wav.append(uint32: 16)
        wav.append(uint16: 1)
        wav.append(uint16: 1)
        wav.append(uint32: UInt32(sampleRate))
        wav.append(uint32: UInt32(sampleRate * 2))
        wav.append(uint16: 2)
        wav.append(uint16: 16)

        wav.append(contentsOf: "data".utf8)
        wav.append(uint32: UInt32(dataSize))
        wav.append(contentsOf: samples.withUnsafeBytes { Data($0) })

        return try? AVAudioPlayer(data: wav)
    }
}

private extension Data {
    mutating func append(uint16 value: UInt16) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 2))
    }

    mutating func append(uint32 value: UInt32) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 4))
    }
}
