import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/search_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/search_entity.g.dart';

@JsonSerializable()
class SearchEntity {
  SearchResult? result;
  int? code = 0;

  SearchEntity();

  factory SearchEntity.fromJson(Map<String, dynamic> json) =>
      $SearchEntityFromJson(json);

  Map<String, dynamic> toJson() => $SearchEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class SearchResult {
  List<SearchSongItem>? songs = [];
  int? songCount = 0;
  bool? hasMore = false;

  SearchResult();

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      $SearchResultFromJson(json);

  Map<String, dynamic> toJson() => $SearchResultToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class SearchSongItem {
  int? id = 0;
  String? name = '';
  List<SearchSongArtist>? artists = [];
  SearchSongAlbum? album;
  int? duration = 0;
  int? fee = 0;

  SearchSongItem();

  factory SearchSongItem.fromJson(Map<String, dynamic> json) =>
      $SearchSongItemFromJson(json);

  Map<String, dynamic> toJson() => $SearchSongItemToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class SearchSongArtist {
  int? id = 0;
  String? name = '';

  SearchSongArtist();

  factory SearchSongArtist.fromJson(Map<String, dynamic> json) =>
      $SearchSongArtistFromJson(json);

  Map<String, dynamic> toJson() => $SearchSongArtistToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class SearchSongAlbum {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  SearchSongAlbum();

  factory SearchSongAlbum.fromJson(Map<String, dynamic> json) =>
      $SearchSongAlbumFromJson(json);

  Map<String, dynamic> toJson() => $SearchSongAlbumToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
