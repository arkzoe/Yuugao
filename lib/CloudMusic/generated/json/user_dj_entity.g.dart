import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/podcast/entity/user_dj_entity.dart';

UserDjEntity $UserDjEntityFromJson(Map<String, dynamic> json) {
  final UserDjEntity entity = UserDjEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    entity.code = code;
  }
  final int? count = jsonConvert.convert<int>(json['count']);
  if (count != null) {
    entity.count = count;
  }
  final bool? hasMore = jsonConvert.convert<bool>(json['hasMore']);
  if (hasMore != null) {
    entity.hasMore = hasMore;
  }
  final List<UserDjRadio>? djRadios = (json['djRadios'] as List<dynamic>?)
      ?.map((e) =>
          jsonConvert.convert<UserDjRadio>(e) as UserDjRadio)
      .toList();
  if (djRadios != null) {
    entity.djRadios = djRadios;
  }
  return entity;
}

Map<String, dynamic> $UserDjEntityToJson(UserDjEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['count'] = entity.count;
  data['hasMore'] = entity.hasMore;
  data['djRadios'] = entity.djRadios?.map((v) => v.toJson()).toList();
  return data;
}

UserDjRadio $UserDjRadioFromJson(Map<String, dynamic> json) {
  final UserDjRadio item = UserDjRadio();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) item.picUrl = picUrl;
  final String? category = jsonConvert.convert<String>(json['category']);
  if (category != null) item.category = category;
  final int? programCount = jsonConvert.convert<int>(json['programCount']);
  if (programCount != null) item.programCount = programCount;
  final int? subCount = jsonConvert.convert<int>(json['subCount']);
  if (subCount != null) item.subCount = subCount;
  final int? playCount = jsonConvert.convert<int>(json['playCount']);
  if (playCount != null) item.playCount = playCount;
  final UserDjRadioDj? dj =
      jsonConvert.convert<UserDjRadioDj>(json['dj']);
  if (dj != null) item.dj = dj;
  return item;
}

Map<String, dynamic> $UserDjRadioToJson(UserDjRadio entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  data['category'] = entity.category;
  data['programCount'] = entity.programCount;
  data['subCount'] = entity.subCount;
  data['playCount'] = entity.playCount;
  data['dj'] = entity.dj?.toJson();
  return data;
}

UserDjRadioDj $UserDjRadioDjFromJson(Map<String, dynamic> json) {
  final UserDjRadioDj item = UserDjRadioDj();
  final String? nickname = jsonConvert.convert<String>(json['nickname']);
  if (nickname != null) item.nickname = nickname;
  final int? userId = jsonConvert.convert<int>(json['userId']);
  if (userId != null) item.userId = userId;
  final String? avatarUrl =
      jsonConvert.convert<String>(json['avatarUrl']);
  if (avatarUrl != null) item.avatarUrl = avatarUrl;
  return item;
}

Map<String, dynamic> $UserDjRadioDjToJson(UserDjRadioDj entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['nickname'] = entity.nickname;
  data['userId'] = entity.userId;
  data['avatarUrl'] = entity.avatarUrl;
  return data;
}
