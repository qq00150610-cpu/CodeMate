// android/app/src/main/kotlin/com/codemate/editor/AIEngine.kt
// AI 引擎 - 处理 AI 编程助手核心逻辑

package com.codemate.editor

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * AI 引擎 - 模拟 AI 处理逻辑
 * 
 * 核心功能：
 * 1. 关键词识别与路由
 * 2. 代码分析
 * 3. VSCode API 集成
 * 4. AI 响应生成（模拟）
 */
class AIEngine(private val context: Context) {
    
    companion object {
        private const val TAG = "AIEngine"
        private const val CHANNEL_NAME = "com.codemate.ai"
    }

    // 关键词处理器映射
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

    /**
     * 初始化 MethodChannel
     */
    fun initializeChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
        }
        Log.d(TAG, "AI Engine initialized")
    }

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
                // 模拟连接测试
                simulateDelay()
                sendAIMessage(mapOf(
                    "type" to "connection_status",
                    "connected" to true
                ))
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

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
                    // 默认处理：通用问答
                    handleGeneralQuestion(message, code ?: selectedCode ?: "")
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

    /**
     * 解释代码
     */
    private fun handleExplain(remainingMessage: String, code: String) {
        simulateDelay()
        
        val explanation = buildString {
            appendLine("## 📖 代码解释")
            appendLine()
            appendLine("以下是选中代码的功能分析：")
            appendLine()
            
            if (code.isNotEmpty()) {
                appendLine("```${currentLanguage ?: "code"}")
                appendLine(code)
                appendLine("```")
                appendLine()
                
                // 简单分析
                when {
                    code.contains("fun ") || code.contains("def ") -> {
                        appendLine("**类型：** 函数/方法定义")
                        appendLine("**分析：** 这段代码定义了一个函数，通常用于封装可重用的逻辑。")
                    }
                    code.contains("class ") -> {
                        appendLine("**类型：** 类定义")
                        appendLine("**分析：** 这是一个类定义，用于面向对象编程。")
                    }
                    code.contains("val ") || code.contains("var ") -> {
                        appendLine("**类型：** 变量声明")
                        appendLine("**分析：** 这段代码声明了一个变量，用于存储数据。")
                    }
                    code.contains("if ") || code.contains("when ") -> {
                        appendLine("**类型：** 条件判断")
                        appendLine("**分析：** 这段代码根据条件执行不同的逻辑分支。")
                    }
                    code.contains("for ") || code.contains("while ") -> {
                        appendLine("**类型：** 循环结构")
                        appendLine("**分析：** 这段代码用于重复执行某段逻辑。")
                    }
                    else -> {
                        appendLine("**类型：** 代码片段")
                        appendLine("**分析：** 这是一段代码实现。")
                    }
                }
            } else {
                appendLine("未检测到选中的代码。")
                appendLine("请先在编辑器中选中要解释的代码。")
            }
        }
        
        sendAIMessage(mapOf(
            "type" to "response",
            "content" to explanation,
            "action" to "explain"
        ))
    }

    /**
     * 优化代码
     */
    private fun handleOptimize(remainingMessage: String, code: String) {
        simulateDelay()
        
        val optimization = buildString {
            appendLine("## 🔧 代码优化建议")
            appendLine()
            
            if (code.isNotEmpty()) {
                appendLine("### 原始代码")
                appendLine("```${currentLanguage ?: "code"}")
                appendLine(code)
                appendLine("```")
                appendLine()
                
                // 检测可优化的问题
                val issues = mutableListOf<String>()
                
                if (code.contains("for (i in 0..")) {
                    issues.add("- 考虑使用 `forEach` 或更函数式的方式替代传统 for 循环")
                }
                if (code.contains("var ") && !code.contains("+=") && !code.contains("-=")) {
                    issues.add("- 如果变量初始化后不再修改，考虑使用 `val`")
                }
                if (code.count { it == '\n' } > 20) {
                    issues.add("- 代码较长，建议拆分为更小的函数")
                }
                
                if (issues.isNotEmpty()) {
                    appendLine("### 发现的问题")
                    issues.forEach { appendLine(it) }
                    appendLine()
                }
                
                appendLine("### 优化建议")
                appendLine("1. 保持代码简洁清晰")
                appendLine("2. 避免重复代码，考虑抽取公共方法")
                appendLine("3. 添加适当的注释说明")
                appendLine("4. 考虑使用更现代的语法糖")
            } else {
                appendLine("请先选中要优化的代码。")
            }
        }
        
        sendAIMessage(mapOf(
            "type" to "response",
            "content" to optimization,
            "action" to "optimize",
            "code" to code,
            "language" to currentLanguage
        ))
    }

    /**
     * 添加注释
     */
    private fun handleComment(remainingMessage: String, code: String) {
        simulateDelay()
        
        val commentedCode = buildString {
            appendLine("## 📝 添加注释后的代码")
            appendLine()
            
            if (code.isNotEmpty()) {
                appendLine("```${currentLanguage ?: "code"}")
                appendLine("// " + "-".repeat(50))
                appendLine("// 文件: ${currentFileName ?: "unknown"}")
                appendLine("// 功能: [请根据实际功能填写]")
                appendLine("// 作者: CodeMate AI")
                appendLine("// 日期: ${java.text.SimpleDateFormat("yyyy-MM-dd").format(java.util.Date())}")
                appendLine("// " + "-".repeat(50))
                appendLine()
                
                // 为每一行添加注释
                code.lines().forEach { line ->
                    if (line.isNotBlank()) {
                        appendLine("$line // TODO: 添加注释说明")
                    } else {
                        appendLine(line)
                    }
                }
                appendLine("```")
            } else {
                appendLine("请先选中要添加注释的代码。")
            }
        }
        
        sendAIMessage(mapOf(
            "type" to "response",
            "content" to commentedCode,
            "action" to "insert_code",
            "code" to commentedCode,
            "language" to currentLanguage
        ))
    }

    /**
     * 查找 Bug
     */
    private fun handleBug(remainingMessage: String, code: String) {
        simulateDelay()
        
        val bugReport = buildString {
            appendLine("## 🐛 Bug 检查报告")
            appendLine()
            
            if (code.isNotEmpty()) {
                val bugs = mutableListOf<Pair<String, String>>()
                
                // 检测常见问题
                if (code.contains("==") && !code.contains("===")) {
                    bugs.add("潜在问题" to "建议使用 === 进行严格相等比较，避免类型转换带来的意外行为")
                }
                if (code.contains("catch") && !code.contains("e.printStackTrace")) {
                    bugs.add("空 catch 块" to "catch 块中应该处理或记录异常，而不是空着")
                }
                if (code.contains("TODO") || code.contains("FIXME")) {
                    bugs.add("未完成代码" to "代码中包含 TODO 或 FIXME 标记，需要完成")
                }
                if (code.contains("null") && !code.contains("?.")) {
                    bugs.add("空指针风险" to "建议使用空安全操作符 ?. 避免空指针异常")
                }
                if (code.contains("Thread.sleep") || code.contains("while (true)")) {
                    bugs.add("阻塞风险" to "代码可能导致线程阻塞，考虑异步处理")
                }
                
                if (bugs.isNotEmpty()) {
                    appendLine("### 发现 ${bugs.size} 个潜在问题\n")
                    bugs.forEachIndexed { index, (title, desc) ->
                        appendLine("**${index + 1}. $title**")
                        appendLine(desc)
                        appendLine()
                    }
                } else {
                    appendLine("✅ 未发现明显问题")
                    appendLine()
                    appendLine("代码看起来基本正确，但建议：")
                    appendLine("- 添加边界条件检查")
                    appendLine("- 添加适当的错误处理")
                    appendLine("- 编写单元测试验证")
                }
            } else {
                appendLine("请先选中要检查的代码。")
            }
        }
        
        sendAIMessage(mapOf(
            "type" to "response",
            "content" to bugReport
        ))
    }

    /**
     * 生成测试
     */
    private fun handleTest(remainingMessage: String, code: String) {
        simulateDelay()
        
        val testCode = buildString {
            appendLine("## ✅ 生成的单元测试")
            appendLine()
            
            if (code.isNotEmpty()) {
                val language = currentLanguage ?: "kotlin"
                
                when {
                    language.contains("kotlin") || language.contains("java") -> {
                        appendLine("```kotlin")
                        appendLine("import org.junit.Test")
                        appendLine("import org.junit.Assert.*")
                        appendLine()
                        appendLine("class ExampleTest {")
                        appendLine()
                        appendLine("    @Test")
                        appendLine("    fun `test case description`() {")
                        appendLine("        // Arrange")
                        appendLine("        // Act")
                        appendLine("        // Assert")
                        appendLine("        assertTrue(true)")
                        appendLine("    }")
                        appendLine("}")
                        appendLine("```")
                    }
                    language.contains("javascript") || language.contains("typescript") -> {
                        appendLine("```javascript")
                        appendLine("describe('Example', () => {")
                        appendLine("    it('should do something', () => {")
                        appendLine("        // Arrange")
                        appendLine("        // Act")
                        appendLine("        // Assert")
                        appendLine("        expect(true).toBe(true)")
                        appendLine("    })")
                        appendLine("})")
                        appendLine("```")
                    }
                    language.contains("python") -> {
                        appendLine("```python")
                        appendLine("import unittest")
                        appendLine()
                        appendLine("class TestExample(unittest.TestCase):")
                        appendLine()
                        appendLine("    def test_case(self):")
                        appendLine("        # Arrange")
                        appendLine("        # Act")
                        appendLine("        # Assert")
                        appendLine("        self.assertTrue(True)")
                        appendLine()
                        appendLine("if __name__ == '__main__':")
                        appendLine("    unittest.main()")
                        appendLine("```")
                    }
                }
                
                appendLine("\n**使用说明：**")
                appendLine("1. 将测试文件添加到项目的测试目录")
                appendLine("2. 根据实际需求修改测试用例")
                appendLine("3. 运行测试验证代码功能")
            } else {
                appendLine("请先选中要生成测试的代码。")
            }
        }
        
        sendAIMessage(mapOf(
            "type" to "response",
            "content" to testCode,
            "action" to "insert_code"
        ))
    }

    // 其他处理器...
    private fun handleRefactor(msg: String, code: String) = handleOptimize(msg, code)
    private fun handleDebug(msg: String, code: String) = handleBug(msg, code)
    private fun handleTranslate(msg: String, code: String) = handleGeneralQuestion(msg, code)
    private fun handleGenerate(msg: String, code: String) = handleTest(msg, code)
    
    private fun handleGeneralQuestion(message: String, code: String) {
        simulateDelay()
        
        val response = buildString {
            appendLine("## 💬 AI 助手")
            appendLine()
            appendLine("我收到了您的消息：")
            appendLine("> $message")
            appendLine()
            
            if (code.isNotEmpty()) {
                appendLine("当前选中的代码片段：")
                appendLine("```${currentLanguage ?: "code"}")
                appendLine(code.take(200) + if (code.length > 200) "..." else "")
                appendLine("```")
                appendLine()
            }
            
            appendLine("**我可以帮助您：**")
            appendLine("- 🔍 解释代码功能")
            appendLine("- 🔧 优化代码性能")
            appendLine("- 🐛 查找潜在 Bug")
            appendLine("- ✅ 生成单元测试")
            appendLine("- 📝 添加代码注释")
            appendLine()
            appendLine("请告诉我您需要什么帮助！")
        }
        
        sendAIMessage(mapOf(
            "type" to "response",
            "content" to response
        ))
    }

    /**
     * 模拟 AI 处理延迟
     */
    private fun simulateDelay() {
        Thread.sleep(minDelay + (Math.random() * (maxDelay - minDelay)).toLong())
    }

    /**
     * 发送 AI 消息到 Flutter
     */
    private fun sendAIMessage(data: Map<String, Any?>) {
        mainHandler.post {
            try {
                val jsonData = JSONObject(data).toString()
                methodChannel?.invokeMethod("onAIMessage", jsonData)
                resultCallback?.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending AI message", e)
                resultCallback?.error("SEND_ERROR", e.message, null)
            }
        }
    }

    /**
     * 发送错误消息
     */
    private fun sendError(message: String) {
        sendAIMessage(mapOf(
            "type" to "error",
            "content" to message
        ))
    }

    /**
     * 获取选中的代码
     */
    fun getSelectedCode(): String? = selectedCode

    /**
     * 设置选中的代码
     */
    fun setSelectedCode(code: String?) {
        selectedCode = code
    }

    /**
     * 清理资源
     */
    fun dispose() {
        executor.shutdown()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}
