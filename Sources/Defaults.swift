import Cocoa
import Carbon

// Grid size, inter-window gap, four screen-edge insets, shortcuts, target rule, and presets live in UserDefaults.
let defaults: UserDefaults = {
    let d = UserDefaults.standard
    let fullScreen = Preset(name: "Full screen", x: 0, y: 0, w: 1, h: 1, keyCode: kVK_ANSI_F, keyMods: optionKey | controlKey, keyLabel: "⌃⌥F")
    let oldEdge = max((d.object(forKey: "gap") as? NSNumber)?.doubleValue ?? 0, 0)
    for key in ["edgeLeft", "edgeRight", "edgeTop", "edgeBottom"] where d.object(forKey: key) == nil {
        d.set(oldEdge, forKey: key)   // Each new edge inherits the old gap once, preserving the previous uniform layout.
    }
    d.register(defaults: ["cols": 12, "rows": 8, "gap": 0, "presets": try! JSONEncoder().encode([fullScreen])])
    return d
}()
var cols: Int { min(max(defaults.integer(forKey: "cols"), 1), 24) }
var rows: Int { min(max(defaults.integer(forKey: "rows"), 1), 24) }
