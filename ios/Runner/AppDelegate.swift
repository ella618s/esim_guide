import Flutter
import UIKit
import CoreTelephony
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 讓本機通知（到期提醒）在 App 開著的時候也能顯示
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "EsimSupportChannel") {
      EsimSupportChannel.register(with: registrar)
    }
  }
}

/// 原生端只回報「事實」，要不要算支援交給 Dart 判斷（比較好測試）。
/// 為了不用改 Xcode 專案檔，這個類別直接放在 AppDelegate.swift 裡。
final class EsimSupportChannel {
  static let name = "com.example.esim_guide/esim"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getEsimFacts":
        result(collectFacts())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func collectFacts() -> [String: Any] {
    var isSimulator = false
    #if targetEnvironment(simulator)
    isSimulator = true
    #endif

    // 官方 API：只開放給電信業者的 App（需要特殊 entitlement）。
    // 一般 App 呼叫通常回 false，就算手機有 eSIM 也一樣。
    // 這裡仍然記錄下來，純粹拿來實驗與驗證，不參與判斷。
    let apiSupportsCellularPlan = CTCellularPlanProvisioning().supportsCellularPlan()

    return [
      "model": modelIdentifier(),
      "systemVersion": UIDevice.current.systemVersion,
      "isSimulator": isSimulator,
      "apiSupportsCellularPlan": apiSupportsCellularPlan,
    ]
  }

  /// 機型代號，例如 iPhone14,6（iPhone SE 第 3 代）
  private static func modelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    return mirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
  }
}
