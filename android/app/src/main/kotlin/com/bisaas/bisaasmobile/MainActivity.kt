package com.bisaas.bisaasmobile

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Hosts the `security_screen` platform channel (security plan W2.7).
///
/// FLAG_SECURE is applied ONLY while the Flutter side holds the guard open —
/// the official exam runner and premium content readers. It is never set
/// app-wide: blanket FLAG_SECURE breaks legitimate screenshots and
/// accessibility tooling, and a camera defeats it anyway.
class MainActivity : FlutterActivity() {
    private val channelName = "com.bisaas/security_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setFlagSecure" -> {
                        val secure = call.argument<Boolean>("secure") ?: false
                        runOnUiThread {
                            window.apply {
                                if (secure) {
                                    setFlags(
                                        WindowManager.LayoutParams.FLAG_SECURE,
                                        WindowManager.LayoutParams.FLAG_SECURE,
                                    )
                                } else {
                                    clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                                }
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
