import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/string_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/string_entity.g.dart';

@JsonSerializable()
class StringEntity {
  int? code = 0;
  String? data = '';
  String? message;

  StringEntity();

  factory StringEntity.fromJson(Map<String, dynamic> json) =>
      $StringEntityFromJson(json);

  Map<String, dynamic> toJson() => $StringEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
