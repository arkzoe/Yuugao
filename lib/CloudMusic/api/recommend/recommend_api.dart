import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/recommend/entity/recommend_new_song_entity.dart';
import 'package:yuugao/CloudMusic/api/recommend/entity/recommend_resource_entity.dart';
import 'package:yuugao/CloudMusic/api/recommend/entity/recommend_song_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/common/music_interceptors.dart';

mixin RecommendApi {
  ///每日推荐歌曲（需要登录）
  ///
  Future<RecommendSongEntity?> recommendSongs() async {
    return await BujuanMusicManager().post<RecommendSongEntity>(
      url: Api.recommendSongs,
      options: createOption(),
    );
  }

  ///每日推荐歌单（需要登录）
  ///
  Future<RecommendResourceEntity?> recommendResource() async {
    return await BujuanMusicManager().post<RecommendResourceEntity>(
      url: Api.recommendResource,
      options: createOption(),
    );
  }

  ///推荐新歌
  ///
  /// [limit] 数量限制
  Future<RecommendNewSongEntity?> recommendNewSong({int limit = 30}) async {
    final data = {'limit': limit};
    return await BujuanMusicManager().post<RecommendNewSongEntity>(
      url: Api.recommendNewSong,
      data: data,
    );
  }
}
