import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/bool_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/bool_entity.g.dart';

@JsonSerializable()
class BoolEntity {
  int? code = 0;
  bool? data = false;
  String? message;

  BoolEntity();

  factory BoolEntity.fromJson(Map<String, dynamic> json) =>
      $BoolEntityFromJson(json);

  Map<String, dynamic> toJson() => $BoolEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
