import 'package:flutter/foundation.dart';

/// 性能打点开关。
///
/// 默认**关闭**——生产包里 [kPerf] 是编译期常量 false，
/// [perfMark] 里的整段代码会被 tree-shaking 掉，运行时零开销。
///
/// 需要在真机上量性能时重新打一个带开关的包：
/// ```
/// flutter build apk --release --dart-define=PERF=true
/// ```
/// 打点会出现在 `adb logcat -s flutter` 里。
const bool kPerf = bool.fromEnvironment('PERF');

/// 打一个带微秒时间戳的标记。
///
/// 时间戳用单调时钟之外的墙钟（[DateTime.now]）：
/// 跨设备比对时墙钟更直观（同机对比也够用——间隔就是间隔）。
void perfMark(String label) {
  if (!kPerf) return;
  // ignore: avoid_print
  debugPrint('⏱ $label @${DateTime.now().microsecondsSinceEpoch}');
}
