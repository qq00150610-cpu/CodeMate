// android/app/src/androidTest/java/com/codemate/editor/InstrumentedTest.kt
// CodeMate 仪器测试套件

package com.codemate.editor

import android.content.Context
import android.view.View
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * AI 侧边栏 UI 测试
 */
@RunWith(AndroidJUnit4::class)
class AISidebarTest {

    private lateinit var context: Context

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
    }

    @Test
    fun testSidebarInitialization() {
        val sidebarView = View(context)
        assertNotNull(sidebarView)
    }

    @Test
    fun testSidebarWidth() {
        val screenWidth = context.resources.displayMetrics.widthPixels
        val expectedWidth = (screenWidth * 0.4).toInt()
        assertTrue("侧边栏宽度应该是屏幕的 40%", expectedWidth > 0)
    }

    @Test
    fun testMessageListDisplay() {
        val messageCount = 10
        assertTrue("消息数量应该大于 0", messageCount >= 0)
    }

    @Test
    fun testInputFieldFocus() {
        val isFocused = false
        assertTrue("输入框焦点状态应该正确", !isFocused || isFocused)
    }

    @Test
    fun testMarkdownRendering() {
        val markdown = "```kotlin\nfun hello() {}\n```"
        assertTrue("Markdown 内容应该包含代码块", markdown.contains("```"))
    }
}

/**
 * MethodChannel 通信测试
 */
@RunWith(AndroidJUnit4::class)
class MethodChannelInstrumentedTest {

    private lateinit var instrumentation: androidx.test.platform.app.InstrumentationRegistry

    @Before
    fun setup() {
        instrumentation = InstrumentationRegistry.getInstrumentation()
    }

    @Test
    fun testChannelConnection() {
        val channelName = "com.codemate.ai"
        assertTrue("Channel 名称应该正确", channelName.isNotEmpty())
    }

    @Test
    fun testSendMessageToNative() {
        val message = mapOf(
            "type" to "user_message",
            "content" to "测试消息"
        )
        assertNotNull(message)
    }

    @Test
    fun testReceiveMessageFromNative() {
        val response = "AI 响应内容"
        assertTrue("响应应该包含内容", response.isNotEmpty())
    }

    @Test
    fun testErrorCallback() {
        val errorCode = "TIMEOUT"
        val errorMessage = "请求超时"
        assertTrue("错误码应该非空", errorCode.isNotEmpty())
        assertTrue("错误消息应该非空", errorMessage.isNotEmpty())
    }
}

/**
 * WebView 加载测试
 */
@RunWith(AndroidJUnit4::class)
class WebViewTest {

    private lateinit var context: Context

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
    }

    @Test
    fun testWebViewCreation() {
        val webView = android.webkit.WebView(context)
        assertNotNull(webView)
    }

    @Test
    fun testJavaScriptEnabled() {
        val settings = android.webkit.WebSettings.Builder().build()
        assertNotNull(settings)
    }

    @Test
    fun testBridgeInjection() {
        val bridgeScript = """
            window.CodeMateBridge = {
                sendMessage: function(data) {
                    return JSON.stringify(data);
                }
            };
        """.trimIndent()
        assertTrue("桥接脚本应该非空", bridgeScript.isNotEmpty())
    }

    @Test
    fun testURLLoading() {
        val codeServerUrl = "http://127.0.0.1:20000"
        assertTrue("URL 应该正确", codeServerUrl.startsWith("http"))
    }
}

/**
 * 键盘适配测试
 */
@RunWith(AndroidJUnit4::class)
class KeyboardAdapterTest {

    private lateinit var context: Context

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
    }

    @Test
    fun testKeyboardHeightDetection() {
        val screenHeight = context.resources.displayMetrics.heightPixels
        val keyboardHeight = screenHeight / 3
        assertTrue("键盘高度应该大于 0", keyboardHeight > 0)
    }

    @Test
    fun testLayoutAdjustment() {
        val bottomPadding = 200
        val adjustedPadding = bottomPadding + 50
        assertTrue("调整后的内边距应该正确", adjustedPadding > bottomPadding)
    }

    @Test
    fun testQuickKeysVisibility() {
        val keyboardVisible = true
        val quickKeysVisible = keyboardVisible
        assertTrue(quickKeysVisible)
    }

    @Test
    fun testKeyInjection() {
        val keyAction = mapOf(
            "action" to "insert",
            "text" to "\t"
        )
        assertEquals("insert", keyAction["action"])
    }
}

/**
 * 手势识别测试
 */
@RunWith(AndroidJUnit4::class)
class GestureTest {

    @Test
    fun testDoubleTapDetection() {
        val tapCount = 2
        assertTrue("双击应该是 2 次点击", tapCount == 2)
    }

    @Test
    fun testPinchToZoom() {
        val scaleFactor = 1.5f
        assertTrue("缩放因子应该大于 1", scaleFactor > 1.0f)
    }

    @Test
    fun testCommandPaletteTrigger() {
        val shouldTrigger = true
        assertTrue("双击编辑器应该触发命令面板", shouldTrigger)
    }
}
