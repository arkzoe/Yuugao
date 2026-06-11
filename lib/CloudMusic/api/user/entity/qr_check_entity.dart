import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/qr_check_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/qr_check_entity.g.dart';

@JsonSerializable()
class QrCheckEntity {
  int? code = 0;
  String? message = '';

  QrCheckEntity();

  factory QrCheckEntity.fromJson(Map<String, dynamic> json) =>
      $QrCheckEntityFromJson(json);

  Map<String, dynamic> toJson() => $QrCheckEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
