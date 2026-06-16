import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/user_dj_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/user_dj_entity.g.dart';

/// 用户订阅的播客/电台列表
@JsonSerializable()
class UserDjEntity {
  int? code = 0;
  int? count = 0;
  bool? hasMore = false;
  List<UserDjRadio>? djRadios = [];

  UserDjEntity();

  factory UserDjEntity.fromJson(Map<String, dynamic> json) =>
      $UserDjEntityFromJson(json);

  Map<String, dynamic> toJson() => $UserDjEntityToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class UserDjRadio {
  int? id = 0;
  String? name = '';
  String? picUrl = '';
  String? category = '';
  int? programCount = 0;
  int? subCount = 0;
  int? playCount = 0;
  UserDjRadioDj? dj;

  UserDjRadio();

  factory UserDjRadio.fromJson(Map<String, dynamic> json) =>
      $UserDjRadioFromJson(json);

  Map<String, dynamic> toJson() => $UserDjRadioToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class UserDjRadioDj {
  String? nickname = '';
  int? userId = 0;
  String? avatarUrl = '';

  UserDjRadioDj();

  factory UserDjRadioDj.fromJson(Map<String, dynamic> json) =>
      $UserDjRadioDjFromJson(json);

  Map<String, dynamic> toJson() => $UserDjRadioDjToJson(this);

  @override
  String toString() => jsonEncode(this);
}
