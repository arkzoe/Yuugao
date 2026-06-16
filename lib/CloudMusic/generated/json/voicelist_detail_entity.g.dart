import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/podcast/entity/voicelist_detail_entity.dart';

VoicelistDetailEntity $VoicelistDetailEntityFromJson(
    Map<String, dynamic> json) {
  final VoicelistDetailEntity entity = VoicelistDetailEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    entity.code = code;
  }
  final VoicelistDetailData? data =
      jsonConvert.convert<VoicelistDetailData>(json['data']);
  if (data != null) {
    entity.data = data;
  }
  return entity;
}

Map<String, dynamic> $VoicelistDetailEntityToJson(
    VoicelistDetailEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['data'] = entity.data?.toJson();
  return data;
}

VoicelistDetailData $VoicelistDetailDataFromJson(Map<String, dynamic> json) {
  final VoicelistDetailData item = VoicelistDetailData();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? coverPic = jsonConvert.convert<String>(json['coverPic']);
  if (coverPic != null) item.coverPic = coverPic;
  final String? desc = jsonConvert.convert<String>(json['desc']);
  if (desc != null) item.desc = desc;
  final String? category = jsonConvert.convert<String>(json['category']);
  if (category != null) item.category = category;
  final String? subCategory =
      jsonConvert.convert<String>(json['subCategory']);
  if (subCategory != null) item.subCategory = subCategory;
  final int? playCount = jsonConvert.convert<int>(json['playCount']);
  if (playCount != null) item.playCount = playCount;
  final int? subCount = jsonConvert.convert<int>(json['subCount']);
  if (subCount != null) item.subCount = subCount;
  final int? shareCount = jsonConvert.convert<int>(json['shareCount']);
  if (shareCount != null) item.shareCount = shareCount;
  final int? programCount = jsonConvert.convert<int>(json['programCount']);
  if (programCount != null) item.programCount = programCount;
  final String? djNickname =
      jsonConvert.convert<String>(json['djNickname']);
  if (djNickname != null) item.djNickname = djNickname;
  final int? djUserId = jsonConvert.convert<int>(json['djUserId']);
  if (djUserId != null) item.djUserId = djUserId;
  final String? djAvatarUrl =
      jsonConvert.convert<String>(json['djAvatarUrl']);
  if (djAvatarUrl != null) item.djAvatarUrl = djAvatarUrl;
  final List<String>? tags = (json['tags'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<String>(e) as String)
      .toList();
  if (tags != null) item.tags = tags;
  return item;
}

Map<String, dynamic> $VoicelistDetailDataToJson(VoicelistDetailData entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['coverPic'] = entity.coverPic;
  data['desc'] = entity.desc;
  data['category'] = entity.category;
  data['subCategory'] = entity.subCategory;
  data['playCount'] = entity.playCount;
  data['subCount'] = entity.subCount;
  data['shareCount'] = entity.shareCount;
  data['programCount'] = entity.programCount;
  data['djNickname'] = entity.djNickname;
  data['djUserId'] = entity.djUserId;
  data['djAvatarUrl'] = entity.djAvatarUrl;
  data['tags'] = entity.tags;
  return data;
}
