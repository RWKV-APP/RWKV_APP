import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Set window title to display name with space
    self.title = "RWKV Chat"

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    let isCommandPressed = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
    if !isCommandPressed {
      return super.performKeyEquivalent(with: event)
    }

    let key = event.charactersIgnoringModifiers?.lowercased()
    if key != "q" {
      return super.performKeyEquivalent(with: event)
    }

    NSApplication.shared.terminate(nil)
    return true
  }
}
