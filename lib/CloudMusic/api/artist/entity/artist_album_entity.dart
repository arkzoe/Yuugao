import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/artist_album_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/artist_album_entity.g.dart';

@JsonSerializable()
class ArtistAlbumEntity {
  int? code = 0;
  bool? more = false;
  ArtistAlbumArtist? artist;
  List<ArtistAlbumHotAlbum>? hotAlbums = [];

  ArtistAlbumEntity();

  factory ArtistAlbumEntity.fromJson(Map<String, dynamic> json) =>
      $ArtistAlbumEntityFromJson(json);

  Map<String, dynamic> toJson() => $ArtistAlbumEntityToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistAlbumArtist {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  ArtistAlbumArtist();

  factory ArtistAlbumArtist.fromJson(Map<String, dynamic> json) =>
      $ArtistAlbumArtistFromJson(json);

  Map<String, dynamic> toJson() => $ArtistAlbumArtistToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistAlbumHotAlbum {
  int? id = 0;
  String? name = '';
  String? picUrl = '';
  int? size = 0;
  int? publishTime = 0;
  String? company = '';
  List<ArtistAlbumHotAlbumArtist>? artists = [];

  ArtistAlbumHotAlbum();

  factory ArtistAlbumHotAlbum.fromJson(Map<String, dynamic> json) =>
      $ArtistAlbumHotAlbumFromJson(json);

  Map<String, dynamic> toJson() => $ArtistAlbumHotAlbumToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistAlbumHotAlbumArtist {
  int? id = 0;
  String? name = '';

  ArtistAlbumHotAlbumArtist();

  factory ArtistAlbumHotAlbumArtist.fromJson(Map<String, dynamic> json) =>
      $ArtistAlbumHotAlbumArtistFromJson(json);

  Map<String, dynamic> toJson() => $ArtistAlbumHotAlbumArtistToJson(this);

  @override
  String toString() => jsonEncode(this);
}
