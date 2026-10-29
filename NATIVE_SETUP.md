# 原生程式設定（第 7 週）

Dart 端用 `MethodChannel('com.example.esim_guide/esim')` 呼叫原生的 `isEsimSupported`。
Android 和 iOS 各要加一小段程式。**沒設定也不會當掉**，畫面只會顯示「沒辦法自動判斷」。

## Android

`android/app/src/main/kotlin/com/example/esim_guide/MainActivity.kt` 已經放在壓縮檔裡，直接覆蓋原本的檔案即可。

覆蓋前先確認兩件事：
1. 原本的檔案路徑是否一致：`ls android/app/src/main/kotlin/com/example/esim_guide/`
2. 原本檔案第一行的 `package` 是否是 `com.example.esim_guide`。如果不一樣，把新檔案第一行改成原本的。

## iOS

Swift 的檔案要加進 Xcode 專案才會被編譯，用解壓縮的方式放檔案進去不會生效。
所以 iOS 這邊改成**直接編輯現有的 `ios/Runner/AppDelegate.swift`**。

### 步驟 1：在 AppDelegate.swift 最上面加入

```swift
import CoreTelephony
```

### 步驟 2：在檔案最下面（最後一個大括號之後）加入

```swift
/// 註冊「這支手機支援 eSIM 嗎？」的管道，名稱要和 Dart 端完全一樣
private func registerEsimChannel(messenger: FlutterBinaryMessenger) {
  let channel = FlutterMethodChannel(
    name: "com.example.esim_guide/esim",
    binaryMessenger: messenger
  )
  channel.setMethodCallHandler { call, result in
    switch call.method {
    case "isEsimSupported":
      // 只能查出手機「支援」，查不出有沒有被電信公司鎖住
      result(CTCellularPlanProvisioning().supportsCellularPlan())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

### 步驟 3：在 AppDelegate 裡呼叫它（依你的檔案長相二選一）

**情況 A：檔案裡有 `didInitializeImplicitFlutterEngine`**（新版專案範本）

在這個函式裡，`GeneratedPluginRegistrant.register(...)` 那一行的下面加一行：

```swift
registerEsimChannel(messenger: engineBridge.applicationRegistrar.messenger())
```

**情況 B：檔案裡有 `didFinishLaunchingWithOptions`，沒有上面那個函式**（舊版範本）

在 `GeneratedPluginRegistrant.register(with: self)` 的下面、`return super.application(...)` 的上面加：

```swift
if let controller = window?.rootViewController as? FlutterViewController {
  registerEsimChannel(messenger: controller.binaryMessenger)
}
```

兩種都不像的話，把你的 `AppDelegate.swift` 全部內容貼給我，我幫你改。

## 測試

- **iPhone 實機**：應該顯示「你的手機支援 eSIM」（iPhone XS／XR 以後的機型）。
- **iOS 模擬器**：永遠會顯示不支援，這是正常的，模擬器沒有 eSIM。
- **Android 實機**：支援 eSIM 的手機顯示支援。
- **Android 模擬器**：通常會顯示不支援。
- **Chrome（網頁版）**：顯示「沒辦法自動判斷」。
