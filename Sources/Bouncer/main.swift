import AppKit

// NSApplication keeps only a weak reference to its delegate, so this top-level
// constant is what keeps the delegate alive for the life of the process.
let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.run()
