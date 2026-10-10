# Readnest / reading-tracker 的 R8（release 压缩）规则。
#
# 背景：google_mlkit_text_recognition 在 TextRecognizer.initialize() 里用
# 反射式懒加载引用多种语言识别器（中文 / 日文 / 韩文 / 天城文）。本项目只
# 依赖拉丁 + 中文两套模型，其余几种在 APK 里不存在，R8 在压缩阶段会因
# "Missing class" 直接失败。
#
# 处理方式两层：
#   1) 本文件用 -dontwarn 明确放行这些「按需加载、缺了也不影响主流程」的类；
#   2) 真正的模型依赖（中文）声明在 app/build.gradle 的 dependencies 里，
#      保证运行时确实存在，不会被误删。
#
# 注意：不要用 -keep 强留这些类——它们本就不在 APK 中，keep 只会掩盖问题。

# --- ML Kit 文本识别：可选语言模型 ---
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# --- ML Kit 内部可选的日志 / 遥测实现 ---
-dontwarn com.google.mlkit.common.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text.**

# --- Play Core（动态交付 / 按需下载模块）---
# Flutter 引擎的 FlutterPlayStoreSplitApplication 与
# PlayStoreDeferredComponentManager 会引用 Play Core 的拆分安装 API。
# 本项目不使用 deferred components（也没引入 play-core 依赖），
# 相关类在 APK 中不存在，属「引用了但不会走到」的可选路径，放行即可。
# 若将来真要启用 deferred components，须改为 implementation 引入 play-core，
# 而不是继续 -dontwarn。
-dontwarn com.google.android.play.core.**

# --- Gson：泛型签名必须保留 ---
#
# 背景：flutter_local_notifications 用 Gson 的 `TypeToken` 反序列化已排期的
# 通知。TypeToken 靠 **匿名子类的泛型签名** 拿到目标类型，一旦压缩时把
# Signature 属性丢掉，构造 TypeToken 就抛
#   IllegalStateException: TypeToken must be created with a type argument
#
# 这一点在 release 包上是致命的：调用发生在 Android 组件的入口
# （ScheduledNotificationBootReceiver.onReceive），异常会升级成
# FATAL EXCEPTION 并把整个进程 SIG:9 杀掉——用户看到的就是「打开即闪退」，
# 且 Dart 层的 try/catch 完全接不住（进程级崩溃，不是 Dart 异常）。
#
# 即使当前把 minifyEnabled 显式关掉了（见 build.gradle 的说明），
# 这组规则也必须留着：**将来任何人打开压缩都会重新踩同一个坑**。
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
# TypeToken 的匿名子类：这批内部类承载泛型信息，不能被删
-keepclassmembers class * extends com.google.gson.reflect.TypeToken { *; }
# SerializedName 标注的字段按名反射查找，改了名就取不到值
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# --- flutter_local_notifications ---
# 插件的类与内部类由系统与插件双向反射引用，$a 这种匿名内部类
# （承载 TypeToken 子类）尤其不能被删。
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# --- 保留插件与 Flutter 引擎的入口（避免被误删） ---
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
# 本项目 Android 入口类；包名必须与 namespace / Manifest 一致
-keep class io.github.ltong9463.readnest.MainActivity { *; }

# 插件注册器由 Flutter 工具生成，反射调用
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
