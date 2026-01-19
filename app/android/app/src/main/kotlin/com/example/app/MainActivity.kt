package com.fitlock.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Base64
import android.view.accessibility.AccessibilityManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fitlock.app/native"
    private val PREFS_NAME = "fitlock_prefs"
    private val KEY_AVAILABLE_MINUTES = "available_minutes"
    private val KEY_BLOCKED_PACKAGES = "blocked_packages"
    
    companion object {
        var availableMinutes: Int = 0
            set(value) {
                field = value
                saveAvailableMinutes(value)
            }
        var blockedPackages: List<String> = emptyList()
            set(value) {
                field = value
                saveBlockedPackages(value)
            }
        private var methodChannel: MethodChannel? = null
        private var appContext: Context? = null
        
        fun notifyTimeChanged() {
            methodChannel?.invokeMethod("onTimeChanged", mapOf("minutes" to availableMinutes))
        }
        
        private fun saveAvailableMinutes(minutes: Int) {
            appContext?.getSharedPreferences("fitlock_prefs", Context.MODE_PRIVATE)?.edit()?.apply {
                putInt("available_minutes", minutes)
                apply()
            }
        }
        
        private fun saveBlockedPackages(packages: List<String>) {
            appContext?.getSharedPreferences("fitlock_prefs", Context.MODE_PRIVATE)?.edit()?.apply {
                putStringSet("blocked_packages", packages.toSet())
                apply()
            }
        }
        
        fun loadFromPrefs(context: Context) {
            appContext = context
            val prefs = context.getSharedPreferences("fitlock_prefs", Context.MODE_PRIVATE)
            availableMinutes = prefs.getInt("available_minutes", 0)
            blockedPackages = prefs.getStringSet("blocked_packages", emptySet())?.toList() ?: emptyList()
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Load persisted data
        loadFromPrefs(applicationContext)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "setBlockedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    blockedPackages = packages
                    result.success(true)
                }
                "setAvailableTime" -> {
                    val minutes = call.argument<Int>("minutes") ?: 0
                    availableMinutes = minutes
                    result.success(true)
                }
                "getAvailableTime" -> {
                    // Return current available time from SharedPreferences
                    // This allows Flutter to sync FROM native on startup
                    loadFromPrefs(applicationContext)
                    result.success(availableMinutes)
                }
                "getBlockedAppsUsage" -> {
                    result.success(getBlockedAppsUsageMinutes())
                }
                "checkAndDeductTime" -> {
                    val deducted = checkAndDeductBlockedAppsTime()
                    result.success(deducted)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "isUsageStatsPermissionGranted" -> {
                    result.success(isUsageStatsPermissionGranted())
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(null)
                }
                "startBlockingService" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "stopBlockingService" -> {
                    result.success(null)
                }
                "startPoseDetection" -> {
                    result.success(true)
                }
                "stopPoseDetection" -> {
                    result.success(null)
                }
                "switchCamera" -> {
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any?>>()
        val addedPackages = mutableSetOf<String>()
        val usageStats = getTodayUsageStats()
        
        // Method 1: Query launchable apps with MATCH_ALL for Android 11+
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        // Use MATCH_ALL to get all apps on Android 11+
        val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            PackageManager.MATCH_ALL
        } else {
            0
        }
        val launchableApps = pm.queryIntentActivities(launcherIntent, flags)
        
        for (resolveInfo in launchableApps) {
            val packageName = resolveInfo.activityInfo.packageName
            if (addedPackages.contains(packageName)) continue
            addedPackages.add(packageName)
            
            try {
                val appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val todayUsageMinutes = usageStats[packageName] ?: 0L
                val iconBase64 = getAppIconBase64(appInfo)
                
                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to resolveInfo.loadLabel(pm).toString(),
                    "isSystemApp" to isSystemApp,
                    "todayUsageMinutes" to todayUsageMinutes,
                    "iconBase64" to iconBase64
                ))
            } catch (e: Exception) {
                // Skip if can't get app info
            }
        }
        
        // Method 2: Also get apps from usage stats (already used apps are visible)
        for ((packageName, _) in usageStats) {
            if (addedPackages.contains(packageName)) continue
            
            try {
                val appInfo = pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                addedPackages.add(packageName)
                
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val todayUsageMinutes = usageStats[packageName] ?: 0L
                val iconBase64 = getAppIconBase64(appInfo)
                
                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "isSystemApp" to isSystemApp,
                    "todayUsageMinutes" to todayUsageMinutes,
                    "iconBase64" to iconBase64
                ))
            } catch (e: Exception) {
                // Skip if can't get app info
            }
        }
        
        // Method 3: Force add popular apps that might be hidden by Android 11+ restrictions
        val popularApps = listOf(
            "com.google.android.youtube" to "YouTube",
            "com.google.android.apps.youtube.music" to "YouTube Music",
            "com.zhiliaoapp.musically" to "TikTok",
            "com.ss.android.ugc.trill" to "TikTok",
            "com.instagram.android" to "Instagram",
            "com.facebook.katana" to "Facebook",
            "com.facebook.orca" to "Messenger",
            "com.twitter.android" to "Twitter/X",
            "com.snapchat.android" to "Snapchat",
            "com.whatsapp" to "WhatsApp",
            "org.telegram.messenger" to "Telegram",
            "com.vkontakte.android" to "VK",
            "com.netflix.mediaclient" to "Netflix",
            "com.spotify.music" to "Spotify",
            "com.reddit.frontpage" to "Reddit",
            "com.discord" to "Discord",
            "tv.twitch.android.app" to "Twitch",
            "com.android.chrome" to "Chrome",
            "com.tencent.ig" to "PUBG Mobile",
            "com.supercell.brawlstars" to "Brawl Stars",
            "com.miHoYo.GenshinImpact" to "Genshin Impact"
        )
        
        for ((packageName, appName) in popularApps) {
            if (addedPackages.contains(packageName)) continue
            
            try {
                // Check if app is actually installed
                val appInfo = pm.getApplicationInfo(packageName, 0)
                addedPackages.add(packageName)
                
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val todayUsageMinutes = usageStats[packageName] ?: 0L
                val iconBase64 = getAppIconBase64(appInfo)
                
                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "isSystemApp" to isSystemApp,
                    "todayUsageMinutes" to todayUsageMinutes,
                    "iconBase64" to iconBase64
                ))
            } catch (e: PackageManager.NameNotFoundException) {
                // App not installed, skip
            } catch (e: Exception) {
                // Other error, skip
            }
        }
        
        return apps.sortedBy { it["appName"] as String }
    }
    
    private fun getAppIconBase64(appInfo: ApplicationInfo): String? {
        return try {
            val drawable = packageManager.getApplicationIcon(appInfo)
            val bitmap = drawableToBitmap(drawable)
            val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 64, 64, true)
            
            val outputStream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 80, outputStream)
            val byteArray = outputStream.toByteArray()
            
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }
    
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 64
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 64
        
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        
        return bitmap
    }
    
    private fun getTodayUsageStats(): Map<String, Long> {
        val result = mutableMapOf<String, Long>()
        
        if (!isUsageStatsPermissionGranted()) {
            return result
        }
        
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = java.util.Calendar.getInstance()
            calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
            calendar.set(java.util.Calendar.MINUTE, 0)
            calendar.set(java.util.Calendar.SECOND, 0)
            
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()
            
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
            
            for (stat in stats) {
                val minutes = stat.totalTimeInForeground / 1000 / 60
                if (minutes > 0) {
                    result[stat.packageName] = minutes
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return result
    }
    
    // Get total usage minutes for blocked apps today
    private fun getBlockedAppsUsageMinutes(): Long {
        val usageStats = getTodayUsageStats()
        var totalMinutes = 0L
        
        for (pkg in blockedPackages) {
            totalMinutes += usageStats[pkg] ?: 0L
        }
        
        return totalMinutes
    }
    
    // Check usage stats and deduct time spent in blocked apps
    // Returns the number of minutes deducted
    private fun checkAndDeductBlockedAppsTime(): Int {
        val prefs = getSharedPreferences("fitlock_prefs", Context.MODE_PRIVATE)
        val lastCheckedUsage = prefs.getLong("last_blocked_usage", 0L)
        
        val currentUsage = getBlockedAppsUsageMinutes()
        val newUsage = (currentUsage - lastCheckedUsage).coerceAtLeast(0L).toInt()
        
        if (newUsage > 0 && availableMinutes > 0) {
            val toDeduct = minOf(newUsage, availableMinutes)
            availableMinutes -= toDeduct
            
            // Save the current usage as last checked
            prefs.edit().putLong("last_blocked_usage", currentUsage).apply()
            
            // Notify Flutter about time change
            notifyTimeChanged()
            
            return toDeduct
        }
        
        // Update last checked even if no deduction (to prevent accumulation)
        if (currentUsage > lastCheckedUsage) {
            prefs.edit().putLong("last_blocked_usage", currentUsage).apply()
        }
        
        return 0
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        
        for (service in enabledServices) {
            if (service.id.contains(packageName)) {
                return true
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
}
