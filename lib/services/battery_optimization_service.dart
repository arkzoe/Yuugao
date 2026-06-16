import 'dart:io';

import 'package:flutter/services.dart';

/// Android 平台服务：WiFi 锁 + CPU 唤醒锁管理。
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

  /// 获取 PARTIAL_WAKE_LOCK，防止息屏后 CPU 休眠导致流式解码中断。
  ///
  /// WiFi 锁只保证 WiFi 模块不进入低功耗模式，但 CPU 仍可能被 Doze 挂起，
  /// 导致 just_audio 解码/缓冲线程停顿。PARTIAL_WAKE_LOCK 确保 CPU 持续运行。
  static Future<bool> acquireWakeLock() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('acquireWakeLock') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 释放 CPU 唤醒锁。
  static Future<bool> releaseWakeLock() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('releaseWakeLock') ?? false;
    } catch (_) {
      return false;
    }
  }
}
