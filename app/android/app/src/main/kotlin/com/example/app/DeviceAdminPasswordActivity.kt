package com.fitlock.app

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.inputmethod.EditorInfo

class DeviceAdminPasswordActivity : Activity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make dialog-style window
        window.setBackgroundDrawableResource(android.R.color.transparent)
        window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        window.attributes.dimAmount = 0.6f
        
        // Create dialog layout programmatically
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(24), dp(24), dp(24))
            
            val dialogBg = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(16).toFloat()
            }
            background = dialogBg
        }
        
        // Title
        val title = TextView(this).apply {
            text = "Отключение защиты"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTextColor(Color.parseColor("#1a1a1a"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(8))
        }
        container.addView(title)
        
        // Description
        val description = TextView(this).apply {
            text = "Введите кодовое слово для отключения защиты от удаления"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#666666"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(16))
        }
        container.addView(description)
        
        // Password input
        val passwordInput = EditText(this).apply {
            hint = "Кодовое слово"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(dp(16), dp(12), dp(16), dp(12))
            imeOptions = EditorInfo.IME_ACTION_DONE
            
            val inputBg = GradientDrawable().apply {
                setColor(Color.parseColor("#f5f5f5"))
                cornerRadius = dp(8).toFloat()
                setStroke(dp(1), Color.parseColor("#e0e0e0"))
            }
            background = inputBg
            
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(16)
            }
        }
        container.addView(passwordInput)
        
        // Buttons container
        val buttonsContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        
        // Cancel button
        val cancelButton = Button(this).apply {
            text = "Отмена"
            setTextColor(Color.parseColor("#666666"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#f0f0f0"))
                cornerRadius = dp(8).toFloat()
            }
            background = btnBg
            
            layoutParams = LinearLayout.LayoutParams(
                0,
                dp(48),
                1f
            ).apply {
                rightMargin = dp(8)
            }
            
            setOnClickListener {
                finish()
            }
        }
        buttonsContainer.addView(cancelButton)
        
        // Confirm button
        val confirmButton = Button(this).apply {
            text = "Подтвердить"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#4CAF50"))
                cornerRadius = dp(8).toFloat()
            }
            background = btnBg
            
            layoutParams = LinearLayout.LayoutParams(
                0,
                dp(48),
                1f
            ).apply {
                leftMargin = dp(8)
            }
            
            setOnClickListener {
                val enteredPassword = passwordInput.text.toString().trim()
                if (enteredPassword == FitLockDeviceAdminReceiver.UNLOCK_PASSWORD) {
                    // Allow disable
                    val prefs = getSharedPreferences(
                        FitLockDeviceAdminReceiver.PREFS_NAME, 
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().putBoolean(
                        FitLockDeviceAdminReceiver.KEY_DISABLE_ALLOWED, 
                        true
                    ).apply()
                    
                    Toast.makeText(
                        this@DeviceAdminPasswordActivity,
                        "Теперь вы можете отключить администратора устройства",
                        Toast.LENGTH_LONG
                    ).show()
                    
                    // Open device admin settings
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val componentName = ComponentName(
                        this@DeviceAdminPasswordActivity,
                        FitLockDeviceAdminReceiver::class.java
                    )
                    
                    // Navigate to device admin settings
                    val intent = android.content.Intent(
                        android.provider.Settings.ACTION_SECURITY_SETTINGS
                    )
                    intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    
                    finish()
                } else {
                    Toast.makeText(
                        this@DeviceAdminPasswordActivity,
                        "Неверное кодовое слово",
                        Toast.LENGTH_SHORT
                    ).show()
                    passwordInput.text.clear()
                }
            }
        }
        buttonsContainer.addView(confirmButton)
        
        container.addView(buttonsContainer)
        
        // Set content view with margins
        val rootLayout = LinearLayout(this).apply {
            gravity = Gravity.CENTER
            setPadding(dp(32), dp(32), dp(32), dp(32))
            addView(container, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ))
        }
        
        setContentView(rootLayout)
    }
    
    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }
    
    override fun onBackPressed() {
        // Prevent back press without entering password
        Toast.makeText(this, "Введите кодовое слово для отмены", Toast.LENGTH_SHORT).show()
    }
}
