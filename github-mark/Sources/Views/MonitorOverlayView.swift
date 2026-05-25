import AppKit

final class MonitorOverlayView: NSView {
    var borderColor: NSColor = .systemRed

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 半透明填充
        borderColor.withAlphaComponent(0.08).setFill()
        bounds.fill()

        // 边框
        borderColor.withAlphaComponent(0.7).setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 1, dy: 1))
        path.lineWidth = 3.0
        path.stroke()

        // 四角加粗标记
        let cornerLen: CGFloat = 12.0
        let lw: CGFloat = 3.0
        borderColor.withAlphaComponent(0.9).setStroke()

        let corners: [(NSPoint, NSPoint, NSPoint, NSPoint)] = [
            // 左上
            (NSPoint(x: 0, y: bounds.height - cornerLen),
             NSPoint(x: 0, y: bounds.height),
             NSPoint(x: 0, y: bounds.height),
             NSPoint(x: cornerLen, y: bounds.height)),
            // 右上
            (NSPoint(x: bounds.width - cornerLen, y: bounds.height),
             NSPoint(x: bounds.width, y: bounds.height),
             NSPoint(x: bounds.width, y: bounds.height),
             NSPoint(x: bounds.width, y: bounds.height - cornerLen)),
            // 左下
            (NSPoint(x: 0, y: cornerLen),
             NSPoint(x: 0, y: 0),
             NSPoint(x: 0, y: 0),
             NSPoint(x: cornerLen, y: 0)),
            // 右下
            (NSPoint(x: bounds.width - cornerLen, y: 0),
             NSPoint(x: bounds.width, y: 0),
             NSPoint(x: bounds.width, y: 0),
             NSPoint(x: bounds.width, y: cornerLen)),
        ]

        for (h1, h2, v1, v2) in corners {
            let hLine = NSBezierPath()
            hLine.move(to: h1)
            hLine.line(to: h2)
            hLine.lineWidth = lw
            hLine.stroke()

            let vLine = NSBezierPath()
            vLine.move(to: v1)
            vLine.line(to: v2)
            vLine.lineWidth = lw
            vLine.stroke()
        }
    }
}
