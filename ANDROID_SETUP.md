# Android 設定（尚未實測）

`flutter_local_notifications` 要求 Android 端做幾項設定，**沒做的話 Android 會編譯失敗**。
iOS 不受影響，所以你用 iPhone 測試時可以先不做。
這些是我依套件官方文件整理的，沒有 Android 實機也沒有跑過，請當作草稿。

套件要求（22.x）：Flutter 3.38.1 以上、AGP 8.11.1 以上、Java 17、compileSdk 35 以上、
開啟 core library desugaring。

## 1. android/app/build.gradle(.kts)

先看你的檔案是 `build.gradle.kts`（Kotlin）還是 `build.gradle`（Groovy）。

### Kotlin 版（.kts）

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    defaultConfig {
        multiDexEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Groovy 版

```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

已經有 `compileOptions`、`kotlinOptions`、`dependencies` 區塊就把內容合併進去，不要重複建立。

## 2. android/app/src/main/AndroidManifest.xml

在 `<manifest>` 裡、`<application>` 前面加：

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

在 `<application>` 裡面（`<activity>` 後面）加：

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

通知權限（`POST_NOTIFICATIONS`）套件已經自己宣告，不用另外加。
這個 App 用「不精準」的排程模式，所以**不需要**宣告 `SCHEDULE_EXACT_ALARM`。

## 3. 驗證

```bash
flutter build apk --debug
```

能成功編譯才算過。Android Studio 2024.2.1（Ladybug）比 AGP 8.11 舊，
用 Android Studio 直接開 `android/` 資料夾可能會要求升級，用 `flutter` 指令建置則不受影響。
