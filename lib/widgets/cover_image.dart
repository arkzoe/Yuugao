import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:yuugao/theme.dart';

/// 统一封面图：圆角 + 占位 + 错误兜底。
class CoverImage extends StatelessWidget {
  final String url;
  final double size;
  final double radius;

  const CoverImage({
    super.key,
    required this.url,
    this.size = 48,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    // 网易云封面常返回 http 链接，Android 默认禁止明文流量会导致图片加载失败，
    // 统一升级为 https。
    final safeUrl = url.startsWith('http://')
        ? url.replaceFirst('http://', 'https://')
        : url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: !safeUrl.startsWith('http')
          ? _placeholder()
          : CachedNetworkImage(
              imageUrl: safeUrl,
              // 网易云图片 CDN 校验来源，缺少 Referer / UA 会返回 403，
              // 导致所有封面都加载失败回退到占位图。
              httpHeaders: const {
                'Referer': 'https://music.163.com',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                        '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
              },
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) => _placeholder(),
              errorWidget: (_, _, _) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    final box = size.isFinite ? size : null;
    final iconSize = size.isFinite ? size * 0.5 : 24.0;
    return Container(
      width: box,
      height: box,
      color: AppColors.card,
      child: Icon(Icons.music_note,
          color: AppColors.textSecondary, size: iconSize),
    );
  }
}
