import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// 偵測結果有三種，不是只有「是／否」：
/// 沒辦法判斷（例如在網頁版、桌面版，或原生程式還沒設定）時，要誠實說「不知道」，
/// 不能直接當成「不支援」嚇到使用者。
enum EsimSupport { supported, unsupported, unknown }

/// 和原生程式（Android 的 Kotlin、iOS 的 Swift）溝通的管道。
/// 名稱要和 MainActivity.kt、AppDelegate.swift 裡的完全一樣。
const _channel = MethodChannel('com.example.esim_guide/esim');

/// 問原生程式：這支手機支援 eSIM 嗎？
///
/// 原生那邊只回答 true／false，這裡再轉成三種結果。
/// 任何出錯的情況（網頁版、沒有設定原生程式、原生程式丟出錯誤）都回傳 unknown。
Future<EsimSupport> checkEsimSupport() async {
  if (kIsWeb) return EsimSupport.unknown;

  try {
    final result = await _channel.invokeMethod<bool>('isEsimSupported');
    if (result == null) return EsimSupport.unknown;
    return result ? EsimSupport.supported : EsimSupport.unsupported;
  } on MissingPluginException {
    // 這個平台沒有實作這個方法（網頁、桌面，或原生程式碼還沒加）
    return EsimSupport.unknown;
  } on PlatformException {
    return EsimSupport.unknown;
  }
}
