import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/catalogue_entity.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/create_playlist_entity.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/high_quality_tags_entity.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/intelligence_list_entity.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/playlist_detail_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';

import '../user/entity/bool_entity.dart';
import '../user/entity/string_entity.dart';

mixin PlaylistApi {
  /// 歌单分类
  ///
  Future<CatalogueEntity?> playlistCatalogue() async {
    return await MusicManager().post<CatalogueEntity>(
      url: Api.playlistCatalogue,
    );
  }

  ///创建歌单
  ///
  /// [name] 歌单名称（必选）
  /// [privacy] 歌单隐私状态（必选）0 普通歌单 1 隐私歌单）
  /// [type] 歌单类型（可选 NORMAL|VIDEO|SHARED）
  Future<CreatePlaylistEntity?> createPlaylist({
    required String name,
    required int privacy,
    String type = 'NORMAL',
  }) async {
    final data = {'name': name, 'privacy': privacy, 'type': type};
    return await MusicManager().post<CreatePlaylistEntity>(
      url: Api.createPlaylist,
      data: data,
    );
  }

  /// 删除歌单
  ///
  /// [ids]要删除的歌单id（必选）
  Future<StringEntity?> removePlaylist({required List<String> ids}) async {
    return await MusicManager().post<StringEntity>(
      url: Api.removePlaylist,
      data: {'ids': ids},
    );
  }

  /// 更新歌单描述
  ///
  /// [id] 歌单id（必选）
  Future<StringEntity?> updatePlaylistDesc({
    required int id,
    required String desc,
  }) async {
    return await MusicManager().post<StringEntity>(
      url: Api.updatePlaylistDesc,
      data: {'id': id, 'desc': desc},
    );
  }

  /// 歌单详情
  ///
  /// [id] 歌单id（必选）
  /// [n] 单次返回歌曲数（必选，默认 1000）
  /// [s] 歌曲排序方式（默认 8）
  /// [offset] 分页偏移量，从第几首开始拉取
  Future<PlaylistDetailEntity?> playlistDetail({
    required int id,
    int n = 1000,
    int s = 8,
    int? offset,
    bool dynamic = false,
  }) async {
    final data = {
      'id': id,
      'n': n,
      's': s,
      // ignore: use_null_aware_elements
      if (offset != null) 'offset': offset,
    };
    return await MusicManager().post<PlaylistDetailEntity>(
      url: dynamic ? Api.playlistDetailDynamic : Api.playlistDetail,
      data: data,
    );
  }

  /// 相关歌单推荐
  ///
  /// [id] 歌单id（必选）
  /// [newStyle] newStyle（可选）
  // _recommendByPlaylist({
  //   required int id,
  //   bool newStyle = true,
  // }) async {
  //   final data = {
  //     'id': id,
  //     'scene': 'playlist_head',
  //     'newStyle': newStyle,
  //   };
  //   return await MusicManager().post(url: Api.recommendByPlaylist, data: data);
  // }

  /// 精品歌单tags
  ///
  Future<HighQualityTagsEntity?> highQualityTags() async {
    return await MusicManager().post<HighQualityTagsEntity>(
      url: Api.highQualityTags,
    );
  }

  /// 收藏/取消收藏歌单
  ///
  /// [id] 歌单 id（必选）
  /// [t] 类型，1:收藏, 2:取消收藏（必选）
  Future<BoolEntity?> playlistSubscribe({
    required int id,
    required int t,
  }) async {
    final url = t == 1 ? Api.playlistSubscribe : Api.playlistUnsubscribe;
    final data = {
      'id': id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await MusicManager().post<BoolEntity>(
      url: url,
      data: data,
    );
  }

  /// 心动模式 / 智能播放列表
  ///
  /// [songId] 种子歌曲 id（必选）
  /// [playlistId] 歌单 id（必选）
  /// [startMusicId] 开始播放的歌曲 id（可选，默认同 songId）
  /// [count] 返回歌曲数量（默认 30）
  Future<IntelligenceListEntity?> playmodeIntelligenceList({
    required int songId,
    required int playlistId,
    int? startMusicId,
    int count = 30,
  }) async {
    final data = <String, dynamic>{
      'songId': songId,
      'type': 'fromPlayOne',
      'playlistId': playlistId,
      'startMusicId': startMusicId ?? songId,
      'count': count,
    };
    return await MusicManager().post<IntelligenceListEntity>(
      url: Api.playmodeIntelligenceList,
      data: data,
    );
  }

  /// 导入歌单（三者取其一）
  ///
  /// [local] 元数据导入（可选）
  /// [text] 文字导入（可选）
  /// [link] 链接导入（可选）
  // void importPlaylist({
  //   Map<String, dynamic>? local,
  //   String text = '',
  //   String link = '',
  //   String playlistName = '导入歌单',
  // }) {
  //   String songs = '';
  //       //元数据导入
  //   if (local != null) {
  //     // local.map((key,value){
  //     //  return {};
  //     // });
  //   }
  //   playlistName += DateTime.now().toIso8601String();
  //   //文字导入
  //   if (text.isNotEmpty) {
  //     songs = jsonEncode([
  //       {
  //         'name': playlistName,
  //         'type': '',
  //         'url': Uri.encodeFull('rpc://playlist/import?text=$text')
  //       }
  //     ]);
  //   }
  //   //链接导入
  //   if (link.isNotEmpty) {}
  // }
}
