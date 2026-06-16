package com.example.yuugao

import android.content.Context
import android.net.wifi.WifiManager
import android.os.PowerManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.yuugao/platform"

    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireWifiLock" -> {
                    try {
                        if (wifiLock == null) {
                            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            wifiLock = wifiManager.createWifiLock(
                                WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                                "yuugao:wifi_lock"
                            )
                            wifiLock?.setReferenceCounted(false)
                        }
                        wifiLock?.acquire()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "releaseWifiLock" -> {
                    try {
                        wifiLock?.release()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "acquireWakeLock" -> {
                    try {
                        if (wakeLock == null) {
                            val powerManager = applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
                            wakeLock = powerManager.newWakeLock(
                                PowerManager.PARTIAL_WAKE_LOCK,
                                "yuugao:cpu_lock"
                            )
                            wakeLock?.setReferenceCounted(false)
                        }
                        wakeLock?.acquire()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "releaseWakeLock" -> {
                    try {
                        wakeLock?.release()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            wifiLock?.release()
            wakeLock?.release()
        } catch (_: Exception) {}
    }
}
