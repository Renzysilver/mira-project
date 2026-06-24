package com.example.mira

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.NotificationCompat

class WakeWordService : Service() {

    companion object {
        private const val TAG = "WakeWordService"
        private const val CHANNEL_ID      = "mira_wake_word"
        private const val CALL_CHANNEL_ID = "mira_incoming_call"
        private const val NOTIF_LISTENING = 2001
        private const val NOTIF_CALL      = 2002

        const val EXTRA_WAKE_WORD = "wake_word_detected"

        private val WAKE_PHRASES = listOf(
            "hey mira", "hey mirror", "hey mara",
            "hey myra", "hey meera", "hey mera"
        )

        var isActive = false
            private set
    }

    private var recognizer: SpeechRecognizer? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isListening = false
    private var shouldRun   = true

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isActive = true
        createNotificationChannels()
        startForeground(NOTIF_LISTENING, buildListeningNotification())
        mainHandler.post { createRecognizer() }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        shouldRun = true
        if (!isListening && recognizer != null) mainHandler.post { startListening() }
        return START_STICKY
    }

    override fun onDestroy() {
        isActive  = false
        shouldRun = false
        destroyRecognizer()
        super.onDestroy()
    }

    // ── Recognizer lifecycle ───────────────────────────────────────────────────

    private fun createRecognizer() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Log.w(TAG, "Speech recognition unavailable")
            return
        }
        destroyRecognizer()
        recognizer = SpeechRecognizer.createSpeechRecognizer(this)
        recognizer?.setRecognitionListener(listener)
        startListening()
    }

    private fun destroyRecognizer() {
        try { recognizer?.destroy() } catch (_: Exception) {}
        recognizer = null
        isListening = false
    }

    /** Recreate the entire SpeechRecognizer after ERROR_CLIENT. */
    private fun scheduleRecreate(delayMs: Long = 1500) {
        isListening = false
        if (!shouldRun) return
        mainHandler.postDelayed({
            if (shouldRun) createRecognizer()
        }, delayMs)
    }

    private fun startListening() {
        if (!shouldRun || recognizer == null || isListening) return
        isListening = true

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            // Keep each window open longer so "Hey Mira" has time to land.
            // Without these the recognizer cuts off after ~1s of silence.
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 2000)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1500)
        }
        try {
            recognizer?.startListening(intent)
        } catch (e: Exception) {
            Log.e(TAG, "startListening threw: ${e.message}")
            scheduleRecreate(2000)
        }
    }

    private fun scheduleRestart(delayMs: Long = 500) {
        isListening = false
        if (!shouldRun) return
        mainHandler.postDelayed({
            if (shouldRun) startListening()
        }, delayMs)
    }

    private fun delayForError(error: Int): Long = when (error) {
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY          -> 3000
        SpeechRecognizer.ERROR_NO_MATCH                 -> 1200  // Normal idle — don't spin fast
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT           -> 1200  // Same: silence timeout
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> 10_000
        SpeechRecognizer.ERROR_NETWORK,
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT          -> 5000
        SpeechRecognizer.ERROR_SERVER                   -> 5000
        else                                            -> 1000
    }

    // ── Wake-word logic ────────────────────────────────────────────────────────

    private fun containsWakePhrase(text: String): Boolean {
        val lower = text.lowercase().trim()
        return WAKE_PHRASES.any { lower.contains(it) }
    }

    private fun onWakeWordDetected() {
        Log.i(TAG, "Wake word detected! isInForeground=${MainActivity.isInForeground}")

        // Turn the screen on even if it's dark/locked.
        // ACQUIRE_CAUSES_WAKEUP forces the display on from deep sleep.
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        val wl = pm.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "mira:WakeWordWakeLock"
        )
        wl.acquire(10_000L) // Auto-releases after 10 s

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            putExtra(EXTRA_WAKE_WORD, true)
        }

        if (MainActivity.isInForeground) {
            startActivity(intent)
        } else {
            // Screen was off or app in background.
            // Full-screen notification shows over the lock screen like an
            // incoming call. startActivity also fires — works if SYSTEM_ALERT_WINDOW
            // is granted (which we request when enabling Hey Mira).
            showIncomingCallNotification()
            try { startActivity(intent) } catch (_: Exception) {}
        }

        scheduleRestart(3000)
    }


    // ── Incoming call notification ─────────────────────────────────────────────

    private fun showIncomingCallNotification() {
        val answerIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_WAKE_WORD, true)
        }
        val answerPi = PendingIntent.getActivity(
            this, 1, answerIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val declinePi = PendingIntent.getBroadcast(
            this, 2,
            Intent("com.example.mira.DECLINE_CALL"),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(this, CALL_CHANNEL_ID)
            .setContentTitle("Mira")
            .setContentText("Hey Mira detected — tap to answer")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setAutoCancel(true)
            .setContentIntent(answerPi)
            // Full-screen intent: shows over the lock screen like an incoming call.
            .setFullScreenIntent(answerPi, true)
            .addAction(android.R.drawable.ic_menu_call, "Answer", answerPi)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declinePi)
            .build()

        getSystemService(NotificationManager::class.java).notify(NOTIF_CALL, notif)
    }

    // ── RecognitionListener ────────────────────────────────────────────────────

    private val listener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {}
        override fun onEvent(eventType: Int, params: Bundle?) {}

        override fun onPartialResults(partialResults: Bundle?) {
            val results = partialResults
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION) ?: return
            for (r in results) {
                if (containsWakePhrase(r)) {
                    recognizer?.cancel()
                    onWakeWordDetected()
                    return
                }
            }
        }

        override fun onResults(bundle: Bundle?) {
            val results = bundle
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION) ?: emptyList<String>()
            if (results.any { containsWakePhrase(it) }) {
                onWakeWordDetected()
            } else {
                scheduleRestart(1200)  // No wake word — idle restart
            }
        }

        override fun onError(error: Int) {
            // NO_MATCH (7) and SPEECH_TIMEOUT (6) are normal idle events.
            // Don't log them — they happen every ~2s when no one is speaking.
            if (error != SpeechRecognizer.ERROR_NO_MATCH &&
                error != SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                Log.d(TAG, "STT error $error")
            }
            if (error == SpeechRecognizer.ERROR_CLIENT) {
                scheduleRecreate(1500)
            } else {
                scheduleRestart(delayForError(error))
            }
        }
    }

    // ── Notifications ──────────────────────────────────────────────────────────

    private fun createNotificationChannels() {
        val mgr = getSystemService(NotificationManager::class.java)
        mgr.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Hey Mira",
                NotificationManager.IMPORTANCE_LOW).apply {
                description = "Listening for 'Hey Mira'"
                setShowBadge(false)
            }
        )
        mgr.createNotificationChannel(
            NotificationChannel(CALL_CHANNEL_ID, "Mira Incoming Call",
                NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Wake word triggered"
            }
        )
    }

    private fun buildListeningNotification(): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mira is listening")
            .setContentText("Say \"Hey Mira\" to start a call")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pi)
            .build()
    }
}