import 'dart:convert';

import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/song/entity/comment_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/new_song_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_detail_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_lyric_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_quality_detail_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_like_check_entity.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_url_entity.dart';
import 'package:yuugao/CloudMusic/api/user/entity/bool_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/services/metadata_cache_service.dart';

mixin SongApi {
  /// 新歌速递
  ///
  /// [type] 全部:0 华语:7 欧美:96 日本:8 韩国:16
  /// [total] 默认为true
  Future<NewSongEntity?> newSongs({int type = 0, bool total = true}) async {
    final data = {'areaId': type, 'total': total};
    return await BujuanMusicManager().post<NewSongEntity>(
      url: Api.newSongs,
      data: data,
    );
  }

  ///歌曲地址
  ///
  /// [ids] 歌曲id数组
  /// [level] standard, exhigh, lossless, hires, jyeffect(高清环绕声), sky(沉浸环绕声), jymaster(超清母带) 进行音质判断
  /// [encodeType] 编码类型 默认 flac
  Future<SongUrlEntity?> songUrl({
    required List<String> ids,
    String level = 'jyeffect',
    String encodeType = 'flac',
  }) async {
    final data = {
      'ids': ids,
      'level': level,
      'encodeType': encodeType,
      'immerseType': level == 'sky' ? 'c51' : null,
    };
    return await BujuanMusicManager().post<SongUrlEntity>(
      url: Api.songUrl,
      data: data,
    );
  }

  /// 歌曲详情
  /// [ids] 歌曲id数组 不可超过1000
  Future<SongDetailEntity?> songDetail({required List<int> ids}) async {
    if (ids.length > 1000) {
      return SongDetailEntity()
        ..songs = []
        ..code = -1;
    }
    final data = {
      "c": jsonEncode(ids.map((id) => {"id": id}).toList()),
    };
    return await BujuanMusicManager().post<SongDetailEntity>(
      url: Api.songDetail,
      data: data,
    );
  }

  /// 检查歌曲是否被喜欢
  /// [ids] 歌曲id数组
  Future<SongLikeCheckEntity?> songLikeCheck({
    required List<String> ids,
  }) async {
    final data = {'trackIds': ids};
    return await BujuanMusicManager().post<SongLikeCheckEntity>(
      url: Api.songLikeCheck,
      data: data,
    );
  }

  /// 歌曲音质详情
  /// [id] 歌曲id
  Future<SongQualityDetailEntity?> songQualityDetail({required int id}) async {
    final data = {'songId': id};
    return await BujuanMusicManager().post<SongQualityDetailEntity>(
      url: Api.songQualityDetail,
      data: data,
    );
  }

  /// 歌词
  /// [id] 歌曲id
  ///
  /// 需带上 lv/kv/tv 版本参数，否则接口返回空歌词。
  /// -1 表示请求最新版本：lv 原文、kv 逐字、tv 翻译。
  Future<SongLyricEntity?> songLyric({required String id}) async {
    final data = {
      'id': id,
      'lv': -1,
      'kv': -1,
      'tv': -1,
    };
    return await BujuanMusicManager().post<SongLyricEntity>(
      url: Api.songLyric,
      data: data,
    );
  }

  /// 歌曲被喜欢数量
  /// [id] 歌曲id
  /// TODO: 创建 SongLikeCountEntity 替代 dynamic，需先确认 /api/song/red/count 响应结构
  Future<dynamic> songLikeCount({required int id}) async {
    final data = {'songId': id};
    return await BujuanMusicManager().post(url: Api.songLikeCount, data: data);
  }

  /// 喜欢/取消喜欢歌曲
  /// [id] 歌曲id
  /// [like] true=喜欢 false=取消
  ///
  /// 注：真实响应通常为 {code: 200}，BoolEntity.data 可能恒为 null，
  /// 业务层应以 code==200 判断成功（见 BujuanMusicManager 调用方）。
  Future<BoolEntity?> songLike({required int id, bool like = true}) async {
    final data = {'trackId': id, 'like': like};
    return await BujuanMusicManager().post<BoolEntity>(
      url: Api.songLike,
      data: data,
    );
  }

  /// 歌曲评论
  /// [id] 歌曲id
  /// [limit] 每页数量
  /// [offset] 偏移
  Future<CommentEntity?> songComments({
    required int id,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = {'rid': id, 'limit': limit, 'offset': offset};
    return await BujuanMusicManager().post<CommentEntity>(
      url: '${Api.songComments}$id',
      data: data,
    );
  }

  // ═══ Cache-First 封装 ═══

  /// 歌曲详情（缓存优先）。
  ///
  /// 先从本地缓存读取即时返回，同时后台请求最新数据并更新缓存。
  /// [onResult] 在数据就绪时回调（缓存命中可能回调两次：缓存 + 最新）。
  Future<SongDetailEntity?> songDetailCached({
    required List<int> ids,
    void Function(SongDetailEntity data)? onResult,
  }) async {
    SongDetailEntity? last;

    // 1. 尝试缓存
    if (ids.length == 1) {
      final cached = await MetadataCacheService.instance.getTrackDetail(ids.first);
      if (cached != null) {
        try {
          last = SongDetailEntity.fromJson(cached);
          onResult?.call(last);
        } catch (_) {}
      }
    }

    // 2. 请求最新
    final fresh = await songDetail(ids: ids);
    if (fresh != null && fresh.code == 200) {
      if (ids.length == 1 && fresh.songs?.isNotEmpty == true) {
        MetadataCacheService.instance.cacheTrackDetail(
          ids.first,
          fresh.toJson(),
        );
      }
      if (fresh != last) {
        onResult?.call(fresh);
        last = fresh;
      }
    }

    return last;
  }

  /// 歌词（缓存优先）。
  ///
  /// 先从本地缓存读取即时返回，同时后台请求最新数据并更新缓存。
  /// [onResult] 在数据就绪时回调（缓存命中可能回调两次：缓存 + 最新）。
  Future<SongLyricEntity?> songLyricCached({
    required String id,
    void Function(SongLyricEntity data)? onResult,
  }) async {
    SongLyricEntity? last;
    final songId = int.tryParse(id);

    // 1. 尝试缓存
    if (songId != null) {
      final cached = await MetadataCacheService.instance.getLyric(songId);
      if (cached != null) {
        try {
          last = SongLyricEntity.fromJson(cached);
          onResult?.call(last);
        } catch (_) {}
      }
    }

    // 2. 请求最新
    final fresh = await songLyric(id: id);
    if (fresh != null && fresh.code == 200) {
      if (songId != null) {
        MetadataCacheService.instance.cacheLyric(songId, fresh.toJson());
      }
      if (fresh != last) {
        onResult?.call(fresh);
        last = fresh;
      }
    }

    return last;
  }
}
