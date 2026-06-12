import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/user/entity/user_playlist_entity.dart';
import 'package:yuugao/providers/user_provider.dart';

class PlaylistState {
  final List<UserPlaylistPlaylist> created;
  final List<UserPlaylistPlaylist> subscribed;
  final Set<int> likedSongIds;
  final bool loading;

  const PlaylistState({
    this.created = const [],
    this.subscribed = const [],
    this.likedSongIds = const {},
    this.loading = false,
  });

  /// 第一个歌单通常是"我喜欢的音乐"
  UserPlaylistPlaylist? get likedPlaylist =>
      created.isNotEmpty ? created.first : null;

  PlaylistState copyWith({
    List<UserPlaylistPlaylist>? created,
    List<UserPlaylistPlaylist>? subscribed,
    Set<int>? likedSongIds,
    bool? loading,
  }) {
    return PlaylistState(
      created: created ?? this.created,
      subscribed: subscribed ?? this.subscribed,
      likedSongIds: likedSongIds ?? this.likedSongIds,
      loading: loading ?? this.loading,
    );
  }
}

class PlaylistNotifier extends Notifier<PlaylistState> {
  @override
  PlaylistState build() => const PlaylistState();

  late final _api = BujuanMusicManager();

  Future<void> fetchAll() async {
    final uid = ref.read(userProvider).uid;
    if (uid == null) return;
    state = state.copyWith(loading: true);
    await Future.wait([
      _fetchPlaylists(uid),
      _fetchLikedSongs(uid),
    ]);
    state = state.copyWith(loading: false);
  }

  Future<void> _fetchPlaylists(int uid) async {
    try {
      final res = await _api.userPlaylist(uid: uid.toString(), limit: 100);
      final all = res?.playlist ?? [];
      final created = <UserPlaylistPlaylist>[];
      final subscribed = <UserPlaylistPlaylist>[];
      for (final p in all) {
        if (p.userId == uid) {
          created.add(p);
        } else {
          subscribed.add(p);
        }
      }
      state = state.copyWith(created: created, subscribed: subscribed);
    } catch (_) {}
  }

  Future<void> _fetchLikedSongs(int uid) async {
    try {
      final ids = <int>[];
      int? cursor; // checkPoint 作为分页游标
      var safety = 0;
      while (safety < 20) {
        safety++;
        final res = await _api.userLikeList(
          uid: uid.toString(),
          offset: cursor,
        );
        if (res?.ids != null) ids.addAll(res!.ids!);
        final cp = res?.checkPoint ?? 0;
        if (cp <= 0 || cp == cursor) break; // 无更多数据或游标未推进
        cursor = cp;
      }
      state = state.copyWith(likedSongIds: ids.toSet());
    } catch (_) {}
  }

  bool isLiked(int songId) => state.likedSongIds.contains(songId);

  /// 喜欢/取消喜欢。乐观更新 + 失败回滚。
  /// 注：songLike 真实响应可能无 data 字段，故以 code==200 判定成功。
  Future<bool> toggleLike(int songId) async {
    final liked = isLiked(songId);
    final newSet = Set<int>.from(state.likedSongIds);
    if (liked) {
      newSet.remove(songId);
    } else {
      newSet.add(songId);
    }
    state = state.copyWith(likedSongIds: newSet); // 乐观更新

    try {
      final res = await _api.songLike(id: songId, like: !liked);
      final ok = res?.code == 200 || res?.data == true;
      if (!ok) {
        // 回滚
        state = state.copyWith(likedSongIds: state.likedSongIds);
        final rollback = Set<int>.from(state.likedSongIds);
        if (liked) {
          rollback.add(songId);
        } else {
          rollback.remove(songId);
        }
        state = state.copyWith(likedSongIds: rollback);
        return false;
      }
      return true;
    } catch (_) {
      final rollback = Set<int>.from(state.likedSongIds);
      if (liked) {
        rollback.add(songId);
      } else {
        rollback.remove(songId);
      }
      state = state.copyWith(likedSongIds: rollback);
      return false;
    }
  }

  void clear() => state = const PlaylistState();
}

final playlistProvider =
    NotifierProvider<PlaylistNotifier, PlaylistState>(PlaylistNotifier.new);
