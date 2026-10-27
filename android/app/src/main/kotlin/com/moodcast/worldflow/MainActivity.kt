package com.moodcast.worldflow

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val smsChannel = "moodcast/sms"
    private val smsPermissionRequest = 9911
    private var pendingSmsResult: MethodChannel.Result? = null
    private var pendingPhone: String? = null
    private var pendingBody: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phone = call.argument<String>("phone")
                        val body = call.argument<String>("body")
                        if (phone.isNullOrBlank() || body == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        sendSms(phone, body, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun sendSms(phone: String, body: String, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            pendingSmsResult = result
            pendingPhone = phone
            pendingBody = body
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.SEND_SMS),
                smsPermissionRequest,
            )
            return
        }
        result.success(dispatchSms(phone, body))
    }

    private fun dispatchSms(phone: String, body: String): Boolean {
        return try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            val parts = smsManager.divideMessage(body)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(phone, null, body, null, null)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != smsPermissionRequest) return
        val result = pendingSmsResult
        val phone = pendingPhone
        val body = pendingBody
        pendingSmsResult = null
        pendingPhone = null
        pendingBody = null
        if (result == null || phone == null || body == null) return
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            result.success(dispatchSms(phone, body))
        } else {
            result.success(false)
        }
    }
}
