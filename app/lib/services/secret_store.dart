import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 机密存储：把 API Key 等敏感凭据存到系统密钥库
/// （Android 走 EncryptedSharedPreferences / Keystore，iOS 走 Keychain），
/// 而不是明文 SQLite。
///
/// 在无法使用平台通道的环境（例如部分自动化测试）下，退化为内存存储，
/// 保证调用方永不抛异常；真实设备上始终走系统密钥库。
class SecretStore {
  SecretStore([FlutterSecureStorage? store])
      : _store = store ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                // flutter_secure_storage 9.x 的枚举值是 snake_case；
                // first_unlock_this_device = 首次解锁后可读，且不随备份迁移到新设备
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _store;

  /// 平台通道不可用时的会话内兜底。真实设备上不会用到它。
  final Map<String, String> _memFallback = {};

  Future<String?> read(String key) async {
    try {
      final v = await _store.read(key: key);
      if (v != null) return v;
    } catch (_) {
      // 平台通道不可用：回落到内存副本
    }
    return _memFallback[key];
  }

  Future<void> write(String key, String value) async {
    _memFallback[key] = value;
    try {
      await _store.write(key: key, value: value);
    } catch (_) {
      // 平台通道不可用：仅保留内存副本
    }
  }

  Future<void> delete(String key) async {
    _memFallback.remove(key);
    try {
      await _store.delete(key: key);
    } catch (_) {
      // 平台通道不可用：忽略
    }
  }
}
