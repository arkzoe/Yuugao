import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/qr_check_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/qr_check_entity.g.dart';

@JsonSerializable()
class QrCheckEntity {
  int? code = 0;
  String? message = '';
  /// 授权成功时服务器在 JSON body 中直接下发 cookie 串
  String? cookie;
  /// 已扫码时返回的昵称
  String? nickname;
  /// 已扫码时返回的头像
  String? avatarUrl;

  QrCheckEntity();

  factory QrCheckEntity.fromJson(Map<String, dynamic> json) =>
      $QrCheckEntityFromJson(json);

  Map<String, dynamic> toJson() => $QrCheckEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
