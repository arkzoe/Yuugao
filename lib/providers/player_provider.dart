import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:yuugao/models/song.dart';
import 'package:yuugao/services/audio_service.dart';

enum PlayMode { sequential, shuffle, repeatOne }

class PlayerState {
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final PlayMode mode;
  final Duration position;
  final Duration duration;
  final bool buffering;

  const PlayerState({
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.mode = PlayMode.sequential,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffering = false,
  });

  Song? get current =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  bool get hasSong => current != null;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  PlayerState copyWith({
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    PlayMode? mode,
    Duration? position,
    Duration? duration,
    bool? buffering,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      mode: mode ?? this.mode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffering: buffering ?? this.buffering,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerState()) {
    _bind();
  }

  final _audio = AudioService.instance;

  void _bind() {
    _audio.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _audio.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });
    _audio.currentIndexStream.listen((idx) {
      if (idx != null) state = state.copyWith(currentIndex: idx);
    });
    _audio.playerStateStream.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        buffering: ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering,
      );
    });
  }

  /// 播放一首歌，可附带其所属队列。无队列时单曲成队。
  Future<void> play(Song song, {List<Song>? queue}) async {
    final list = queue ?? [song];
    var index = list.indexWhere((s) => s.id == song.id);
    if (index < 0) index = 0;
    state = state.copyWith(queue: list, currentIndex: index);
    await _audio.setQueue(list, initialIndex: index);
  }

  Future<void> toggle() => _audio.toggle();
  Future<void> next() => _audio.next();
  Future<void> prev() => _audio.previous();
  Future<void> seek(Duration pos) => _audio.seek(pos);
  Future<void> playAt(int index) => _audio.playAt(index);

  Future<void> appendAndPlay(Song song) async {
    await _audio.appendAndPlay(song);
    state = state.copyWith(queue: _audio.queue);
  }

  Future<void> setMode(PlayMode mode) async {
    state = state.copyWith(mode: mode);
    switch (mode) {
      case PlayMode.sequential:
        await _audio.setShuffle(false);
        await _audio.setLoopMode(LoopMode.all);
        break;
      case PlayMode.shuffle:
        await _audio.setLoopMode(LoopMode.all);
        await _audio.setShuffle(true);
        break;
      case PlayMode.repeatOne:
        await _audio.setShuffle(false);
        await _audio.setLoopMode(LoopMode.one);
        break;
    }
  }

  /// 循环切换播放模式
  Future<void> cycleMode() {
    final next = PlayMode.values[(state.mode.index + 1) % PlayMode.values.length];
    return setMode(next);
  }
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});
