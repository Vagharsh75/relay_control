package com.example.lift_restart

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager
import android.telephony.SmsMessage
import android.telephony.SubscriptionManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.lift_restart/sms"
    private val EVENT_CHANNEL = "com.example.lift_restart/sms_receive"

    private var smsReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")
                        val message = call.argument<String>("message")
                        val subscriptionId = call.argument<Int>("subscriptionId") ?: -1

                        if (phoneNumber == null || message == null) {
                            result.error("INVALID_ARGS", "Phone number and message are required", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val smsManager = if (subscriptionId > 0) {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                    context.getSystemService(SmsManager::class.java)
                                        .createForSubscriptionId(subscriptionId)
                                } else {
                                    @Suppress("DEPRECATION")
                                    SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
                                }
                            } else {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                    context.getSystemService(SmsManager::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    SmsManager.getDefault()
                                }
                            }

                            val parts = smsManager.divideMessage(message)
                            if (parts.size > 1) {
                                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                            } else {
                                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SEND_FAILED", e.message, null)
                        }
                    }
                    "getAvailableSims" -> {
                        try {
                            val subscriptionManager = getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                            val sims = subscriptionManager.activeSubscriptionInfoList ?: emptyList()
                            val simList = sims.map { info ->
                                mapOf(
                                    "subscriptionId" to info.subscriptionId,
                                    "carrierName" to (info.carrierName?.toString() ?: "Unknown"),
                                    "slotIndex" to info.simSlotIndex
                                )
                            }
                            result.success(simList)
                        } catch (e: SecurityException) {
                            result.success(emptyList<Map<String, Any>>())
                        } catch (e: Exception) {
                            result.error("SIM_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    smsReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                                for (msg in messages) {
                                    events?.success(mapOf(
                                        "sender" to (msg.originatingAddress ?: ""),
                                        "body" to (msg.messageBody ?: "")
                                    ))
                                }
                            }
                        }
                    }
                    val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
                    } else {
                        registerReceiver(smsReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    if (smsReceiver != null) {
                        unregisterReceiver(smsReceiver)
                        smsReceiver = null
                    }
                }
            })
    }
}
