import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/like_list_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/like_list_entity.g.dart';

@JsonSerializable()
class LikeListEntity {
  List<int>? ids = [];
  int? checkPoint = 0;
  int? code = 0;

  LikeListEntity();

  factory LikeListEntity.fromJson(Map<String, dynamic> json) =>
      $LikeListEntityFromJson(json);

  Map<String, dynamic> toJson() => $LikeListEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
