package com.timerin.app

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "com.timerin.app/vibration"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupVibrationChannel(flutterEngine)

        // Setup channel on overlay engine if already present
        FlutterEngineCache.getInstance().get("myCachedEngine")?.let { cachedEngine ->
            setupVibrationChannel(cachedEngine)
        }
    }

    private fun setupVibrationChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    val durationMs = (call.argument<Int>("durationMs") ?: 2400).toLong()
                    triggerVibrate(durationMs)
                    result.success(true)
                }
                "cancel" -> {
                    cancelVibrate()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun triggerVibrate(durationMs: Long) {
        val vibrator = getVibrator() ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val timings = longArrayOf(0, 500, 150, 500, 150, 500, 150, 500)
            val amplitudes = intArrayOf(0, 255, 0, 255, 0, 255, 0, 255)
            val effect = VibrationEffect.createWaveform(timings, amplitudes, -1)
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            val timings = longArrayOf(0, 500, 150, 500, 150, 500, 150, 500)
            @Suppress("DEPRECATION")
            vibrator.vibrate(timings, -1)
        }
    }

    private fun cancelVibrate() {
        getVibrator()?.cancel()
    }
}
