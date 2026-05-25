import AppKit
import CoreGraphics

final class RegionSelectionView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    var onSelectionCancelled: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
        }

        guard let start = startPoint, let end = currentPoint else { return }

        let rect = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        if rect.width > 15, rect.height > 15 {
            onSelectionComplete?(rect)
        } else {
            onSelectionCancelled?()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            onSelectionCancelled?()
        } else {
            super.keyDown(with: event)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let start = startPoint, let current = currentPoint else { return }

        let selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        // punch a clear hole for the selection area
        if let ctx = NSGraphicsContext.current {
            ctx.compositingOperation = .copy
            NSColor.clear.setFill()
            selectionRect.fill()
            ctx.compositingOperation = .sourceOver
        }

        // draw selection border
        NSColor.white.setStroke()
        let path = NSBezierPath(rect: selectionRect)
        path.lineWidth = 2.0
        path.stroke()

        // draw size label
        let label = "\(Int(selectionRect.width)) × \(Int(selectionRect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let labelSize = label.size(withAttributes: attributes)
        let labelOrigin = NSPoint(
            x: selectionRect.origin.x + 6,
            y: selectionRect.origin.y - labelSize.height - 6
        )
        // keep label inside the selection if possible
        let adjustedY = labelOrigin.y < 4
            ? selectionRect.origin.y + selectionRect.height + 4
            : labelOrigin.y
        label.draw(at: NSPoint(x: labelOrigin.x, y: adjustedY), withAttributes: attributes)
    }
}
