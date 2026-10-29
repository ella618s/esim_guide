package com.example.esim_guide

import android.content.Context
import android.os.Build
import android.telephony.euicc.EuiccManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 這個名稱要和 Dart 端 lib/esim_support.dart 裡的完全一樣
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEsimSupported" -> result.success(isEsimSupported())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * EuiccManager 從 Android 9（API 28）才有。
     * isEnabled 為 true 代表：手機有 eSIM 晶片，而且這個功能是開啟的。
     * 注意：它不會告訴我們手機有沒有被電信公司鎖住。
     */
    private fun isEsimSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val manager = getSystemService(Context.EUICC_SERVICE) as? EuiccManager
        return manager?.isEnabled == true
    }

    companion object {
        private const val CHANNEL = "com.example.esim_guide/esim"
    }
}
