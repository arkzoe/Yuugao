import 'package:yuugao/CloudMusic/api/album/entity/album_info_entity.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_songs_entity.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/playlist_detail_entity.dart';
import 'package:yuugao/CloudMusic/api/recommend/entity/recommend_song_entity.dart';
import 'package:yuugao/CloudMusic/api/search/entity/search_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_detail_entity.dart';

/// 将 http:// 强制转为 https://，网易云 CDN 对明文请求返回 403。
String _safeUrl(String url) =>
    url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;

/// 统一的 UI 歌曲模型。
///
/// 各接口返回的歌曲结构不同（每日推荐 / 歌单 track / 搜索 / 歌曲详情），
/// 通过工厂方法归一为同一模型，供播放器与列表统一消费。
class Song {
  final int id;
  final String name;
  final String artist;
  final String album;
  final String coverUrl;

  /// 时长（毫秒）；0 表示未知
  final int durationMs;

  /// 付费标记（>0 通常为 VIP）
  final int fee;

  const Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.coverUrl,
    this.durationMs = 0,
    this.fee = 0,
  });

  /// 高清封面（按需追加尺寸参数）
  String coverThumb(int px) =>
      coverUrl.isEmpty ? coverUrl : '$coverUrl?param=${px}y$px';

  Duration get duration => Duration(milliseconds: durationMs);

  factory Song.fromDailySong(RecommendSongDataDailySongs s) {
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: (s.ar ?? []).map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromPlaylistTrack(PlaylistDetailPlaylistTracks t) {
    return Song(
      id: t.id ?? 0,
      name: t.name ?? '',
      artist: (t.ar ?? []).map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      album: t.al?.name ?? '',
      coverUrl: _safeUrl(t.al?.picUrl ?? ''),
      durationMs: t.dt ?? 0,
      fee: t.fee ?? 0,
    );
  }

  factory Song.fromSearchItem(SearchSongItem s) {
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: (s.artists ?? []).map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      album: s.album?.name ?? '',
      coverUrl: _safeUrl(s.album?.picUrl ?? ''),
      durationMs: s.duration ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromSongDetail(SongDetailSongs s) {
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: (s.ar ?? []).map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromAlbumTrack(AlbumInfoSongs s) {
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: (s.ar ?? []).map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromArtistHotSong(ArtistHotSong s) {
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: (s.ar ?? []).map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
