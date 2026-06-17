import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/pages/daily_songs_page.dart';
import 'package:yuugao/pages/cloud_page.dart';
import 'package:yuugao/pages/podcast_search_page.dart';
import 'package:yuugao/providers/player_provider.dart';
import 'package:yuugao/providers/settings_provider.dart';
import 'package:yuugao/widgets/player_panel.dart';

/// 首页四个功能入口：每日 / FM / 播客 / 云盘。
class HomeActionButtons extends ConsumerWidget {
  const HomeActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentColorsProvider);
    final items = [
      (
        _Action(Icons.calendar_month, '每日', Colors.grey),
        () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DailySongsPage()));
        },
      ),
      (
        _Action(Icons.radio, 'FM', Colors.grey),
        () => _startFmAndShowPlayer(ref),
      ),
      (
        _Action(Icons.sensors, '播客', Colors.grey),
        () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PodcastSearchPage()));
        },
      ),
      (
        _Action(Icons.cloud_queue, '云盘', Colors.grey),
        () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CloudPage()));
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((e) {
        final action = e.$1;
        return _ActionButton(
          action: action,
          onTap: e.$2,
          textColor: colors.textPrimary,
        );
      }).toList(),
    );
  }

  /// 启动 FM 并打开已有的播放面板
  Future<void> _startFmAndShowPlayer(WidgetRef ref) async {
    final ok = await ref.read(playerProvider.notifier).startFm();
    if (ok) {
      // 通过全局 PanelController 打开已有面板，不 push 新页面
      final ctrl = ref.read(panelControllerProvider);
      ctrl?.open();
    }
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  _Action(this.icon, this.label, this.color);
}

class _ActionButton extends StatelessWidget {
  final _Action action;
  final VoidCallback onTap;
  final Color textColor;
  const _ActionButton({
    required this.action,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(action.icon, color: action.color, size: 26),
          const SizedBox(height: 4),
          Text(action.label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }
}
