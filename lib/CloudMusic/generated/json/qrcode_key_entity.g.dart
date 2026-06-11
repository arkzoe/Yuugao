import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/user/entity/qrcode_key_entity.dart';

QrcodeKeyEntity $QrcodeKeyEntityFromJson(Map<String, dynamic> json) {
  final QrcodeKeyEntity qrcodeKeyEntity = QrcodeKeyEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    qrcodeKeyEntity.code = code;
  }
  final String? unikey = jsonConvert.convert<String>(json['unikey']);
  if (unikey != null) {
    qrcodeKeyEntity.unikey = unikey;
  }
  return qrcodeKeyEntity;
}

Map<String, dynamic> $QrcodeKeyEntityToJson(QrcodeKeyEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['unikey'] = entity.unikey;
  return data;
}

extension QrcodeKeyEntityExtension on QrcodeKeyEntity {
  QrcodeKeyEntity copyWith({int? code, String? unikey}) {
    return QrcodeKeyEntity()
      ..code = code ?? this.code
      ..unikey = unikey ?? this.unikey;
  }
}
