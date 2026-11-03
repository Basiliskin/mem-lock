package com.leavecheck.probe.wifi_probe

import android.content.Context
import android.net.wifi.WifiManager
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Raw Wi-Fi readings. Names and addresses are hidden on the Dart side before logging. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "probe/wifi")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        // False when Android throttles scans (4 per 2 minutes by default).
                        @Suppress("DEPRECATION")
                        "startScan" -> result.success(wifi.startScan())
                        "scanResults" -> {
                            val now = SystemClock.elapsedRealtime() * 1000
                            result.success(wifi.scanResults.map {
                                @Suppress("DEPRECATION")
                                mapOf(
                                    "bssid" to it.BSSID,
                                    "ssid" to it.SSID,
                                    "rssi" to it.level,
                                    "mhz" to it.frequency,
                                    "ageMs" to (now - it.timestamp) / 1000,
                                )
                            })
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    result.error("permission", e.message, null)
                }
            }
    }
}
