# eSIM Guide

給**第一次出國的旅客**使用的 eSIM 安裝教學 App。目標是把 eSIM 的所有麻煩事變簡單：不用看懂術語，照著畫面一步一步做，就能在出國前裝好、落地後順利上網。

> 目前處於早期開發階段。已完成「選擇行程、推薦方案、安裝教學」的基本流程，方案資料為範例資料。

## 為什麼做這個

很多人不常出國，對 eSIM 的疑慮不是「選哪個方案」，而是：

- 怕裝錯，錢花了卻不能用
- 不知道要什麼時候開啟、什麼時候不能開
- 落地後沒有網路，不知道怎麼排查

這個 App 用「依出國時間軸給出下一步」的方式，在對的時間只告訴你現在該做的那一件事。

## 目前功能

- 選擇目的地（日本／韓國／泰國）與旅遊天數
- 依行程推薦最適合的方案，並用白話說明流量大概夠做什麼（目前為範例資料，非真實價格）
- 6 個步驟的 eSIM 安裝教學：確認支援、連 Wi-Fi、掃描 QR Code、命名、先不要開啟、完成
- 左右滑動或按鈕切換步驟，附進度條與每一步的小提醒
- 記住上次選的行程，以及教學看到第幾步，重開 App 會從上次的地方繼續

## 技術

- Flutter / Dart（開發環境為 Flutter 3.47.8 stable）
- 狀態管理：Riverpod（`Notifier`、`FutureProvider`）
- 本地儲存：shared_preferences
- 資料來源：本地 JSON（`assets/steps.json`、`assets/plans.json`）

## 如何執行

需要先安裝 [Flutter](https://docs.flutter.dev/get-started/install)。

```bash
git clone https://github.com/ella618s/esim_guide.git
cd esim_guide
flutter pub get
flutter run -d chrome
```

執行測試：

```bash
flutter test
```

支援平台：Android、iOS、Web。目前已在 Chrome 與 iPhone 實機驗證，Android 實機尚待測試。

> iOS 14 以後，debug 版 App 只能從 Flutter 指令或 Xcode 啟動。若要從手機桌面直接開啟，請改裝 release 版：`flutter run --release`。

## 專案結構

```
esim_guide/
├── lib/
│   ├── main.dart            # App 進入點，設定 Riverpod 與本地儲存
│   ├── models.dart          # 資料模型（教學步驟、方案、行程）與推薦邏輯
│   ├── providers.dart       # 狀態管理：行程、教學進度、資料載入
│   ├── home_page.dart       # 首頁：選擇目的地與天數
│   ├── recommend_page.dart  # 推薦方案頁
│   └── guide_page.dart      # 安裝教學步驟頁
├── assets/
│   ├── steps.json           # 教學步驟內容
│   └── plans.json           # 範例方案資料
├── test/
│   └── widget_test.dart
└── pubspec.yaml
```

## 開發規劃

- [x] 出發前：eSIM 安裝教學步驟頁
- [x] 輸入目的地與天數，推薦適合的方案
- [x] 狀態管理（Riverpod）與本地儲存：記住行程與教學進度
- [x] 落地後：三步驟開啟網路
- [ ] 沒網路時的排查流程
- [ ] 依機型（iOS／各品牌 Android）顯示對應的操作路徑
- [ ] 偵測手機是否支援 eSIM（原生平台整合）
- [ ] 流量用量與到期提醒
- [ ] 串接方案供應商與比價（資料改為網路取得，並處理離線快取）

## 作者

[@ella618s](https://github.com/ella618s)