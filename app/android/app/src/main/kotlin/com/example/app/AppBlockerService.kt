package com.fitlock.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

/**
 * Accessibility Service for blocking apps when no time available
 * and tracking time spent in blocked apps.
 * 
 * REAL-TIME TRACKING: This service now tracks time in real-time when user is in
 * blocked apps, instead of relying solely on UsageStats which has delays.
 */
class AppBlockerService : AccessibilityService() {
    
    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "fitlock_blocking"
        private const val LOW_BALANCE_NOTIFICATION_ID = 1001
        private const val ZERO_BALANCE_NOTIFICATION_ID = 1002
        private const val PREFS_NAME = "fitlock_prefs"
        private const val LOW_BALANCE_THRESHOLD_MINUTES = 5
        
        // Real-time tracking interval (every 1 second)
        private const val REALTIME_CHECK_INTERVAL_MS = 1_000L
        private const val SECONDS_PER_MINUTE = 60
    }
    
    private var currentBlockedApp: String? = null
    private var realtimeTrackingStartMs: Long = 0
    private var realtimeSecondsAccumulated: Int = 0
    private val handler = Handler(Looper.getMainLooper())
    private var realtimeTrackingRunnable: Runnable? = null
    private var backgroundCheckRunnable: Runnable? = null
    private var lastNotifiedLowBalance: Int = -1
    private var hasNotifiedZeroBalance: Boolean = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        // Create notification channel
        createNotificationChannel()
        
        // Load persisted data so service works even when Flutter app is closed
        MainActivity.loadFromPrefs(applicationContext)
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
        
        // Start background check loop
        startBackgroundCheck()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Блокировка приложений",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о блокировке приложений и низком балансе"
                enableVibration(true)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
    
    /**
     * Background check loop - runs every 3 seconds to catch when user is in blocked app
     * and to enforce blocking even when accessibility events are missed
     */
    private fun startBackgroundCheck() {
        backgroundCheckRunnable = object : Runnable {
            override fun run() {
                // Reload from prefs in case Flutter updated it
                MainActivity.loadFromPrefs(applicationContext)
                
                val currentApp = getCurrentForegroundApp()
                val isBlockedForeground = currentApp != null && 
                    MainActivity.blockedPackages.contains(currentApp)
                
                // If we're in a blocked app but not tracking, start tracking
                if (isBlockedForeground && currentBlockedApp != currentApp) {
                    stopRealtimeTracking()
                    startRealtimeTracking(currentApp!!)
                }

                // If we left blocked app, stop tracking to avoid over-counting
                if (!isBlockedForeground && currentBlockedApp != null) {
                    stopRealtimeTracking()
                }
                
                // If no time left and a blocked app is in foreground, BLOCK IT
                if (MainActivity.availableMinutes <= 0 && isBlockedForeground) {
                    showBlockedActivity(currentApp!!)
                    checkLowBalanceNotification()
                    stopRealtimeTracking()
                }
                
                // Check for low balance notification
                checkLowBalanceNotification()
                
                // Continue checking every 3 seconds
                handler.postDelayed(this, 3_000)
            }
        }
        handler.postDelayed(backgroundCheckRunnable!!, 1_000)
    }
    
    private fun getCurrentForegroundApp(): String? {
        val rootPackage = rootInActiveWindow?.packageName?.toString()
        if (!rootPackage.isNullOrBlank()) {
            return rootPackage
        }
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 5_000 // Last 5 seconds for faster detection
            
            val usageEvents = usm.queryEvents(startTime, endTime)
            var lastApp: String? = null
            var lastTime = 0L
            
            val event = android.app.usage.UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED ||
                    event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_PAUSED) {
                    if (event.timeStamp > lastTime) {
                        lastTime = event.timeStamp
                        // Only set lastApp for RESUMED events
                        if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                            lastApp = event.packageName
                        }
                    }
                }
            }
            return lastApp
        } catch (e: Exception) {
            return null
        }
    }
    
    /**
     * REAL-TIME time tracking - deducts 1 minute for every 60 seconds spent in blocked apps.
     * This is much more accurate than UsageStats which can have delays of several minutes.
     */
    private fun startRealtimeTracking(packageName: String) {
        currentBlockedApp = packageName
        realtimeTrackingStartMs = SystemClock.elapsedRealtime()
        realtimeSecondsAccumulated = 0
        
        // Check every second and deduct time in real-time
        realtimeTrackingRunnable = object : Runnable {
            override fun run() {
                if (currentBlockedApp == null) return
                
                // Reload from prefs to get latest balance
                MainActivity.loadFromPrefs(applicationContext)
                
                // Calculate elapsed seconds since last check
                val now = SystemClock.elapsedRealtime()
                val elapsedMs = now - realtimeTrackingStartMs
                val elapsedSeconds = (elapsedMs / 1000).toInt()
                
                // Accumulate seconds
                realtimeSecondsAccumulated = elapsedSeconds
                
                // Deduct 1 minute for every 60 accumulated seconds
                val minutesToDeduct = realtimeSecondsAccumulated / SECONDS_PER_MINUTE
                
                if (minutesToDeduct > 0 && MainActivity.availableMinutes > 0) {
                    val actualDeduct = minOf(minutesToDeduct, MainActivity.availableMinutes)
                    MainActivity.availableMinutes -= actualDeduct
                    
                    // Reset tracking start to now, keeping remainder seconds
                    realtimeSecondsAccumulated %= SECONDS_PER_MINUTE
                    realtimeTrackingStartMs = now - (realtimeSecondsAccumulated * 1000L)
                    
                    // Save to prefs for persistence
                    saveAvailableMinutesToPrefs()
                    
                    // Notify Flutter about time change
                    MainActivity.notifyTimeChanged()
                    
                    // Check for low balance notification
                    checkLowBalanceNotification()
                }
                
                // If time ran out, BLOCK IMMEDIATELY
                if (MainActivity.availableMinutes <= 0) {
                    showBlockedActivity(currentBlockedApp!!)
                    checkLowBalanceNotification()
                    stopRealtimeTracking()
                    return
                }
                
                // Continue tracking
                handler.postDelayed(this, REALTIME_CHECK_INTERVAL_MS)
            }
        }
        
        // Start first check after 1 second
        handler.postDelayed(realtimeTrackingRunnable!!, REALTIME_CHECK_INTERVAL_MS)
    }
    
    private fun stopRealtimeTracking() {
        realtimeTrackingRunnable?.let { handler.removeCallbacks(it) }
        realtimeTrackingRunnable = null
        currentBlockedApp = null
        realtimeTrackingStartMs = 0
        realtimeSecondsAccumulated = 0
    }
    
    private fun saveAvailableMinutesToPrefs() {
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putInt("available_minutes", MainActivity.availableMinutes).apply()
    }
    
    private fun showBlockedActivity(packageName: String) {
        val intent = Intent(this, BlockedActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("blocked_package", packageName)
        }
        startActivity(intent)
    }
    
    private fun checkLowBalanceNotification() {
        val balance = MainActivity.availableMinutes
        
        if (balance <= 0) {
            if (!hasNotifiedZeroBalance) {
                showZeroBalanceNotification()
                hasNotifiedZeroBalance = true
            }
            return
        }
        hasNotifiedZeroBalance = false

        if (balance > LOW_BALANCE_THRESHOLD_MINUTES) {
            lastNotifiedLowBalance = -1
            return
        }

        // Show notification when balance is 5, 4, 3, 2, or 1 minute
        if (balance in 1..LOW_BALANCE_THRESHOLD_MINUTES && balance != lastNotifiedLowBalance) {
            lastNotifiedLowBalance = balance
            showLowBalanceNotification(balance)
        }
    }
    
    private fun showLowBalanceNotification(minutes: Int) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("⏰ Время заканчивается!")
            .setContentText("Осталось $minutes мин. Потренируйтесь, чтобы заработать больше!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(LOW_BALANCE_NOTIFICATION_ID, notification)
    }
    
    private fun showZeroBalanceNotification() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("🚫 Время закончилось!")
            .setContentText("Заблокированные приложения недоступны. Потренируйтесь!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(ZERO_BALANCE_NOTIFICATION_ID, notification)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        val packageName = event.packageName?.toString() ?: return
        
        // Skip if this is our own app or system UI
        if (packageName == this.packageName || 
            packageName == "com.android.systemui" ||
            packageName == "com.android.launcher" ||
            packageName.contains("launcher")) {
            // User left blocked app, stop tracking
            stopRealtimeTracking()
            return
        }
        
        // Reload latest data
        MainActivity.loadFromPrefs(applicationContext)
        
        val isBlockedApp = MainActivity.blockedPackages.contains(packageName)
        
        if (isBlockedApp) {
            if (MainActivity.availableMinutes <= 0) {
                // No time available - BLOCK immediately
                stopRealtimeTracking()
                showBlockedActivity(packageName)
                checkLowBalanceNotification()
            } else {
                // Time available - start real-time tracking if not already tracking this app
                if (currentBlockedApp != packageName) {
                    stopRealtimeTracking()
                    startRealtimeTracking(packageName)
                }
            }
        } else {
            // Not a blocked app, stop tracking
            stopRealtimeTracking()
        }
    }

    override fun onInterrupt() {
        stopRealtimeTracking()
    }
    
    override fun onDestroy() {
        stopRealtimeTracking()
        backgroundCheckRunnable?.let { handler.removeCallbacks(it) }
        super.onDestroy()
    }
}
