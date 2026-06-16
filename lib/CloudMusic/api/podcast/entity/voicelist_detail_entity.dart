import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/voicelist_detail_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/voicelist_detail_entity.g.dart';

/// 播客列表详情
@JsonSerializable()
class VoicelistDetailEntity {
  int? code = 0;
  VoicelistDetailData? data;

  VoicelistDetailEntity();

  factory VoicelistDetailEntity.fromJson(Map<String, dynamic> json) =>
      $VoicelistDetailEntityFromJson(json);

  Map<String, dynamic> toJson() => $VoicelistDetailEntityToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class VoicelistDetailData {
  int? id = 0;
  String? name = '';
  String? coverPic = '';
  String? desc = '';
  String? category = '';
  String? subCategory = '';
  int? playCount = 0;
  int? subCount = 0;
  int? shareCount = 0;
  int? programCount = 0;
  String? djNickname = '';
  int? djUserId = 0;
  String? djAvatarUrl = '';
  List<String>? tags = [];

  VoicelistDetailData();

  factory VoicelistDetailData.fromJson(Map<String, dynamic> json) =>
      $VoicelistDetailDataFromJson(json);

  Map<String, dynamic> toJson() => $VoicelistDetailDataToJson(this);

  @override
  String toString() => jsonEncode(this);
}
