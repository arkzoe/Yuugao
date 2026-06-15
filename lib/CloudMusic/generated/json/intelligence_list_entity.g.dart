import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/playlist/entity/intelligence_list_entity.dart';

IntelligenceListEntity $IntelligenceListEntityFromJson(
    Map<String, dynamic> json) {
  final IntelligenceListEntity entity = IntelligenceListEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    entity.code = code;
  }
  final List<IntelligenceListSongItem>? data =
      (json['data'] as List<dynamic>?)
          ?.map(
            (e) => jsonConvert.convert<IntelligenceListSongItem>(e)
                as IntelligenceListSongItem,
          )
          .toList();
  if (data != null) {
    entity.data = data;
  }
  return entity;
}

Map<String, dynamic> $IntelligenceListEntityToJson(
    IntelligenceListEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['data'] = entity.data?.map((v) => v.toJson()).toList();
  return data;
}

IntelligenceListSongItem $IntelligenceListSongItemFromJson(
    Map<String, dynamic> json) {
  final IntelligenceListSongItem entity = IntelligenceListSongItem();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    entity.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    entity.name = name;
  }
  return entity;
}

Map<String, dynamic> $IntelligenceListSongItemToJson(
    IntelligenceListSongItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  return data;
}
