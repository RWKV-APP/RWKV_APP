package com.rwkvzone.chat

import android.content.Intent
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.fonts.SystemFonts
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "utils"
    private val fontChannelName = "com.rwkvzone.chat/fonts"
    
    // 使用单线程池来处理后台任务，避免阻塞主线程
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Utils Channel (安装 APK)
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

        // 2. Fonts Channel (获取字体)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, fontChannelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "getSystemFonts") {
                // 在后台线程执行耗时扫描
                executor.execute {
                    try {
                        val fonts = getRealSystemFonts()
                        // 切回主线程返回结果
                        mainHandler.post {
                            result.success(fonts)
                        }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("ERROR", "Failed to get system fonts: ${e.message}", null)
                        }
                    }
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

        try {
            val uri = FileProvider.getUriForFile(
                this, "${applicationContext.packageName}.fileprovider", file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
        } catch (e: Exception) {
            Log.e("APK_INSTALL", "Error installing APK", e)
        }
    }

    /**
     * 获取真实存在的系统字体列表
     * 混合策略：Android 10+ 使用 SystemFonts API，旧版本扫描 /system/fonts
     */
    private fun getRealSystemFonts(): List<Map<String, Any>> {
        val fontInfoList = mutableListOf<Map<String, Any>>()
        val processedPaths = mutableSetOf<String>()

        // 策略 A: Android 10 (API 29) 及以上使用官方 API
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val fonts = SystemFonts.getAvailableFonts()
                for (font in fonts) {
                    val file = font.file ?: continue
                    val path = file.absolutePath
                    
                    if (processedPaths.contains(path)) continue
                    processedPaths.add(path)

                    // 尝试加载字体进行测量
                    try {
                        // 注意：这里我们使用文件创建 Typeface，确保字体真实有效
                        val typeface = Typeface.createFromFile(file)
                        fontInfoList.add(mapOf(
                            "name" to file.name, // 使用文件名作为标识，例如 Roboto-Regular.ttf
                            "path" to path,
                            "isMonospace" to isFontMonospace(typeface)
                        ))
                    } catch (e: Exception) {
                        // 忽略损坏的字体文件
                        continue
                    }
                }
            } catch (e: Exception) {
                Log.e("FONTS", "Error using SystemFonts API", e)
            }
        }

        // 策略 B: 扫描 /system/fonts 目录 (作为补充或主力)
        // 即使在 Android 10+，有时扫描目录能发现 API 没暴露的字体，或者作为 fallback
        val systemFontDir = File("/system/fonts")
        if (systemFontDir.exists() && systemFontDir.isDirectory) {
            val files = systemFontDir.listFiles()
            if (files != null) {
                for (file in files) {
                    val path = file.absolutePath
                    
                    // 过滤非字体文件
                    if (!file.name.endsWith(".ttf", true) && !file.name.endsWith(".otf", true)) {
                        continue
                    }
                    
                    // 如果已经在 策略 A 中处理过，跳过
                    if (processedPaths.contains(path)) continue
                    processedPaths.add(path)

                    try {
                        val typeface = Typeface.createFromFile(file)
                        fontInfoList.add(mapOf(
                            "name" to file.name,
                            "path" to path,
                            "isMonospace" to isFontMonospace(typeface)
                        ))
                    } catch (e: Exception) {
                        continue
                    }
                }
            }
        }

        // 按名称排序
        fontInfoList.sortBy { it["name"] as String }

        return fontInfoList
    }

    /**
     * 通过测量字符宽度来精确判断是否为等宽字体
     */
    private fun isFontMonospace(typeface: Typeface): Boolean {
        val paint = Paint().apply {
            this.typeface = typeface
            textSize = 24f // 设置足够大的字号以减少测量误差
        }

        // 测试字符集：包含通常较窄的 'i', 'l' 和较宽的 'M', 'W' 以及标点
        val testChars = charArrayOf('i', 'M', '.', 'W', 'l', '1')
        
        if (testChars.isEmpty()) return false

        // 获取第一个字符的宽度作为基准
        val firstWidth = paint.measureText(testChars, 0, 1)

        // 遍历剩余字符，如果有任何一个宽度不同，则不是等宽字体
        for (i in 1 until testChars.size) {
            val currentWidth = paint.measureText(testChars, i, 1)
            // 允许极小的浮点数误差 (0.05f)
            if (kotlin.math.abs(currentWidth - firstWidth) > 0.05f) {
                return false
            }
        }
        
        return true
    }
}
