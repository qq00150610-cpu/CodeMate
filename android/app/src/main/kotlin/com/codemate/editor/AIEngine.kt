// =============================================================================
// AI Engine - Android 原生 AI 服务实现
// 支持阿里云百炼 API
// =============================================================================

package com.codemate.editor

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * AI 引擎 - 处理 AI 编程助手核心逻辑
 * 
 * 核心功能：
 * 1. 关键词识别与路由
 * 2. 代码分析（解释、优化、调试等）
 * 3. Flutter 通信
 * 4. 阿里云百炼 API 调用
 */
class AIEngine(private val context: Context) {
    
    companion object {
        private const val TAG = "AIEngine"
        private const val CHANNEL_NAME = "com.codemate.ai"
        
        // 阿里云百炼 API 配置
        const val BAI_LIAN_API_KEY = "sk-e511f943447849769e588927c03fcffe"
        const val BAI_LIAN_BASE_URL = "https://dashscope.aliyuncs.com/api/v1"
        const val DEFAULT_MODEL = "qwen-turbo"
        
        // 请求配置
        const val TIMEOUT_SECONDS = 30L
        const val MAX_RETRIES = 3
        const val RETRY_DELAY_MS = 1000L
    }

    // =============================================================================
    // 关键词处理器映射
    // =============================================================================
    
    private val keywordHandlers = mutableMapOf(
        "解释" to ::handleExplain,
        "优化" to ::handleOptimize,
        "重构" to ::handleRefactor,
        "调试" to ::handleDebug,
        "翻译" to ::handleTranslate,
        "生成" to ::handleGenerate,
        "注释" to ::handleComment,
        "查找" to ::handleFind,
        "bug" to ::handleBug,
        "测试" to ::handleTest
    )

    // 模拟 AI 响应延迟范围 (毫秒)
    private val minDelay = 500L
    private val maxDelay = 2000L

    // 线程池
    private val executor: ExecutorService = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    // MethodChannel 回调
    private var methodChannel: MethodChannel? = null
    private var resultCallback: MethodChannel.Result? = null

    // 当前编辑器上下文
    private var currentFileName: String? = null
    private var currentLanguage: String? = null
    private var selectedCode: String? = null

    // AI 请求配置
    private var apiKey: String = BAI_LIAN_API_KEY
    private var baseUrl: String = BAI_LIAN_BASE_URL
    private var currentModel: String = DEFAULT_MODEL

    // =============================================================================
    // 初始化
    // =============================================================================
    
