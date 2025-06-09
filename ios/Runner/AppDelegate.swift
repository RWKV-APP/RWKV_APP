import Flutter
import UIKit

enum FromFlutter: String {
  case checkMemory
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
