import 'package:yuugao/CloudMusic/api/album/entity/album_info_entity.dart';
import 'package:yuugao/CloudMusic/api/album/entity/new_album_entity.dart';

import '../../common/music_api.dart';
import '../../common/music_interceptors.dart';
import '../api.dart';

mixin AlbumApi {
  /// 最新专辑
  ///
  /// [limit] （可选，默认30）
  /// [offset]（可选，默认0）
  /// [area] 地区 ALL:全部,ZH:华语,EA:欧美,KR:韩国,JP:日本（可选，默认 ALL）
  /// [total] 是否请求全部（可选，默认 total）
  Future<NewAlbumEntity?> newAlbum({
    int limit = 30,
    int offset = 0,
    String area = 'ALL',
    bool total = true,
  }) async {
    final data = {
      'limit': limit,
      'offset': offset,
      'area': area,
      'total': total,
    };
    return await MusicManager().post<NewAlbumEntity>(
      url: Api.newAlbum,
      options: createOption(),
      data: data,
    );
  }

  /// 专辑内容
  ///
  /// [id] 专辑ID（必选）
  Future<AlbumInfoEntity?> albumInfo({required int id}) async {
    return await MusicManager().post<AlbumInfoEntity>(
      url: '${Api.albumInfo}/$id',
      options: createOption(),
    );
  }

}
