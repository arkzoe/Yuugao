import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/song_lyric_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/song_lyric_entity.g.dart';

@JsonSerializable()
class SongLyricEntity {
  int? code = 0;
  SongLyricLrc? lrc;
  SongLyricLrc? klyric;
  SongLyricLrc? tlyric;

  SongLyricEntity();

  factory SongLyricEntity.fromJson(Map<String, dynamic> json) =>
      $SongLyricEntityFromJson(json);

  Map<String, dynamic> toJson() => $SongLyricEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class SongLyricLrc {
  String? lyric = '';
  int? version = 0;

  SongLyricLrc();

  factory SongLyricLrc.fromJson(Map<String, dynamic> json) =>
      $SongLyricLrcFromJson(json);

  Map<String, dynamic> toJson() => $SongLyricLrcToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
