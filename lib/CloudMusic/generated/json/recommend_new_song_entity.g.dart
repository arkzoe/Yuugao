import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/recommend/entity/recommend_new_song_entity.dart';

RecommendNewSongEntity $RecommendNewSongEntityFromJson(
  Map<String, dynamic> json,
) {
  final RecommendNewSongEntity recommendNewSongEntity =
      RecommendNewSongEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    recommendNewSongEntity.code = code;
  }
  final List<RecommendNewSongResult>? result =
      (json['result'] as List<dynamic>?)
          ?.map(
            (e) =>
                jsonConvert.convert<RecommendNewSongResult>(e)
                    as RecommendNewSongResult,
          )
          .toList();
  if (result != null) {
    recommendNewSongEntity.result = result;
  }
  return recommendNewSongEntity;
}

Map<String, dynamic> $RecommendNewSongEntityToJson(
  RecommendNewSongEntity entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['result'] = entity.result?.map((v) => v.toJson()).toList();
  return data;
}

extension RecommendNewSongEntityExtension on RecommendNewSongEntity {
  RecommendNewSongEntity copyWith({
    int? code,
    List<RecommendNewSongResult>? result,
  }) {
    return RecommendNewSongEntity()
      ..code = code ?? this.code
      ..result = result ?? this.result;
  }
}

RecommendNewSongResult $RecommendNewSongResultFromJson(
  Map<String, dynamic> json,
) {
  final RecommendNewSongResult recommendNewSongResult =
      RecommendNewSongResult();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    recommendNewSongResult.id = id;
  }
  final int? type = jsonConvert.convert<int>(json['type']);
  if (type != null) {
    recommendNewSongResult.type = type;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    recommendNewSongResult.name = name;
  }
  final String? copywriter = jsonConvert.convert<String>(json['copywriter']);
  if (copywriter != null) {
    recommendNewSongResult.copywriter = copywriter;
  }
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) {
    recommendNewSongResult.picUrl = picUrl;
  }
  final int? playcount = jsonConvert.convert<int>(json['playcount']);
  if (playcount != null) {
    recommendNewSongResult.playcount = playcount;
  }
  final int? createTime = jsonConvert.convert<int>(json['createTime']);
  if (createTime != null) {
    recommendNewSongResult.createTime = createTime;
  }
  final int? trackCount = jsonConvert.convert<int>(json['trackCount']);
  if (trackCount != null) {
    recommendNewSongResult.trackCount = trackCount;
  }
  final int? userId = jsonConvert.convert<int>(json['userId']);
  if (userId != null) {
    recommendNewSongResult.userId = userId;
  }
  final String? alg = jsonConvert.convert<String>(json['alg']);
  if (alg != null) {
    recommendNewSongResult.alg = alg;
  }
  final RecommendNewSongResultSong? song = jsonConvert
      .convert<RecommendNewSongResultSong>(json['song']);
  if (song != null) {
    recommendNewSongResult.song = song;
  }
  return recommendNewSongResult;
}

Map<String, dynamic> $RecommendNewSongResultToJson(
  RecommendNewSongResult entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['type'] = entity.type;
  data['name'] = entity.name;
  data['copywriter'] = entity.copywriter;
  data['picUrl'] = entity.picUrl;
  data['playcount'] = entity.playcount;
  data['createTime'] = entity.createTime;
  data['trackCount'] = entity.trackCount;
  data['userId'] = entity.userId;
  data['alg'] = entity.alg;
  data['song'] = entity.song?.toJson();
  return data;
}

extension RecommendNewSongResultExtension on RecommendNewSongResult {
  RecommendNewSongResult copyWith({
    int? id,
    int? type,
    String? name,
    String? copywriter,
    String? picUrl,
    int? playcount,
    int? createTime,
    int? trackCount,
    int? userId,
    String? alg,
    RecommendNewSongResultSong? song,
  }) {
    return RecommendNewSongResult()
      ..id = id ?? this.id
      ..type = type ?? this.type
      ..name = name ?? this.name
      ..copywriter = copywriter ?? this.copywriter
      ..picUrl = picUrl ?? this.picUrl
      ..playcount = playcount ?? this.playcount
      ..createTime = createTime ?? this.createTime
      ..trackCount = trackCount ?? this.trackCount
      ..userId = userId ?? this.userId
      ..alg = alg ?? this.alg
      ..song = song ?? this.song;
  }
}

