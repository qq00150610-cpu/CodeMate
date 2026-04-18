# =============================================================================
# CodeMate ProGuard 混淆规则
# =============================================================================
# 用于 Release 构建时的代码压缩和混淆配置
# =============================================================================

# Flutter 相关
# -----------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter WebView 插件
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Provider
-keep class provider.** { *; }
-keep class * extends provider.ChangeNotifier { *; }

# Dart 相关
# -----------------------------------------------------------------------
-keep class dart:** { *; }
-keep class * extends dart:core. Object { *; }

# Kotlin 相关
# -----------------------------------------------------------------------
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# AndroidX 相关
# -----------------------------------------------------------------------
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Material Design
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Android 原生组件
# -----------------------------------------------------------------------
-keep class * extends android.app.Activity { *; }
-keep class * extends android.app.Application { *; }
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
-keep class * extends android.content.ContentProvider { *; }

# MethodChannel 通信
# -----------------------------------------------------------------------
-keep class * extends io.flutter.plugin.common.MethodChannel { *; }
-keep class * implements io.flutter.plugin.common.BinaryMessenger { *; }

# JSON 解析
# -----------------------------------------------------------------------
-keep class org.json.** { *; }
-keepclassmembers class * {
    @org.json.* <fields>;
}

# WebView 相关
# -----------------------------------------------------------------------
-keep class android.webkit.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep native methods
# -----------------------------------------------------------------------
-keepclasseswithmembernames class * {
    native <methods>;
}

# ViewBinding
# -----------------------------------------------------------------------
-keep class * implements androidx.viewbinding.ViewBinding {
    public static ** inflate(android.view.LayoutInflater);
    public static ** inflate(android.view.LayoutInflater, android.view.ViewGroup, boolean);
}

# 枚举类
# -----------------------------------------------------------------------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
# -----------------------------------------------------------------------
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Serializable
# -----------------------------------------------------------------------
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# R8 全量优化模式
# -----------------------------------------------------------------------
# 允许 R8 优化所有代码
-allowaccessmodification
-repackageclasses

# 保留行号信息（用于调试）
-keepattributes SourceFile,LineNumberTable

# 保留注解
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# 混淆时抛出异常
# --renamesourcefileattribute SourceFile
# -addconfigurationdebuggable
