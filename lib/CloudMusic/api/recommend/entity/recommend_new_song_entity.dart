import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/recommend_new_song_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/recommend_new_song_entity.g.dart';

@JsonSerializable()
class RecommendNewSongEntity {
  int? code = 0;
  List<RecommendNewSongResult>? result = [];

  RecommendNewSongEntity();

  factory RecommendNewSongEntity.fromJson(Map<String, dynamic> json) =>
      $RecommendNewSongEntityFromJson(json);

  Map<String, dynamic> toJson() => $RecommendNewSongEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class RecommendNewSongResult {
  int? id = 0;
  int? type = 0;
  String? name = '';
  String? copywriter = '';
  String? picUrl = '';
  int? playcount = 0;
  int? createTime = 0;
  int? trackCount = 0;
  int? userId = 0;
  String? alg = '';
  RecommendNewSongResultSong? song;

  RecommendNewSongResult();

  factory RecommendNewSongResult.fromJson(Map<String, dynamic> json) =>
      $RecommendNewSongResultFromJson(json);

  Map<String, dynamic> toJson() => $RecommendNewSongResultToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class RecommendNewSongResultSong {
  int? id = 0;
  String? name = '';
  List<RecommendNewSongResultSongArtists>? artists = [];
  RecommendNewSongResultSongAlbum? album;
  int? duration = 0;
  int? mvid = 0;

  RecommendNewSongResultSong();

  factory RecommendNewSongResultSong.fromJson(Map<String, dynamic> json) =>
      $RecommendNewSongResultSongFromJson(json);

  Map<String, dynamic> toJson() => $RecommendNewSongResultSongToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class RecommendNewSongResultSongArtists {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  RecommendNewSongResultSongArtists();

  factory RecommendNewSongResultSongArtists.fromJson(
    Map<String, dynamic> json,
  ) => $RecommendNewSongResultSongArtistsFromJson(json);

  Map<String, dynamic> toJson() =>
      $RecommendNewSongResultSongArtistsToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class RecommendNewSongResultSongAlbum {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  RecommendNewSongResultSongAlbum();

  factory RecommendNewSongResultSongAlbum.fromJson(Map<String, dynamic> json) =>
      $RecommendNewSongResultSongAlbumFromJson(json);

  Map<String, dynamic> toJson() => $RecommendNewSongResultSongAlbumToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
