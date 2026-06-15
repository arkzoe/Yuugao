import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/intelligence_list_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/intelligence_list_entity.g.dart';

@JsonSerializable()
class IntelligenceListEntity {
  int? code = 0;
  List<IntelligenceListSongItem>? data = [];

  IntelligenceListEntity();

  factory IntelligenceListEntity.fromJson(Map<String, dynamic> json) =>
      $IntelligenceListEntityFromJson(json);

  Map<String, dynamic> toJson() => $IntelligenceListEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class IntelligenceListSongItem {
  int? id = 0;
  String? name = '';

  IntelligenceListSongItem();

  factory IntelligenceListSongItem.fromJson(Map<String, dynamic> json) =>
      $IntelligenceListSongItemFromJson(json);

  Map<String, dynamic> toJson() => $IntelligenceListSongItemToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
