import 'dart:io';

import 'package:flutter/services.dart';

/// Android 平台服务：WiFi 锁管理。
///
/// 统一使用 MethodChannel `com.example.yuugao/platform` 与原生层通信。
class PlatformService {
  static const _channel = MethodChannel('com.example.yuugao/platform');

  /// 获取高性能 WiFi 锁，防止息屏后 WiFi 进入低功耗模式导致流式连接断开。
  static Future<bool> acquireWifiLock() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('acquireWifiLock') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 释放 WiFi 锁。
  static Future<bool> releaseWifiLock() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('releaseWifiLock') ?? false;
    } catch (_) {
      return false;
    }
  }
}
