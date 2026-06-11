import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/common/music_interceptors.dart';

import 'entity/top_artist_entity.dart';

mixin TopApi {
  /// 热门歌手
  ///
  /// [limit] 30
  /// [offset] 0
  /// [total] true,
  Future<TopArtistEntity?> topArtist({
    int limit = 30,
    int offset = 0,
    total = true,
  }) async {
    final data = {'limit': limit, 'offset': offset, 'total': total};
    return await BujuanMusicManager().post<TopArtistEntity>(
      url: Api.topArtist,
      options: createOption(),
      data: data,
    );
  }
}
