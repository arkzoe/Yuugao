import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/qrcode_key_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/qrcode_key_entity.g.dart';

@JsonSerializable()
class QrcodeKeyEntity {
  int? code = 0;
  String? unikey = '';

  QrcodeKeyEntity();

  factory QrcodeKeyEntity.fromJson(Map<String, dynamic> json) =>
      $QrcodeKeyEntityFromJson(json);

  Map<String, dynamic> toJson() => $QrcodeKeyEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
