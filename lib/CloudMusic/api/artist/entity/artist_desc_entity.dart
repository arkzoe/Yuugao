import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/artist_desc_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/artist_desc_entity.g.dart';

@JsonSerializable()
class ArtistDescEntity {
  int? code = 0;
  String? briefDesc = '';
  List<ArtistDescIntroduction>? introduction = [];
  int? count = 0;

  ArtistDescEntity();

  factory ArtistDescEntity.fromJson(Map<String, dynamic> json) =>
      $ArtistDescEntityFromJson(json);

  Map<String, dynamic> toJson() => $ArtistDescEntityToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistDescIntroduction {
  String? ti = '';
  String? txt = '';

  ArtistDescIntroduction();

  factory ArtistDescIntroduction.fromJson(Map<String, dynamic> json) =>
      $ArtistDescIntroductionFromJson(json);

  Map<String, dynamic> toJson() => $ArtistDescIntroductionToJson(this);

  @override
  String toString() => jsonEncode(this);
}
