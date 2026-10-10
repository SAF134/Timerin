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
        const val OVERLAY_ENGINE_ID = "myCachedEngine"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupVibrationChannel(flutterEngine)
        attachVibrationChannelToOverlayEngine()
    }

    override fun onResume() {
        super.onResume()
        attachVibrationChannelToOverlayEngine()
    }

    override fun onStart() {
        super.onStart()
        attachVibrationChannelToOverlayEngine()
    }

    private fun attachVibrationChannelToOverlayEngine() {
        FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_ID)?.let { cachedEngine ->
            setupVibrationChannel(cachedEngine)
        }
    }

    private fun setupVibrationChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    val durationMs = (call.argument<Int>("durationMs") ?: 1000).toLong()
                    triggerVibrate(durationMs)
                    result.success(true)
                }
                "cancel" -> {
                    cancelVibrate()
                    result.success(true)
                }
                "isHapticFeedbackEnabled" -> {
                    try {
                        val enabled = android.provider.Settings.System.getInt(
                            context.contentResolver,
                            android.provider.Settings.System.HAPTIC_FEEDBACK_ENABLED,
                            0
                        ) != 0
                        result.success(enabled)
                    } catch (e: Exception) {
                        result.success(true)
                    }
                }
                "openHapticSettings" -> {
                    try {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_SOUND_SETTINGS)
                        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = android.content.Intent(android.provider.Settings.ACTION_SETTINGS)
                            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (ex: Exception) {
                            result.success(false)
                        }
                    }
                }
                "initOverlayChannel" -> {
                    attachVibrationChannelToOverlayEngine()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getVibrator(): Vibrator? {
        val appContext = applicationContext ?: context
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun triggerVibrate(durationMs: Long) {
        val vibrator = getVibrator() ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs)
        }
    }

    private fun cancelVibrate() {
        getVibrator()?.cancel()
    }
}
