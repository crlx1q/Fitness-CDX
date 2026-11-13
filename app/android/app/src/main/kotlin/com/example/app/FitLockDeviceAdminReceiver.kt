package com.fitlock.app

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class FitLockDeviceAdminReceiver : DeviceAdminReceiver() {
    
    companion object {
        const val UNLOCK_PASSWORD = "Апельсин"
        const val PREFS_NAME = "fitlock_admin_prefs"
        const val KEY_DISABLE_ALLOWED = "disable_allowed"
    }
    
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Защита от удаления активирована", Toast.LENGTH_SHORT).show()
    }
    
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Reset the disable flag
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_DISABLE_ALLOWED, false)
            .apply()
        Toast.makeText(context, "Защита от удаления отключена", Toast.LENGTH_SHORT).show()
    }
    
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Check if disable was allowed via password
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val disableAllowed = prefs.getBoolean(KEY_DISABLE_ALLOWED, false)
        
        if (!disableAllowed) {
            // Launch password dialog activity
            val dialogIntent = Intent(context, DeviceAdminPasswordActivity::class.java)
            dialogIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(dialogIntent)
            return "Для отключения защиты введите кодовое слово в приложении FitLock"
        }
        
        return "Вы уверены, что хотите отключить защиту от удаления?"
    }
}
