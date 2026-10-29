# eSIM Guide

給**第一次出國的旅客**使用的 eSIM 安裝教學 App。目標是把 eSIM 的所有麻煩事變簡單：不用看懂術語，照著畫面一步一步做，就能在出國前裝好、落地後順利上網。

> 目前處於早期開發階段（第 1 週），只完成「出發前安裝教學」的第一個畫面流程。

## 為什麼做這個

很多人不常出國，對 eSIM 的疑慮不是「選哪個方案」，而是：

- 怕裝錯，錢花了卻不能用
- 不知道要什麼時候開啟、什麼時候不能開
- 落地後沒有網路，不知道怎麼排查

這個 App 用「依出國時間軸給出下一步」的方式，在對的時間只告訴你現在該做的那一件事。

## 目前功能

- 6 個步驟的 eSIM 安裝教學（確認支援、連 Wi-Fi、掃描 QR Code、命名、先不要開啟、完成）
- 左右滑動或按鈕切換步驟
- 頂端進度條與「第 X 步，共 Y 步」提示
- 每一步附上小提醒
- 教學內容放在 `assets/steps.json`，修改文字不需要動程式

## 技術

- Flutter / Dart（開發環境為 Flutter 3.47.8 stable）
- 資料來源：本地 JSON（`assets/steps.json`）
- 狀態管理：目前使用 `setState`，之後會導入 Riverpod

## 如何執行

需要先安裝 [Flutter](https://docs.flutter.dev/get-started/install)。

```bash
git clone https://github.com/ella618s/esim_guide.git
cd esim_guide
flutter pub get
flutter run -d chrome
```

支援平台：Android、iOS、Web。目前主要在 Chrome 上驗證，Android／iOS 實機測試尚待進行。

## 專案結構

```
esim_guide/
├── lib/
│   └── main.dart        # App 進入點與安裝教學頁
├── assets/
│   └── steps.json       # 教學步驟內容
├── pubspec.yaml         # 套件與資源設定
└── test/
```

## 開發規劃

- [x] 出發前：eSIM 安裝教學步驟頁
- [x] 輸入目的地與天數，推薦適合的方案
- [ ] 狀態管理（Riverpod）與本地儲存，離線也能看教學
- [ ] 落地後：三步驟開啟網路
- [ ] 沒網路時的排查流程
- [ ] 依機型（iOS／各品牌 Android）顯示對應的操作路徑
- [ ] 偵測手機是否支援 eSIM（原生平台整合）
- [ ] 流量用量與到期提醒
- [ ] 串接方案供應商與比價

## 作者

[@ella618s](https://github.com/ella618s)