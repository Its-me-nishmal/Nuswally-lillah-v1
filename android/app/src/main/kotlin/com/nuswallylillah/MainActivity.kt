package com.nuswallylillah

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.nuswallylillah/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
                val intent = Intent(this, PrayerWidgetProvider::class.java).apply {
                    action = PrayerWidgetProvider.ACTION_UPDATE_PRAYER_WIDGET
                }
                sendBroadcast(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
