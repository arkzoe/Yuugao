import 'package:yuugao/CloudMusic/api/album/entity/album_info_entity.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_songs_entity.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/playlist_detail_entity.dart';
import 'package:yuugao/CloudMusic/api/recommend/entity/recommend_song_entity.dart';
import 'package:yuugao/CloudMusic/api/search/entity/search_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_detail_entity.dart';

/// 规范化封面 URL：协议相对 → https，明文 HTTP → HTTPS，其余不变。
String _safeUrl(String url) {
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return url.replaceFirst('http://', 'https://');
  return url;
}

/// 统一的 UI 歌曲模型。
///
/// 各接口返回的歌曲结构不同（每日推荐 / 歌单 track / 搜索 / 歌曲详情），
/// 通过工厂方法归一为同一模型，供播放器与列表统一消费。
class Song {
  final int id;
  final String name;
  final String artist;
  final List<int> artistIds;
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
    this.artistIds = const [],
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
    final ar = s.ar ?? [];
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: ar.map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromPlaylistTrack(PlaylistDetailPlaylistTracks t) {
    final ar = t.ar ?? [];
    return Song(
      id: t.id ?? 0,
      name: t.name ?? '',
      artist: ar.map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: t.al?.name ?? '',
      coverUrl: _safeUrl(t.al?.picUrl ?? ''),
      durationMs: t.dt ?? 0,
      fee: t.fee ?? 0,
    );
  }

  factory Song.fromSearchItem(SearchSongItem s) {
    final artists = s.artists ?? [];
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: artists.map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      artistIds: artists.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: s.album?.name ?? '',
      coverUrl: _safeUrl(s.album?.picUrl ?? ''),
      durationMs: s.duration ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromSongDetail(SongDetailSongs s) {
    final ar = s.ar ?? [];
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: ar.map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromAlbumTrack(AlbumInfoSongs s) {
    final ar = s.ar ?? [];
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: ar.map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  factory Song.fromArtistHotSong(ArtistHotSong s) {
    final ar = s.ar ?? [];
    return Song(
      id: s.id ?? 0,
      name: s.name ?? '',
      artist: ar.map((a) => a.name ?? '').where((n) => n.isNotEmpty).join(' / '),
      artistIds: ar.map((a) => a.id ?? 0).where((id) => id > 0).toList(),
      album: s.al?.name ?? '',
      coverUrl: _safeUrl(s.al?.picUrl ?? ''),
      durationMs: s.dt ?? 0,
      fee: s.fee ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Song && other.id == id && other.coverUrl == coverUrl;

  @override
  int get hashCode => Object.hash(id, coverUrl);
}
