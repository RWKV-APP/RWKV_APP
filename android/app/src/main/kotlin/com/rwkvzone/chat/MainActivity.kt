package com.rwkvzone.chat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.io.File
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private val CHANNEL = "utils"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val path = call.argument<String>("path")
                if (path != null) {
                    installApk(path)
                    result.success(null)
                } else {
                    result.error("INVALID_PATH", "Path cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun installApk(filePath: String) {
        val file = File(filePath)
        if (!file.exists()) {
            Log.e("APK_INSTALL", "File not found: $filePath")
            return
        }

        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
        } else {
            Uri.fromFile(file)
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            if (!packageManager.canRequestPackageInstalls()) {
//                val packageUri = Uri.parse("package:${packageName}")
//                startActivity(Intent(
//                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
//                    packageUri
//                ))
//                return
//            }
//        }

        startActivity(intent)
    }
}
