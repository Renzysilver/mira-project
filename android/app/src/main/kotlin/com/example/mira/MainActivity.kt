package com.example.mira

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG     = "MainActivity"
        private const val CHANNEL = "com.example.mira/wake_word"

        var isInForeground = false
            private set
    }

    private var methodChannel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingWakeWord = false

    // ── FlutterEngine ─────────────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService"  -> { startForegroundService(Intent(this, WakeWordService::class.java)); result.success(null) }
                "stopService"   -> { stopService(Intent(this, WakeWordService::class.java)); result.success(null) }
                "isRunning"     -> result.success(WakeWordService.isActive)
                "checkPendingWakeWord" -> {
                    val p = pendingWakeWord; pendingWakeWord = false; result.success(p)
                }
                "canDrawOverlays" -> result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Activity lifecycle ────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent?.getBooleanExtra(WakeWordService.EXTRA_WAKE_WORD, false) == true) {
            pendingWakeWord = true
            intent.removeExtra(WakeWordService.EXTRA_WAKE_WORD)
        }
    }

    override fun onResume() {
        super.onResume()
        isInForeground = true

        // REORDER_TO_FRONT sets getIntent() but skips onNewIntent — check here.
        val intentWakeWord = intent?.getBooleanExtra(WakeWordService.EXTRA_WAKE_WORD, false) == true
        if (intentWakeWord) {
            intent.removeExtra(WakeWordService.EXTRA_WAKE_WORD)
            showOverLockScreen()
            Log.i(TAG, "onResume: wake word (REORDER_TO_FRONT path)")
            mainHandler.postDelayed({
                methodChannel?.invokeMethod("wakeWordDetected", null)
            }, 300)
            return
        }

        // Cold start: launched from notification while app was killed.
        if (pendingWakeWord) {
            pendingWakeWord = false
            showOverLockScreen()
            Log.i(TAG, "onResume: pending wake word (cold start)")
            mainHandler.postDelayed({
                methodChannel?.invokeMethod("wakeWordDetected", null)
            }, 600)
        }
    }

    override fun onPause() {
        super.onPause()
        isInForeground = false
    }

    // ── New intent ────────────────────────────────────────────────────────────

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(WakeWordService.EXTRA_WAKE_WORD, false)) {
            showOverLockScreen()
            Log.i(TAG, "onNewIntent: wake word received")
            mainHandler.postDelayed({
                methodChannel?.invokeMethod("wakeWordDetected", null)
            }, 200)
        }
    }

    /** Turn the screen on and show over the lock screen. */
    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }
}