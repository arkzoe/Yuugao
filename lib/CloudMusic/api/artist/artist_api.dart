import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_album_entity.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_desc_entity.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_songs_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/common/music_interceptors.dart';

mixin ArtistApi {
  /// 歌手信息 + 热门歌曲
  ///
  /// [id] 歌手 ID（必选）
  Future<ArtistSongsEntity?> artistSongs({required int id}) async {
    return await MusicManager().post<ArtistSongsEntity>(
      url: '${Api.artistSongs}/$id',
      options: createOption(),
    );
  }

  /// 歌手专辑列表
  ///
  /// [id] 歌手 ID（必选）
  /// [limit] 默认 30
  /// [offset] 默认 0
  Future<ArtistAlbumEntity?> artistAlbum({
    required int id,
    int limit = 30,
    int offset = 0,
  }) async {
    final data = {'limit': limit, 'offset': offset, 'total': true};
    return await MusicManager().post<ArtistAlbumEntity>(
      url: '${Api.artistAlbum}/$id',
      options: createOption(),
      data: data,
    );
  }

  /// 歌手描述
  ///
  /// [id] 歌手 ID（必选）
  Future<ArtistDescEntity?> artistDesc({required int id}) async {
    final data = {'id': id};
    return await MusicManager().post<ArtistDescEntity>(
      url: Api.artistDesc,
      options: createOption(),
      data: data,
    );
  }
}
