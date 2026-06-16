import 'package:yuugao/CloudMusic/api/podcast/entity/dj_program_entity.dart';
import 'package:yuugao/models/song.dart';

/// UI 层统一的播客节目模型。
///
/// 播客节目通过 [DjProgramItem.mainSong.id] 关联到一首网易云歌曲，
/// [toSong] 桥接到现有的 AudioService / PlayerProvider 播放管线。
class PodcastEpisode {
  final int voiceId;
  final int songId;
  final String name;
  final String podcastName;
  final String coverUrl;
  final int durationMs;
  final String description;
  final int playCount;
  final int likedCount;

  const PodcastEpisode({
    required this.voiceId,
    required this.songId,
    required this.name,
    required this.podcastName,
    required this.coverUrl,
    this.durationMs = 0,
    this.description = '',
    this.playCount = 0,
    this.likedCount = 0,
  });

  factory PodcastEpisode.fromDjProgram(DjProgramItem item,
      {String podcastName = ''}) {
    return PodcastEpisode(
      voiceId: item.id ?? 0,
      songId: item.mainSong?.id ?? 0,
      name: item.name ?? '',
      podcastName: podcastName.isNotEmpty
          ? podcastName
          : item.dj?.nickname ?? '',
      coverUrl: item.radio?.picUrl ?? '',
      durationMs: item.duration ?? 0,
      description: item.description ?? '',
      playCount: item.listenerCount ?? 0,
      likedCount: item.likedCount ?? 0,
    );
  }

  /// 转换为 Song 以接入现有播放器管线。
  ///
  /// artist 字段填播客/主播名，album 留空。
  Song toSong() => Song(
        id: songId,
        name: name,
        artist: podcastName.isNotEmpty ? podcastName : '播客',
        album: '',
        coverUrl: coverUrl,
        durationMs: durationMs,
      );

  PodcastEpisode copyWith({
    int? voiceId,
    int? songId,
    String? name,
    String? podcastName,
    String? coverUrl,
    int? durationMs,
    String? description,
    int? playCount,
    int? likedCount,
  }) {
    return PodcastEpisode(
      voiceId: voiceId ?? this.voiceId,
      songId: songId ?? this.songId,
      name: name ?? this.name,
      podcastName: podcastName ?? this.podcastName,
      coverUrl: coverUrl ?? this.coverUrl,
      durationMs: durationMs ?? this.durationMs,
      description: description ?? this.description,
      playCount: playCount ?? this.playCount,
      likedCount: likedCount ?? this.likedCount,
    );
  }
}
