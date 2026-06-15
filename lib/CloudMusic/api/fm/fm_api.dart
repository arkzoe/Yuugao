import 'package:yuugao/CloudMusic/api/api.dart';
import 'package:yuugao/CloudMusic/api/fm/entity/personal_fm_entity.dart';
import 'package:yuugao/CloudMusic/api/user/entity/bool_entity.dart';
import 'package:yuugao/CloudMusic/common/music_interceptors.dart';
import 'package:yuugao/CloudMusic/yuugao.dart';

mixin FmApi {
  /// 私人 FM（需要 weapi 加密）。
  ///
  /// 返回 2-3 首推荐歌曲，可用于双缓冲预加载。
  Future<PersonalFmEntity?> personalFm() async {
    final data = {'timestamp': '${DateTime.now().millisecondsSinceEpoch}'};
    return await MusicManager().post<PersonalFmEntity>(
      url: Api.personalFm,
      options: createOption(encryptType: EncryptType.weApi),
      data: data,
    );
  }

  /// FM 垃圾桶（需要 weapi 加密）。
  ///
  /// 将指定歌曲移入垃圾桶，不再推荐。
  Future<BoolEntity?> fmTrash({required int id}) async {
    final time = DateTime.now().millisecondsSinceEpoch;
    final data = {'songId': id, 'time': time};
    return await MusicManager().post<BoolEntity>(
      url: '${Api.fmTrash}?alg=RT&songId=$id&time=$time',
      options: createOption(encryptType: EncryptType.weApi),
      data: data,
    );
  }
}
