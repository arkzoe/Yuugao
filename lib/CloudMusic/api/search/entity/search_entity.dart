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

  List<SearchArtistItem>? artists = [];
  int? artistCount = 0;

  List<SearchAlbumItem>? albums = [];
  int? albumCount = 0;

  List<SearchPlaylistItem>? playlists = [];
  int? playlistCount = 0;

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

// ═══ 歌手搜索结果 ═══

@JsonSerializable()
class SearchArtistItem {
  int? id = 0;
  String? name = '';
  String? picUrl = '';
  String? img1v1Url = '';
  int? albumSize = 0;
  int? musicSize = 0;
  List<String>? alias = [];
  String? trans = '';

  SearchArtistItem();

  factory SearchArtistItem.fromJson(Map<String, dynamic> json) =>
      $SearchArtistItemFromJson(json);

  Map<String, dynamic> toJson() => $SearchArtistItemToJson(this);

  @override
  String toString() => jsonEncode(this);
}

// ═══ 专辑搜索结果 ═══

@JsonSerializable()
class SearchAlbumItem {
  int? id = 0;
  String? name = '';
  String? picUrl = '';
  SearchAlbumItemArtist? artist;
  int? size = 0;
  int? publishTime = 0;

  SearchAlbumItem();

  factory SearchAlbumItem.fromJson(Map<String, dynamic> json) =>
      $SearchAlbumItemFromJson(json);

  Map<String, dynamic> toJson() => $SearchAlbumItemToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class SearchAlbumItemArtist {
  String? name = '';

  SearchAlbumItemArtist();

  factory SearchAlbumItemArtist.fromJson(Map<String, dynamic> json) =>
      $SearchAlbumItemArtistFromJson(json);

  Map<String, dynamic> toJson() => $SearchAlbumItemArtistToJson(this);

  @override
  String toString() => jsonEncode(this);
}

// ═══ 歌单搜索结果 ═══

@JsonSerializable()
class SearchPlaylistItem {
  int? id = 0;
  String? name = '';
  String? coverImgUrl = '';
  int? trackCount = 0;
  int? playCount = 0;
  int? bookCount = 0;
  SearchPlaylistItemCreator? creator;

  SearchPlaylistItem();

  factory SearchPlaylistItem.fromJson(Map<String, dynamic> json) =>
      $SearchPlaylistItemFromJson(json);

  Map<String, dynamic> toJson() => $SearchPlaylistItemToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class SearchPlaylistItemCreator {
  String? nickname = '';

  SearchPlaylistItemCreator();

  factory SearchPlaylistItemCreator.fromJson(Map<String, dynamic> json) =>
      $SearchPlaylistItemCreatorFromJson(json);

  Map<String, dynamic> toJson() => $SearchPlaylistItemCreatorToJson(this);

  @override
  String toString() => jsonEncode(this);
}
