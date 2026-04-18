// android/app/src/main/kotlin/com/codemate/editor/MainActivity.kt
// CodeMate 主 Activity - 初始化 Flutter Engine

package com.codemate.editor

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * CodeMate 主 Activity
 * 
 * 功能：
 * 1. 初始化 Flutter Engine
 * 2. 注册 Flutter 插件
 * 3. 配置 AI Engine 和 Update Service 的 MethodChannel
 */
class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "CodeMate.MainActivity"
    }
    
    // AI Engine 实例
    private lateinit var aiEngine: AIEngine
    
    // Update Service 实例
    private lateinit var updateService: UpdateService

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册 Flutter 插件
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // 初始化 AI Engine 并配置 MethodChannel
        aiEngine = AIEngine(this)
        aiEngine.initializeChannel(flutterEngine.dartExecutor.binaryMessenger)
        
        // 初始化 Update Service 并配置 MethodChannel
        updateService = UpdateService(this)
        updateService.initialize(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        super.onDestroy()
        // 清理资源
        if (::aiEngine.isInitialized) {
            // AIEngine 清理逻辑（如需要）
        }
        if (::updateService.isInitialized) {
            // UpdateService 清理逻辑（如需要）
        }
    }
}
