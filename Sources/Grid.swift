import Cocoa

final class GridView: NSView {
    var start: (Int, Int)?, end: (Int, Int)?
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }

    var grid: NSRect { bounds.insetBy(dx: 10, dy: 10) }
    func cell(_ e: NSEvent) -> (Int, Int) {
        let p = convert(e.locationInWindow, from: nil)
        return (min(max(Int((p.x - grid.minX) / grid.width * CGFloat(cols)), 0), cols - 1),
                min(max(Int((p.y - grid.minY) / grid.height * CGFloat(rows)), 0), rows - 1))
    }
    var selection: (x: ClosedRange<Int>, y: ClosedRange<Int>)? {
        guard let s = start, let e = end else { return nil }
        return (min(s.0, e.0)...max(s.0, e.0), min(s.1, e.1)...max(s.1, e.1))
    }
    var selectionFraction: NSRect? {
        guard let s = selection else { return nil }
        return NSRect(x: Double(s.x.lowerBound) / Double(cols), y: Double(s.y.lowerBound) / Double(rows),
                      width: Double(s.x.count) / Double(cols), height: Double(s.y.count) / Double(rows))
    }

    var ghosts: [NSRect] = []
    var original: (CGPoint, CGSize)?   // window frame at mouse-down, restored on cancel
    var selectionFrame: NSRect? { selectionFraction.map { screenFrame(fraction: $0, on: targetScreen) } }
    func preview() {   // live: the window follows the selection and snaps back when there is none
        guard let win = targetWindow else { return }
        if let r = selectionFrame { applyFrame(win, r) } else if let o = original { axSet(win, o.0, o.1) }
    }

    override func mouseDown(with e: NSEvent) {
        original = targetWindow.flatMap(axFrame)
        start = cell(e); end = start; needsDisplay = true   // no preview yet: one cell is a tiny window, wait for the drag
    }
    func track(_ e: NSEvent) {   // cursor outside the panel = no selection, so releasing there cancels
        let new = bounds.contains(convert(e.locationInWindow, from: nil)) ? cell(e) : nil
        guard new?.0 != end?.0 || new?.1 != end?.1 else { return }   // only hit AX when the cell changes
        end = new; needsDisplay = true; preview()
    }
    override func mouseDragged(with e: NSEvent) { track(e) }
    override func mouseUp(with e: NSEvent) {
        track(e); preview()   // a plain click never dragged, so apply here
        if selection != nil, let w = targetWindow { remember(w); if let o = original { lastSnap = (w, o.0, o.1) } }
        let save = (e.modifierFlags.contains(.shift) || recordMode) ? selectionFraction : nil   // shift-release saves a preset
        hideGrid()
        if let f = save { newPreset(f) }
    }
    override func keyDown(with e: NSEvent) { if e.keyCode == 53 { start = nil; end = nil; preview(); hideGrid() } } // esc, also mid-drag

    override func draw(_ dirty: NSRect) {
        guard !grid.isEmpty else { return }   // layer-backed views get drawn at zero size before the panel is shown
        let cw = grid.width / CGFloat(cols), ch = grid.height / CGFloat(rows)
        // extra gap at boundary i of n: halves widest, thirds/quarters narrower, everything else uniform
        func gap(_ i: Int, _ n: Int) -> CGFloat {
            i == 0 || i == n ? 0 : (i * 2) % n == 0 ? 3 : (i * 3) % n == 0 || (i * 4) % n == 0 ? 1.5 : 0
        }
        func edge(_ c: CGFloat, _ n: Int, _ size: CGFloat, _ tol: CGFloat, _ sign: CGFloat) -> CGFloat {
            let i = c.rounded()
            return abs(c - i) <= tol ? i * size + sign * (2 + gap(Int(i), n)) : c * size
        }
        func path(_ r: NSRect, tolX: CGFloat = 0, tolY: CGFloat = 0) -> NSBezierPath {
            let x0 = grid.minX + edge(r.minX, cols, cw, tolX, 1), x1 = grid.minX + edge(r.maxX, cols, cw, tolX, -1)
            let y0 = grid.minY + edge(r.minY, rows, ch, tolY, 1), y1 = grid.minY + edge(r.maxY, rows, ch, tolY, -1)
            return NSBezierPath(roundedRect: NSRect(x: x0, y: y0, width: max(x1 - x0, 0), height: max(y1 - y0, 0)), xRadius: 4, yRadius: 4)
        }
        func rect(_ x: ClosedRange<Int>, _ y: ClosedRange<Int>) -> NSBezierPath {
            path(NSRect(x: x.lowerBound, y: y.lowerBound, width: x.count, height: y.count))
        }
        for x in 0..<cols { for y in 0..<rows {
            let p = rect(x...x, y...y)
            NSColor.white.withAlphaComponent(0.10).setFill(); p.fill()
            NSColor.white.withAlphaComponent(0.20).setStroke(); p.stroke()
        }}
        let v = targetScreen.visibleFrame, c = CGFloat(cols), r = CGFloat(rows)
        for u in ghosts {
            let p = path(NSRect(x: u.minX * c, y: u.minY * r, width: u.width * c, height: u.height * r), tolX: 2 * c / v.width, tolY: 2 * r / v.height)
            NSColor.white.withAlphaComponent(0.25).setFill(); p.fill()
            NSColor.white.withAlphaComponent(0.45).setStroke(); p.stroke()
        }
        if let s = selection {
            let p = rect(s.x, s.y)
            NSColor.controlAccentColor.withAlphaComponent(0.85).setFill(); p.fill()
            NSColor.white.withAlphaComponent(0.7).setStroke(); p.lineWidth = 1.5; p.stroke()
        }
    }
}

final class Panel: NSPanel { override var canBecomeKey: Bool { true } }

let view = GridView()
let panel: Panel = {
    let panel = Panel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    let glass: NSView
    if #available(macOS 26, *) {
        let g = NSGlassEffectView(); g.cornerRadius = 18; g.contentView = view; glass = g
        g.wantsLayer = true; g.layer?.cornerRadius = 18; g.layer?.masksToBounds = true  // clip the backdrop too
    } else {
        let v = NSVisualEffectView(); v.material = .hudWindow; v.state = .active
        v.wantsLayer = true; v.layer?.cornerRadius = 18; v.addSubview(view); glass = v
    }
    panel.contentView = glass
    panel.appearance = NSAppearance(named: .darkAqua)
    panel.hasShadow = false  // a shadow is computed on the square bounds and leaks through the corners
    panel.level = .floating
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hidesOnDeactivate = false
    panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
    return panel
}()

func showGrid() {
    targetWindow = recordMode ? nil : pickTarget()   // before the panel appears; record mode moves nothing
    targetScreen = screenUnderCursor()
    view.ghosts = ghostFractions(on: targetScreen)
    view.start = nil; view.end = nil; view.original = nil; view.needsDisplay = true
    let f = targetScreen.visibleFrame, w: CGFloat = 480, h = w * f.height / f.width
    panel.setFrame(NSRect(x: f.midX - w / 2, y: f.midY - h / 2, width: w, height: h), display: true)
    view.frame = panel.contentView!.bounds
    panel.alphaValue = 0
    panel.makeKeyAndOrderFront(nil)
    panel.makeFirstResponder(view)
    NSAnimationContext.runAnimationGroup { $0.duration = 0.12; panel.animator().alphaValue = 1 }
}
func hideGrid() {
    recordMode = false
    NSAnimationContext.runAnimationGroup({ $0.duration = 0.10; panel.animator().alphaValue = 0 }) { panel.orderOut(nil) }
}
