import Flutter
import UIKit

enum FromFlutter: String {
  case checkMemory
  case startAccessingSecurityScopedResource
  case stopAccessingSecurityScopedResource
  case getSystemFonts
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "channel",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler {
      (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self.handleFlutterCall(call, result, channel)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func handleFlutterCall(
    _ call: FlutterMethodCall,
    _ result: @escaping FlutterResult,
    _: FlutterMethodChannel
  ) {
    let method = FromFlutter(rawValue: call.method)
    let arguments = call.arguments

    switch method {
    case .checkMemory:
      do {
        let (mem_used, mem_free) = try checkMemory()
        result([mem_used, mem_free])
      } catch {
        result(FlutterError(code: "-1", message: "Failed to check memory", details: error))
      }
    case .startAccessingSecurityScopedResource:
      if let path = arguments as? String {
        let url = URL(fileURLWithPath: path)
        let success = url.startAccessingSecurityScopedResource()
        result(success)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
      }
    case .stopAccessingSecurityScopedResource:
      if let path = arguments as? String {
        let url = URL(fileURLWithPath: path)
        url.stopAccessingSecurityScopedResource()
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
      }
    case .getSystemFonts:
      let fonts = self.getSystemFonts()
      result(fonts)
    default: result(FlutterMethodNotImplemented)
    }
  }
}

func checkMemory() throws -> (Int64, Int64) {
  var pagesize: vm_size_t = 0
  let host_port: mach_port_t = mach_host_self()
  var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)

  guard host_page_size(host_port, &pagesize) == KERN_SUCCESS else {
    throw NSError(domain: "MemoryCheck", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get page size"])
  }

  var vm_stat = vm_statistics_data_t()
  var retval = withUnsafeMutablePointer(to: &vm_stat) {
    $0.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
      host_statistics(host_port, HOST_VM_INFO, $0, &host_size)
    }
  }

  guard retval == KERN_SUCCESS else {
    let errorMsg = String(format: "Failed to get VM stats: 0x%08x", retval)
    throw NSError(domain: "MemoryCheck", code: Int(retval), userInfo: [NSLocalizedDescriptionKey: errorMsg])
  }

  let mem_used = Int64(vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * Int64(pagesize)
  let mem_free = Int64(vm_stat.free_count) * Int64(pagesize)

  return (mem_used, mem_free)
}

extension AppDelegate {
  private func getSystemFonts() -> [[String: Any]] {
    var fontInfoList: [[String: Any]] = []
    var processedFonts = Set<String>()
    
    // Get all font family names
    for family in UIFont.familyNames {
      // Also get individual font names within each family
      for fontName in UIFont.fontNames(forFamilyName: family) {
        if processedFonts.contains(fontName) {
          continue
        }
        processedFonts.insert(fontName)
        
        // 创建字体实例来检查是否为等宽字体
        if let font = UIFont(name: fontName, size: 12) {
          // 在 iOS 上，通过测量字符宽度来判断是否为等宽字体
          let isMonospace = isFontMonospace(font: font)
          fontInfoList.append([
            "name": fontName,
            "isMonospace": isMonospace
          ])
        } else {
          // 如果无法创建字体，使用字体名称推断
          let isMonospace = inferMonospaceFromName(fontName)
          fontInfoList.append([
            "name": fontName,
            "isMonospace": isMonospace
          ])
        }
      }
    }
    
    // Add system default fonts
    let systemFonts = ["System", "San Francisco"]
    for fontName in systemFonts {
      if !processedFonts.contains(fontName) {
        let isMonospace = inferMonospaceFromName(fontName)
        fontInfoList.append([
          "name": fontName,
          "isMonospace": isMonospace
        ])
        processedFonts.insert(fontName)
      }
    }
    
    // 按名称排序
    fontInfoList.sort { ($0["name"] as! String) < ($1["name"] as! String) }
    
    return fontInfoList
  }
  
  // 检测字体是否为等宽字体（通过测量字符宽度）
  private func isFontMonospace(font: UIFont) -> Bool {
    // 测量几个不同字符的宽度
    let testChars = ["i", "m", "W", "0"]
    var widths: [CGFloat] = []
    
    for char in testChars {
      let size = char.size(withAttributes: [.font: font])
      widths.append(size.width)
    }
    
    // 如果所有字符宽度相同（允许很小的误差），则为等宽字体
    if widths.count > 1 {
      let firstWidth = widths[0]
      for width in widths {
        if abs(width - firstWidth) > 0.1 {
          return false
        }
      }
      return true
    }
    return false
  }
  
  // 辅助方法：从字体名称推断是否为等宽字体（作为后备方案）
  private func inferMonospaceFromName(_ fontName: String) -> Bool {
    let lowerName = fontName.lowercased()
    return lowerName.contains("mono") ||
           lowerName.contains("courier") ||
           lowerName == "monospace" ||
           lowerName.contains("console") ||
           lowerName.contains("terminal") ||
           lowerName.contains("code") ||
           lowerName.contains("menlo") ||
           lowerName.contains("consolas")
  }
}
