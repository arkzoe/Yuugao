import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/podcast/entity/dj_program_entity.dart';
import 'package:yuugao/CloudMusic/api/podcast/entity/user_dj_entity.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';

mixin PodcastApi {
  /// 获取用户订阅的播客/电台列表
  ///
  /// [uid] 用户 id（必选）
  Future<UserDjEntity?> userDj({
    required int uid,
  }) async {
    final data = {'uid': uid};
    return await MusicManager().post<UserDjEntity>(
      url: Api.userDj,
      data: data,
    );
  }

  /// 获取播客/电台的节目列表
  ///
  /// [radioId] 电台/播客 id（必选）
  /// [limit] 取出数量（默认 30）
  /// [offset] 偏移数量（默认 0）
  /// [asc] 是否升序（默认 false）
  Future<DjProgramEntity?> djProgramByRadio({
    required int radioId,
    int limit = 30,
    int offset = 0,
    bool asc = false,
  }) async {
    final data = {
      'radioId': radioId,
      'limit': limit,
      'offset': offset,
      'asc': asc,
    };
    return await MusicManager().post<DjProgramEntity>(
      url: Api.djProgramByRadio,
      data: data,
    );
  }
}
