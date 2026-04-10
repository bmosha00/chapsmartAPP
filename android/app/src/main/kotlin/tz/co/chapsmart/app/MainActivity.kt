package tz.co.chapsmart.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "chapsmart/appcheck"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDebugToken") {
                val token = findDebugToken()
                if (token != null) {
                    result.success(token)
                } else {
                    result.error("NOT_FOUND", "Debug token not found", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun findDebugToken(): String? {
        val prefsDir = File(applicationContext.applicationInfo.dataDir, "shared_prefs")
        if (prefsDir.exists()) {
            val files = prefsDir.listFiles() ?: return null
            for (file in files) {
                try {
                    val prefs = applicationContext.getSharedPreferences(file.nameWithoutExtension, Context.MODE_PRIVATE)
                    for (entry in prefs.all) {
                        val value = entry.value?.toString() ?: ""
                        if (value.matches(Regex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"))) {
                            return value
                        }
                    }
                } catch (e: Exception) {
                    continue
                }
            }
        }
        return null
    }
}