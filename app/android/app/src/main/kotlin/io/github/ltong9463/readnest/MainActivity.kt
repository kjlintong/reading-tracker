package io.github.ltong9463.readnest

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 主 Activity。除了承载 Flutter，另开一条 MethodChannel 给「系统设置」用。
 *
 * ## 为什么需要这条通道
 *
 * 阅读计划提醒是**本地通知**：闹钟由 AlarmManager 持有，App 进程不在时
 * 由系统的 ScheduledNotificationReceiver 拉起并弹通知。它能送达，取决于
 * 三件用户侧的事：
 *
 *  1. 通知权限（Android 13+ 的 POST_NOTIFICATIONS）；
 *  2. 通知渠道没被关掉；
 *  3. **系统没把本 App 的后台掐掉**——国产 ROM（小米/华为/OPPO/vivo）
 *     的「省电策略」「自启动」一旦没开，会直接清掉 AlarmManager 里的闹钟，
 *     于是用户看到的现象是「只有打开 App 才收得到提醒」。
 *
 * 这三件事都不在 App 里，用户只能自己去系统设置里改。App 该做的是
 * **把入口摆在用户手边**，并且**如实告诉他当前是什么状态**。
 * 打开系统设置页需要 Intent，Flutter 侧没有能发 Intent 的能力
 * （url_launcher 只支持 http/tel/mailto 之类的协议），
 * 所以在这里开一条通道。
 */
class MainActivity : FlutterActivity() {

    private val channelName = "io.github.ltong9463.readnest/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" ->
                        result.success(openNotificationSettings())
                    "openBatteryOptimizationSettings" ->
                        result.success(openBatteryOptimizationSettings())
                    "openAutoStartSettings" ->
                        result.success(openAutoStartSettings())
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "romBrand" ->
                        result.success(romBrand())
                    else -> result.notImplemented()
                }
            }
    }

    /** 本 App 的通知设置页（渠道列表 + 通知开关）。 */
    private fun openNotificationSettings(): Boolean {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        if (startSafely(intent)) return true
        return openAppDetails()
    }

    /**
     * 电池优化「不受限制」列表页。
     *
     * 用列表页而不是 `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`：
     * 后者需要 `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 权限，而 Google Play
     * 只允许「闹钟/计时器类」App 申请它——一个读书打卡 App 申请必被拒。
     * 列表页不需要任何权限，用户自己找到本 App 点一下就行。
     */
    private fun openBatteryOptimizationSettings(): Boolean {
        if (startSafely(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))) {
            return true
        }
        return openAppDetails()
    }

    /**
     * 「自启动」管理页。
     *
     * 各家 ROM 的入口 Activity 名都不一样，而且改版就会变，
     * 所以这里**按品牌逐个试**，全都失败才回落到应用详情页
     * （详情页里各家 ROM 一般也放了省电/自启动的入口）。
     *
     * 刻意不用 `resolveActivity` 预检：Android 11 起的包可见性规则会
     * 让系统设置里的 Activity「查不到」，预检会全部落空。
     * 直接 startActivity 捕获异常更稳。
     */
    private fun openAutoStartSettings(): Boolean {
        val candidates = listOf(
            // 小米 MIUI / HyperOS
            ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            ),
            // 华为 EMUI / HarmonyOS
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            ),
            ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.optimize.process.ProtectActivity"
            ),
            // OPPO ColorOS / 一加
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity"
            ),
            ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.startupapp.StartupAppListActivity"
            ),
            // vivo OriginOS / iQOO
            ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            ),
            ComponentName(
                "com.iqoo.secure",
                "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
            ),
            // 三星 One UI
            ComponentName(
                "com.samsung.android.lool",
                "com.samsung.android.sm.battery.ui.BatteryActivity"
            )
        )
        for (c in candidates) {
            if (startSafely(Intent().setComponent(c))) return true
        }
        return openAppDetails()
    }

    /** 应用详情页（最后的兜底：绝大多数 ROM 在这里放了省电/自启动入口）。 */
    private fun openAppDetails(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null)
        )
        return startSafely(intent)
    }

    private fun startSafely(intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 本 App 是否已被排除在电池优化之外。
     *
     * 查询不需要任何权限（只有「请求豁免」才需要）。
     */
    private fun isIgnoringBatteryOptimizations(): Boolean {
        return try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } catch (e: Exception) {
            false
        }
    }

    /**
     * ROM 品牌标记。用来决定要不要给用户「允许自启动」的入口——
     * 原生 AOSP/Google Pixel 没有这个概念，给了反而是噪音。
     */
    private fun romBrand(): String {
        val branded = mapOf(
            "ro.miui.ui.version.name" to "miui",
            "ro.build.version.opporom" to "coloros",
            "ro.build.version.oplusrom" to "coloros",
            "ro.build.version.emui" to "emui",
            "ro.build.version.harmony" to "harmony",
            "ro.vivo.os.version" to "originos",
            "ro.iqoo.os.version" to "iqoo"
        )
        for ((key, brand) in branded) {
            if (!readProp(key).isNullOrBlank()) return brand
        }
        if (!readProp("ro.build.version.oneplus").isNullOrBlank()) return "oneplus"
        if (!readProp("ro.build.version.samsung").isNullOrBlank()) return "oneui"
        return ""
    }

    private fun readProp(key: String): String? = try {
        @Suppress("PrivateApi")
        val clazz = Class.forName("android.os.SystemProperties")
        val get = clazz.getMethod("get", String::class.java)
        get.invoke(null, key) as? String
    } catch (e: Exception) {
        null
    }
}
