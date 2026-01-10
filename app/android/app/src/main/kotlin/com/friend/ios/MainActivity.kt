package com.friend.ios

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.friend.ios/notifyOnKill"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            if(call.method == "setNotificationOnKillService"){
                val arguments = call.arguments as? Map<*, *>
                val title = arguments?.get("title") as? String ?: ""
                val description = arguments?.get("description") as? String ?: ""

                val serviceIntent = Intent(this@MainActivity, NotificationOnKillService::class.java)
                serviceIntent.putExtra("title", title)
                serviceIntent.putExtra("description", description)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    @Suppress("DEPRECATION")
                    startService(serviceIntent)
                }
                result.success(true)
            }else{
                result.notImplemented()
            }
        }
    }

   

}