import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/artist_songs_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/artist_songs_entity.g.dart';

@JsonSerializable()
class ArtistSongsEntity {
  int? code = 0;
  bool? more = false;
  ArtistSongsArtist? artist;
  List<ArtistHotSong>? hotSongs = [];

  ArtistSongsEntity();

  factory ArtistSongsEntity.fromJson(Map<String, dynamic> json) =>
      $ArtistSongsEntityFromJson(json);

  Map<String, dynamic> toJson() => $ArtistSongsEntityToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistSongsArtist {
  int? id = 0;
  String? name = '';
  String? picUrl = '';
  String? img1v1Url = '';
  int? albumSize = 0;
  int? musicSize = 0;
  int? mvSize = 0;
  String? briefDesc = '';

  ArtistSongsArtist();

  factory ArtistSongsArtist.fromJson(Map<String, dynamic> json) =>
      $ArtistSongsArtistFromJson(json);

  Map<String, dynamic> toJson() => $ArtistSongsArtistToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistHotSong {
  int? id = 0;
  String? name = '';
  List<ArtistHotSongAr>? ar = [];
  ArtistHotSongAl? al;
  int? dt = 0;
  int? fee = 0;

  ArtistHotSong();

  factory ArtistHotSong.fromJson(Map<String, dynamic> json) =>
      $ArtistHotSongFromJson(json);

  Map<String, dynamic> toJson() => $ArtistHotSongToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistHotSongAr {
  int? id = 0;
  String? name = '';

  ArtistHotSongAr();

  factory ArtistHotSongAr.fromJson(Map<String, dynamic> json) =>
      $ArtistHotSongArFromJson(json);

  Map<String, dynamic> toJson() => $ArtistHotSongArToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class ArtistHotSongAl {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  ArtistHotSongAl();

  factory ArtistHotSongAl.fromJson(Map<String, dynamic> json) =>
      $ArtistHotSongAlFromJson(json);

  Map<String, dynamic> toJson() => $ArtistHotSongAlToJson(this);

  @override
  String toString() => jsonEncode(this);
}
