import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/search/entity/search_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';

mixin SearchApi {
  /// 搜索
  ///
  /// [keywords] 关键词（必填）
  /// [type] 1=单曲 10=专辑 100=歌手 1000=歌单
  /// [limit] 每页数量
  /// [offset] 偏移
  Future<SearchEntity?> search({
    required String keywords,
    int type = 1,
    int limit = 30,
    int offset = 0,
  }) async {
    final data = {
      's': keywords,
      'type': type,
      'limit': limit,
      'offset': offset,
    };
    return await BujuanMusicManager().post<SearchEntity>(
      url: Api.search,
      data: data,
    );
  }
}
