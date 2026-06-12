import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/user/entity/qr_check_entity.dart';

QrCheckEntity $QrCheckEntityFromJson(Map<String, dynamic> json) {
  final QrCheckEntity qrCheckEntity = QrCheckEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    qrCheckEntity.code = code;
  }
  final String? message = jsonConvert.convert<String>(json['message']);
  if (message != null) {
    qrCheckEntity.message = message;
  }
  final String? cookie = jsonConvert.convert<String>(json['cookie']);
  if (cookie != null) {
    qrCheckEntity.cookie = cookie;
  }
  final String? nickname = jsonConvert.convert<String>(json['nickname']);
  if (nickname != null) {
    qrCheckEntity.nickname = nickname;
  }
  final String? avatarUrl = jsonConvert.convert<String>(json['avatarUrl']);
  if (avatarUrl != null) {
    qrCheckEntity.avatarUrl = avatarUrl;
  }
  return qrCheckEntity;
}

Map<String, dynamic> $QrCheckEntityToJson(QrCheckEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['message'] = entity.message;
  data['cookie'] = entity.cookie;
  data['nickname'] = entity.nickname;
  data['avatarUrl'] = entity.avatarUrl;
  return data;
}

extension QrCheckEntityExtension on QrCheckEntity {
  QrCheckEntity copyWith({
    int? code,
    String? message,
    String? cookie,
    String? nickname,
    String? avatarUrl,
  }) {
    return QrCheckEntity()
      ..code = code ?? this.code
      ..message = message ?? this.message
      ..cookie = cookie ?? this.cookie
      ..nickname = nickname ?? this.nickname
      ..avatarUrl = avatarUrl ?? this.avatarUrl;
  }
}
