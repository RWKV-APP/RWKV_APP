package com.rwkvzone.chat

import android.content.Intent
import android.graphics.Paint
import android.graphics.Typeface
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "utils"
    private val fontChannelName = "com.rwkvzone.chat/fonts"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        installApk(path)
                        result.success(null)
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, fontChannelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "getSystemFonts") {
                try {
                    val fonts = getSystemFonts()
                    result.success(fonts)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get system fonts: ${e.message}", null)
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

        val uri = FileProvider.getUriForFile(
            this, "${applicationContext.packageName}.fileprovider", file
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }

    private fun getSystemFonts(): List<Map<String, Any>> {
        val fontInfoList = mutableListOf<Map<String, Any>>()
        val processedFonts = mutableSetOf<String>()
        
        // Get default system fonts
        val defaultFonts = listOf(
            "Roboto", "sans-serif", "serif", "monospace"
        )
        
        // Common fonts that are typically available
        val commonFonts = listOf(
            "Arial", "Helvetica", "Times New Roman", "Courier New",
            "Verdana", "Georgia", "Palatino", "Garamond",
            "Bookman", "Comic Sans MS", "Trebuchet MS", "Arial Black",
            "Impact", "Lucida Console", "Tahoma", "Courier"
        )
        
        // Android system font families
        val systemFonts = listOf(
            "sans-serif", "sans-serif-light", "sans-serif-thin",
            "sans-serif-condensed", "sans-serif-medium", "sans-serif-black",
            "serif", "serif-monospace", "monospace", "casual", "cursive", "fantasy"
        )
        
        val allFonts = (defaultFonts + commonFonts + systemFonts).distinct()
        
        for (fontName in allFonts) {
            if (processedFonts.contains(fontName)) {
                continue
            }
            processedFonts.add(fontName)
            
            // Try to create Typeface and check if it's monospace
            val isMonospace = try {
                val typeface = Typeface.create(fontName, Typeface.NORMAL)
                if (typeface != null) {
                    isFontMonospace(typeface, fontName)
                } else {
                    inferMonospaceFromName(fontName)
                }
            } catch (e: Exception) {
                inferMonospaceFromName(fontName)
            }
            
            fontInfoList.add(mapOf(
                "name" to fontName,
                "isMonospace" to isMonospace
            ))
        }
        
        // Sort by name
        fontInfoList.sortBy { it["name"] as String }
        
        return fontInfoList
    }
    
    // 检测字体是否为等宽字体（通过测量字符宽度）
    private fun isFontMonospace(typeface: Typeface, fontName: String): Boolean {
        // 对于已知的等宽字体，直接返回
        if (fontName.contains("mono", ignoreCase = true) ||
            fontName.contains("courier", ignoreCase = true) ||
            fontName == "monospace") {
            return true
        }
        
        // 通过测量字符宽度来判断
        val paint = Paint().apply {
            this.typeface = typeface
            textSize = 12f
        }
        
        val testChars = arrayOf("i", "m", "W", "0")
        val widths = mutableListOf<Float>()
        
        for (char in testChars) {
            val width = paint.measureText(char)
            widths.add(width)
        }
        
        // 如果所有字符宽度相同（允许很小的误差），则为等宽字体
        if (widths.isNotEmpty()) {
            val firstWidth = widths[0]
            for (width in widths) {
                if (kotlin.math.abs(width - firstWidth) > 0.1f) {
                    return false
                }
            }
            return true
        }
        
        return false
    }
    
    // 从字体名称推断是否为等宽字体（作为后备方案）
    private fun inferMonospaceFromName(fontName: String): Boolean {
        val lowerName = fontName.lowercase()
        return lowerName.contains("mono") ||
               lowerName.contains("courier") ||
               lowerName == "monospace" ||
               lowerName.contains("console") ||
               lowerName.contains("terminal") ||
               lowerName.contains("code") ||
               lowerName.contains("menlo") ||
               lowerName.contains("consolas")
    }
}