RecommendNewSongResultSong $RecommendNewSongResultSongFromJson(
  Map<String, dynamic> json,
) {
  final RecommendNewSongResultSong recommendNewSongResultSong =
      RecommendNewSongResultSong();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    recommendNewSongResultSong.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    recommendNewSongResultSong.name = name;
  }
  final List<RecommendNewSongResultSongArtists>? artists =
      (json['artists'] as List<dynamic>?)
          ?.map(
            (e) =>
                jsonConvert.convert<RecommendNewSongResultSongArtists>(e)
                    as RecommendNewSongResultSongArtists,
          )
          .toList();
  if (artists != null) {
    recommendNewSongResultSong.artists = artists;
  }
  final RecommendNewSongResultSongAlbum? album = jsonConvert
      .convert<RecommendNewSongResultSongAlbum>(json['album']);
  if (album != null) {
    recommendNewSongResultSong.album = album;
  }
  final int? duration = jsonConvert.convert<int>(json['duration']);
  if (duration != null) {
    recommendNewSongResultSong.duration = duration;
  }
  final int? mvid = jsonConvert.convert<int>(json['mvid']);
  if (mvid != null) {
    recommendNewSongResultSong.mvid = mvid;
  }
  return recommendNewSongResultSong;
}

Map<String, dynamic> $RecommendNewSongResultSongToJson(
  RecommendNewSongResultSong entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['artists'] = entity.artists?.map((v) => v.toJson()).toList();
  data['album'] = entity.album?.toJson();
  data['duration'] = entity.duration;
  data['mvid'] = entity.mvid;
  return data;
}

extension RecommendNewSongResultSongExtension on RecommendNewSongResultSong {
  RecommendNewSongResultSong copyWith({
    int? id,
    String? name,
    List<RecommendNewSongResultSongArtists>? artists,
    RecommendNewSongResultSongAlbum? album,
    int? duration,
    int? mvid,
  }) {
    return RecommendNewSongResultSong()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..artists = artists ?? this.artists
      ..album = album ?? this.album
      ..duration = duration ?? this.duration
      ..mvid = mvid ?? this.mvid;
  }
}

RecommendNewSongResultSongArtists $RecommendNewSongResultSongArtistsFromJson(
  Map<String, dynamic> json,
) {
  final RecommendNewSongResultSongArtists recommendNewSongResultSongArtists =
      RecommendNewSongResultSongArtists();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    recommendNewSongResultSongArtists.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    recommendNewSongResultSongArtists.name = name;
  }
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) {
    recommendNewSongResultSongArtists.picUrl = picUrl;
  }
  return recommendNewSongResultSongArtists;
}

Map<String, dynamic> $RecommendNewSongResultSongArtistsToJson(
  RecommendNewSongResultSongArtists entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}

extension RecommendNewSongResultSongArtistsExtension
    on RecommendNewSongResultSongArtists {
  RecommendNewSongResultSongArtists copyWith({
    int? id,
    String? name,
    String? picUrl,
  }) {
    return RecommendNewSongResultSongArtists()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..picUrl = picUrl ?? this.picUrl;
  }
}

RecommendNewSongResultSongAlbum $RecommendNewSongResultSongAlbumFromJson(
  Map<String, dynamic> json,
) {
  final RecommendNewSongResultSongAlbum recommendNewSongResultSongAlbum =
      RecommendNewSongResultSongAlbum();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    recommendNewSongResultSongAlbum.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    recommendNewSongResultSongAlbum.name = name;
  }
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) {
    recommendNewSongResultSongAlbum.picUrl = picUrl;
  }
  return recommendNewSongResultSongAlbum;
}

Map<String, dynamic> $RecommendNewSongResultSongAlbumToJson(
  RecommendNewSongResultSongAlbum entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}

extension RecommendNewSongResultSongAlbumExtension
    on RecommendNewSongResultSongAlbum {
  RecommendNewSongResultSongAlbum copyWith({
    int? id,
    String? name,
    String? picUrl,
  }) {
    return RecommendNewSongResultSongAlbum()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..picUrl = picUrl ?? this.picUrl;
  }
}
