import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/cloud/cloud_entity.dart';
import 'package:yuugao/CloudMusic/common/music_interceptors.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';

/// 网易云音乐云盘 API。
///
/// 提供云盘歌曲列表获取、删除、匹配等功能。
mixin CloudApi {
  /// 获取云盘歌曲列表（分页）。
  ///
  /// [offset] 偏移量，[limit] 每页数量（默认 30）。
  Future<CloudSongListEntity?> cloudSongList({
    int offset = 0,
    int limit = 30,
  }) async {
    final data = {'limit': limit, 'offset': offset};
    return await MusicManager().post<CloudSongListEntity>(
      url: Api.cloudList,
      options: createOption(encryptType: EncryptType.weApi),
      data: data,
    );
  }

  /// 删除云盘歌曲。
  ///
  /// [songIds] 要删除的歌曲 ID 列表。
  Future<CloudSongListEntity?> cloudSongDelete(List<String> songIds) async {
    final data = {'songIds': songIds};
    return await MusicManager().post<CloudSongListEntity>(
      url: Api.cloudDelete,
      options: createOption(encryptType: EncryptType.weApi),
      data: data,
    );
  }

  /// 获取云盘歌曲详情（通过 ID 列表）。
  Future<CloudSongListEntity?> cloudSongDetail(List<String> songIds) async {
    final data = {'songIds': songIds};
    return await MusicManager().post<CloudSongListEntity>(
      url: Api.cloudDetail,
      options: createOption(encryptType: EncryptType.weApi),
      data: data,
    );
  }
}
