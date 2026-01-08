import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Update menu bar items to use display name with space
    let displayName = "RWKV Chat"
    if let mainMenu = NSApplication.shared.mainMenu {
      // Update main menu item (Apple menu)
      if let appMenu = mainMenu.item(at: 0) {
        appMenu.title = displayName
        
        // Update submenu items
        if let submenu = appMenu.submenu {
          for item in submenu.items {
            let title = item.title
            // Replace RWKV_Chat with RWKV Chat in menu items
            if title.contains("RWKV_Chat") {
              item.title = title.replacingOccurrences(of: "RWKV_Chat", with: displayName)
            }
          }
        }
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
