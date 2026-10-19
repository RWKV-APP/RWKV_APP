import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var inferenceActivity: NSObjectProtocol?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Set window title to display name with space
    self.title = "RWKV Chat"

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(name: "channel", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setInferenceActive" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let active = call.arguments as? Bool else {
        result(FlutterError(code: "invalid_arguments", message: "Expected an active flag", details: nil))
        return
      }
      self?.setInferenceActive(active)
      result(nil)
    }

    super.awakeFromNib()
  }

  private func setInferenceActive(_ active: Bool) {
    if active {
      if inferenceActivity == nil {
        inferenceActivity = ProcessInfo.processInfo.beginActivity(
          options: .userInitiatedAllowingIdleSystemSleep,
          reason: "RWKV model loading or generation")
      }
      return
    }
    guard let activity = inferenceActivity else { return }
    inferenceActivity = nil
    ProcessInfo.processInfo.endActivity(activity)
  }

  deinit {
    if let activity = inferenceActivity {
      ProcessInfo.processInfo.endActivity(activity)
    }
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