    /**
     * 初始化 MethodChannel
     */
    fun initializeChannel(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
        }
        Log.d(TAG, "AI Engine initialized")
    }

    /**
     * 配置 API
     */
    fun configure(apiKey: String, baseUrl: String, model: String) {
        this.apiKey = apiKey
        this.baseUrl = baseUrl
        this.currentModel = model
        Log.d(TAG, "AI configured: model=$model")
    }

    // =============================================================================
    // MethodChannel 处理
    // =============================================================================
    
    /**
     * 处理 MethodChannel 调用
     */
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        resultCallback = result

        when (call.method) {
            "sendToAI" -> {
                val message = call.argument<String>("message") ?: ""
                val code = call.argument<String>("selectedCode")
                processUserMessage(message, code)
            }

            "getSelectedCode" -> {
                result.success(selectedCode)
            }

            "setEditorContext" -> {
                currentFileName = call.argument<String>("fileName")
                currentLanguage = call.argument<String>("language")
                result.success(true)
            }

            "explainCode" -> {
                val code = selectedCode ?: call.argument<String>("code") ?: ""
                explainCode(code)
            }

            "optimizeCode" -> {
                val code = selectedCode ?: call.argument<String>("code") ?: ""
                optimizeCode(code)
            }

            "generateTest" -> {
                val code = selectedCode ?: call.argument<String>("code") ?: ""
                val testFramework = call.argument<String>("framework") ?: "JUnit"
                generateTest(code, testFramework)
            }

            "testConnection" -> {
                testConnection()
            }

            "setApiConfig" -> {
                apiKey = call.argument<String>("apiKey") ?: apiKey
                baseUrl = call.argument<String>("baseUrl") ?: baseUrl
                currentModel = call.argument<String>("model") ?: DEFAULT_MODEL
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    // =============================================================================
    // 消息处理
    // =============================================================================
    
    /**
     * 处理用户消息
     */
    fun processUserMessage(message: String, code: String? = null) {
        selectedCode = code ?: selectedCode
        
        executor.execute {
            try {
                // 检测关键词
                val (keyword, remainingMessage) = detectKeyword(message)
                
                Log.d(TAG, "Detected keyword: $keyword, remaining: $remainingMessage")
                
                // 调用对应的处理器
                val handler = keywordHandlers[keyword]
                if (handler != null) {
                    handler.invoke(remainingMessage, code ?: selectedCode ?: "")
                } else {
                    // 默认处理：通用问答，调用百炼 API
                    sendToBaiLian(remainingMessage, code ?: selectedCode ?: "")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing message", e)
                sendError("处理消息时出错: ${e.message}")
            }
        }
    }

    /**
     * 检测消息中的关键词
     */
    private fun detectKeyword(message: String): Pair<String?, String> {
        val trimmedMessage = message.trim()
        
        for (keyword in keywordHandlers.keys) {
            if (trimmedMessage.contains(keyword)) {
                val remaining = trimmedMessage.replace(keyword, "").trim()
                return keyword to remaining
            }
        }
        
        return null to trimmedMessage
    }

    // =============================================================================
    // 阿里云百炼 API 调用
    // =============================================================================
    
    /**
     * 发送请求到阿里云百炼 API
     */
    private fun sendToBaiLian(userMessage: String, code: String? = null) {
        executor.execute {
            try {
                sendStatus("thinking", 0.0, null)
                
                // 构建消息内容
                var content = userMessage
                if (!code.isNullOrEmpty()) {
                    content = """$userMessage

请分析以下${currentLanguage ?: "代码"}：
```${currentLanguage ?: ""}
$code
```"""
                }
                
                // 构建请求体（百炼 API 格式）
                val requestBody = JSONObject().apply {
                    put("model", currentModel)
                    put("input", JSONObject().apply {
                        put("messages", org.json.JSONArray().apply {
                            put(JSONObject().apply {
                                put("role", "user")
                                put("content", content)
                            })
                        })
                    })
                    put("parameters", JSONObject().apply {
                        put("temperature", 0.7)
                        put("max_tokens", 2000)
                        put("result_format", "message")
                    })
                }
                
                // 调用 API
                val response = callBaiLianApi(requestBody)
                
                // 解析响应
                if (response.has("output")) {
                    val output = response.getJSONObject("output")
                    val text = if (output.has("text")) {
                        output.getString("text")
                    } else if (output.has("choices")) {
                        output.getJSONArray("choices")
                            .getJSONObject(0)
                            .getJSONObject("message")
                            .getString("content")
                    } else {
                        "收到响应，但无法解析内容"
                    }
                    
                    // 提取代码块
                    val codeBlock = extractCodeBlock(text)
                    
                    sendAIMessage(mapOf(
                        "type" to "response",
                        "content" to text,
                        "code" to codeBlock,
                        "language" to (codeBlock?.let { detectLanguage(it) }),
                        "model" to currentModel
                    ))
                } else {
                    sendError(response.optString("error_message", "API 调用失败"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error calling BaiLian API", e)
                sendError("AI 服务暂时不可用: ${e.message}")
            }
        }
    }

    /**
     * 调用百炼 API
     */
    private fun callBaiLianApi(requestBody: JSONObject): JSONObject {
        var lastException: Exception? = null
        
        for (attempt in 1..MAX_RETRIES) {
            try {
                val url = java.net.URL("$baseUrl/services/aigc/text-generation/generation")
                val connection = url.openConnection() as java.net.HttpURLConnection
                
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Authorization", "Bearer $apiKey")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = (TIMEOUT_SECONDS * 1000).toInt()
                connection.readTimeout = (TIMEOUT_SECONDS * 1000).toInt()
                
                // 写入请求体
                connection.outputStream.use { output ->
                    output.write(requestBody.toString().toByteArray())
                }
                
                // 读取响应
                val responseCode = connection.responseCode
                val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
                
                if (responseCode == 200) {
                    return JSONObject(responseBody)
                } else {
                    Log.e(TAG, "API error: $responseCode - $responseBody")
                    lastException = Exception("API error: $responseCode")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Attempt $attempt failed", e)
                lastException = e
                
                // 重试延迟
                if (attempt < MAX_RETRIES) {
                    Thread.sleep(RETRY_DELAY_MS)
                }
            }
        }
        
        throw lastException ?: Exception("Unknown error")
    }

    // =============================================================================
    // 关键词处理器
    // =============================================================================
    
    /**
     * 解释代码
     */
    private fun handleExplain(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要解释的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请详细解释以下${currentLanguage ?: "代码"}的功能和工作原理：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            appendLine()
            appendLine("请用清晰易懂的方式解释，包括：")
            appendLine("1. 整体功能概述")
            appendLine("2. 主要组件和逻辑")
            appendLine("3. 关键代码段的作用")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 优化代码
     */
    private fun handleOptimize(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要优化的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请优化以下${currentLanguage ?: "代码"}，提高性能和可读性：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            appendLine()
            appendLine("请提供：")
            appendLine("1. 优化前的问题分析")
            appendLine("2. 优化后的代码")
            appendLine("3. 优化说明")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 重构代码
     */
    private fun handleRefactor(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要重构的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请重构以下${currentLanguage ?: "代码"}，改善其结构和设计：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            appendLine()
            appendLine("请提供：")
            appendLine("1. 当前问题分析")
            appendLine("2. 重构后的代码")
            appendLine("3. 重构原因说明")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 调试代码
     */
    private fun handleDebug(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要调试的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请分析以下${currentLanguage ?: "代码"}可能存在的问题并提供修复建议：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            appendLine()
            appendLine("请检查：")
            appendLine("1. 潜在的 Bug")
            appendLine("2. 安全风险")
            appendLine("3. 性能问题")
            appendLine("4. 最佳实践建议")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 翻译代码
     */
    private fun handleTranslate(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要翻译的代码")
            return
        }
        
        val targetLanguage = remainingMessage.ifEmpty { "Python" }
        
        val prompt = buildString {
            appendLine("请将以下代码翻译成 $targetLanguage：")
            appendLine()
            appendLine("原始代码 (${currentLanguage ?: "未知"})：")
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            appendLine()
            appendLine("请只提供翻译后的代码，不需要解释。")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 生成代码
     */
    private fun handleGenerate(remainingMessage: String, code: String) {
        if (remainingMessage.isEmpty()) {
            sendError("请描述要生成的代码功能")
            return
        }
        
        val prompt = buildString {
            appendLine("请根据以下需求生成代码：")
            appendLine()
            appendLine(remainingMessage)
            if (!code.isEmpty()) {
                appendLine()
                appendLine("参考现有代码风格：")
                appendLine("```${currentLanguage ?: ""}")
                appendLine(code)
                appendLine("```")
            }
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 添加注释
     */
    private fun handleComment(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要添加注释的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请为以下代码添加详细的中文注释：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 查找问题
     */
    private fun handleFind(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要检查的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请在以下代码中查找问题：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            appendLine()
            appendLine("查找内容：$remainingMessage")
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 处理 Bug
     */
    private fun handleBug(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要修复 Bug 的代码")
            return
        }
        
        val prompt = buildString {
            appendLine("请修复以下代码中的 Bug：")
            appendLine()
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
            if (remainingMessage.isNotEmpty()) {
                appendLine()
                appendLine("问题描述：$remainingMessage")
            }
        }
        
        sendToBaiLian(prompt)
    }

    /**
     * 生成测试
     */
    private fun handleTest(remainingMessage: String, code: String) {
        if (code.isEmpty()) {
            sendError("请先选中要生成测试的代码")
            return
        }
        
        val testFramework = remainingMessage.ifEmpty { "JUnit" }
        
        val prompt = buildString {
            appendLine("请为以下代码生成 $testFramework 单元测试用例：")
            appendLine()
            appendLine("原始代码：")
            appendLine("```${currentLanguage ?: ""}")
            appendLine(code)
            appendLine("```")
        }
        
        sendToBaiLian(prompt)
    }

    // =============================================================================
    // 代码分析（快捷调用）
    // =============================================================================
    
    /**
     * 解释代码
     */
    private fun explainCode(code: String) {
        handleExplain("", code)
    }

    /**
     * 优化代码
     */
    private fun optimizeCode(code: String) {
        handleOptimize("", code)
    }

    /**
     * 生成测试
     */
    private fun generateTest(code: String, testFramework: String) {
        handleTest(testFramework, code)
    }

    /**
     * 测试连接
     */
    private fun testConnection() {
        executor.execute {
            try {
                sendStatus("checking", 0.0, null)
                
                // 简单的连接测试
                val url = java.net.URL("$baseUrl/services/aigc/text-generation/generation")
                val connection = url.openConnection() as java.net.HttpURLConnection
                
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Authorization", "Bearer $apiKey")
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                // 发送测试请求
                val testRequest = JSONObject().apply {
                    put("model", currentModel)
                    put("input", JSONObject().apply {
                        put("messages", org.json.JSONArray().apply {
                            put(JSONObject().apply {
                                put("role", "user")
                                put("content", "Hi")
                            })
                        })
                    })
                    put("parameters", JSONObject().apply {
                        put("max_tokens", 10)
                    })
                }
                
                connection.doOutput = true
                connection.outputStream.use { output ->
                    output.write(testRequest.toString().toByteArray())
                }
                
                val responseCode = connection.responseCode
                
                mainHandler.post {
                    sendAIMessage(mapOf(
                        "type" to "connection_status",
                        "connected" to (responseCode in 200..299)
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Connection test failed", e)
                mainHandler.post {
                    sendAIMessage(mapOf(
                        "type" to "connection_status",
                        "connected" to false,
                        "error" to e.message
                    ))
                }
            }
        }
    }

    // =============================================================================
    // 工具函数
    // =============================================================================
    
    /**
     * 模拟延迟
     */
    private fun simulateDelay() {
        val delay = minDelay + (Math.random() * (maxDelay - minDelay)).toLong()
        Thread.sleep(delay)
    }

    /**
     * 提取代码块
     */
    private fun extractCodeBlock(text: String): String? {
        val regex = Regex("```[\\w]*\\n?([\\s\\S]*?)```")
        val match = regex.find(text)
        return match?.groupValues?.getOrNull(1)?.trim()
    }

    /**
     * 检测编程语言
     */
    private fun detectLanguage(code: String): String {
        return when {
            code.contains("fun ") || code.contains("val ") || code.contains("var ") -> "kotlin"
            code.contains("class ") && code.contains(";") -> "java"
            code.contains("def ") || (code.contains("import ") && !code.contains("{")) -> "python"
            code.contains("function ") || code.contains("const ") || code.contains("=>") -> "javascript"
            code.contains("fn ") && code.contains("->") -> "rust"
            code.contains("#include") || code.contains("int main") -> "cpp"
            else -> "code"
        }
    }

    // =============================================================================
    // 消息发送
    // =============================================================================
    
    /**
     * 发送 AI 消息到 Flutter
     */
    private fun sendAIMessage(data: Map<String, Any?>) {
        mainHandler.post {
            try {
                methodChannel?.invokeMethod("onAIMessage", JSONObject(data).toString())
                resultCallback?.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending AI message", e)
                resultCallback?.error("SEND_ERROR", e.message, null)
            }
        }
    }

    /**
     * 发送状态到 Flutter
     */
    private fun sendStatus(status: String, progress: Double, data: Any?) {
        val statusData = JSONObject().apply {
            put("status", status)
            put("progress", progress)
            if (data != null) {
                put("data", data)
            }
        }
        
        mainHandler.post {
            try {
                methodChannel?.invokeMethod("onStatusChanged", statusData.toString())
            } catch (e: Exception) {
                Log.e(TAG, "Error sending status", e)
            }
        }
    }

    /**
     * 发送错误到 Flutter
     */
    private fun sendError(message: String) {
        sendAIMessage(mapOf(
            "type" to "error",
            "content" to message
        ))
    }

    /**
     * 释放资源
     */
    fun dispose() {
        executor.shutdown()
        try {
            if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
                executor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            executor.shutdownNow()
        }
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}
