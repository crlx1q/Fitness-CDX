package com.fitlock.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

/**
 * Accessibility Service for blocking apps when no time available
 * and tracking time spent in blocked apps
 */
class AppBlockerService : AccessibilityService() {
    
    private var currentBlockedApp: String? = null
    private var timeTrackingStarted: Long = 0
    private val handler = Handler(Looper.getMainLooper())
    private var timeDeductionRunnable: Runnable? = null
    private var usageCheckRunnable: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        // Load persisted data so service works even when Flutter app is closed
        MainActivity.loadFromPrefs(applicationContext)
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
        
        // Start background usage check for when Flutter app is closed
        startUsageCheck()
    }
    
    private fun startUsageCheck() {
        usageCheckRunnable = object : Runnable {
            override fun run() {
                // Reload from prefs in case Flutter updated it
                MainActivity.loadFromPrefs(applicationContext)
                
                // Check and deduct time spent in blocked apps
                checkAndDeductTime()
                
                val currentApp = getCurrentForegroundApp()
                val isBlockedForeground = currentApp != null && MainActivity.blockedPackages.contains(currentApp)
                var nextDelayMs = 15_000L

                // If no time left and a blocked app is in foreground, block it and keep fast checks
                if (MainActivity.availableMinutes <= 0 && isBlockedForeground) {
                    val intent = Intent(this@AppBlockerService, BlockedActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("blocked_package", currentApp)
                    }
                    startActivity(intent)
                    nextDelayMs = 5_000L
                } else if (isBlockedForeground) {
                    // When user is inside blocked app, check faster
                    nextDelayMs = 5_000L
                }
                
                handler.postDelayed(this, nextDelayMs)
            }
        }
        // Start first check after 2 seconds
        handler.postDelayed(usageCheckRunnable!!, 2_000)
    }
    
    private fun getCurrentForegroundApp(): String? {
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 10_000 // Last 10 seconds
            
            val usageEvents = usm.queryEvents(startTime, endTime)
            var lastApp: String? = null
            var lastTime = 0L
            
            val event = android.app.usage.UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                    if (event.timeStamp > lastTime) {
                        lastTime = event.timeStamp
                        lastApp = event.packageName
                    }
                }
            }
            return lastApp
        } catch (e: Exception) {
            return null
        }
    }
    
    private fun checkAndDeductTime() {
        try {
            val prefs = applicationContext.getSharedPreferences("fitlock_prefs", Context.MODE_PRIVATE)
            
            // Check for day change - reset last_blocked_usage at midnight
            val lastCheckedDay = prefs.getInt("last_checked_day", -1)
            val currentDay = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_YEAR)
            
            if (lastCheckedDay != currentDay) {
                // New day - reset usage tracking
                prefs.edit()
                    .putLong("last_blocked_usage", 0L)
                    .putInt("last_checked_day", currentDay)
                    .apply()
            }
            
            val lastCheckedUsage = prefs.getLong("last_blocked_usage", 0L)
            val currentUsage = getBlockedAppsUsageMinutes()
            val newUsage = (currentUsage - lastCheckedUsage).coerceAtLeast(0L).toInt()
            
            if (newUsage > 0 && MainActivity.availableMinutes > 0) {
                val toDeduct = minOf(newUsage, MainActivity.availableMinutes)
                MainActivity.availableMinutes -= toDeduct
                prefs.edit().putLong("last_blocked_usage", currentUsage).apply()
                
                // Notify Flutter about time change
                MainActivity.notifyTimeChanged()
            } else if (currentUsage > lastCheckedUsage) {
                prefs.edit().putLong("last_blocked_usage", currentUsage).apply()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun getBlockedAppsUsageMinutes(): Long {
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = java.util.Calendar.getInstance()
            calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
            calendar.set(java.util.Calendar.MINUTE, 0)
            calendar.set(java.util.Calendar.SECOND, 0)
            
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()
            
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
            var totalMinutes = 0L
            
            for (stat in stats) {
                if (MainActivity.blockedPackages.contains(stat.packageName)) {
                    totalMinutes += stat.totalTimeInForeground / 1000 / 60
                }
            }
            return totalMinutes
        } catch (e: Exception) {
            return 0L
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        val packageName = event.packageName?.toString() ?: return
        
        // Skip if this is our own app or system UI
        if (packageName == this.packageName || 
            packageName == "com.android.systemui" ||
            packageName == "com.android.launcher" ||
            packageName.contains("launcher")) {
            // User left blocked app, stop time tracking
            stopTimeTracking()
            return
        }
        
        val isBlockedApp = MainActivity.blockedPackages.contains(packageName)
        
        if (isBlockedApp) {
            // Immediately check and deduct time when entering blocked app
            checkAndDeductTime()
            
            // Reload to get updated available minutes
            MainActivity.loadFromPrefs(applicationContext)
            
            if (MainActivity.availableMinutes <= 0) {
                // No time available - block the app
                stopTimeTracking()
                val intent = Intent(this, BlockedActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("blocked_package", packageName)
                }
                startActivity(intent)
            } else {
                // Time available - start tracking if not already tracking this app
                if (currentBlockedApp != packageName) {
                    stopTimeTracking()
                    startTimeTracking(packageName)
                }
            }
        } else {
            // Not a blocked app, stop tracking
            stopTimeTracking()
        }
    }
    
    private fun startTimeTracking(packageName: String) {
        currentBlockedApp = packageName
        timeTrackingStarted = System.currentTimeMillis()
        
        // Check time every 5 seconds to detect when time runs out faster
        timeDeductionRunnable = object : Runnable {
            override fun run() {
                if (currentBlockedApp != null) {
                    // Reload from prefs to get latest value
                    MainActivity.loadFromPrefs(applicationContext)
                    
                    // Also check and deduct time based on UsageStats
                    checkAndDeductTime()
                    
                    if (MainActivity.availableMinutes <= 0) {
                        // Time ran out - block the app immediately
                        val intent = Intent(this@AppBlockerService, BlockedActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            putExtra("blocked_package", currentBlockedApp)
                        }
                        startActivity(intent)
                        stopTimeTracking()
                    } else {
                        // Continue checking every 5 seconds for faster response
                        handler.postDelayed(this, 5_000)
                    }
                }
            }
        }
        
        // Start checking after 5 seconds
        handler.postDelayed(timeDeductionRunnable!!, 5_000)
    }
    
    private fun stopTimeTracking() {
        timeDeductionRunnable?.let { handler.removeCallbacks(it) }
        timeDeductionRunnable = null
        currentBlockedApp = null
        timeTrackingStarted = 0
    }

    override fun onInterrupt() {
        stopTimeTracking()
    }
    
    override fun onDestroy() {
        stopTimeTracking()
        usageCheckRunnable?.let { handler.removeCallbacks(it) }
        super.onDestroy()
    }
}
