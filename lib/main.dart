import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/app.dart';
import 'package:yuugao/services/cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 后台播放 / 通知栏控件
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yuugao.channel.audio',
    androidNotificationChannelName: 'yuugao 播放',
    androidNotificationOngoing: true,
  );

  // API 层初始化（cookie 持久化路径）
  final docs = await getApplicationDocumentsDirectory();
  await BujuanMusicManager().init(cookiePath: '${docs.path}/.cookies');

  // 缓存索引
  await CacheService.instance.init();

  runApp(const ProviderScope(child: YuugaoApp()));
}
