import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_songs_entity.dart';

ArtistSongsEntity $ArtistSongsEntityFromJson(Map<String, dynamic> json) {
  // 兼容嵌套在 data 字段中的响应
  final src = (json.containsKey('data') && json['data'] is Map<String, dynamic>)
      ? json['data'] as Map<String, dynamic>
      : json;

  final ArtistSongsEntity entity = ArtistSongsEntity();
  final int? code = jsonConvert.convert<int>(src['code']);
  if (code != null) {
    entity.code = code;
  }
  final bool? more = jsonConvert.convert<bool>(src['more']);
  if (more != null) {
    entity.more = more;
  }
  final ArtistSongsArtist? artist = jsonConvert.convert<ArtistSongsArtist>(
    src['artist'],
  );
  if (artist != null) {
    entity.artist = artist;
  }
  final List<ArtistHotSong>? hotSongs = (src['hotSongs'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<ArtistHotSong>(e) as ArtistHotSong)
      .toList();
  if (hotSongs != null) {
    entity.hotSongs = hotSongs;
  }
  return entity;
}

Map<String, dynamic> $ArtistSongsEntityToJson(ArtistSongsEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['more'] = entity.more;
  data['artist'] = entity.artist?.toJson();
  data['hotSongs'] = entity.hotSongs?.map((v) => v.toJson()).toList();
  return data;
}

ArtistSongsArtist $ArtistSongsArtistFromJson(Map<String, dynamic> json) {
  final ArtistSongsArtist entity = ArtistSongsArtist();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    entity.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    entity.name = name;
  }
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) {
    entity.picUrl = picUrl;
  }
  final String? img1v1Url = jsonConvert.convert<String>(json['img1v1Url']);
  if (img1v1Url != null) {
    entity.img1v1Url = img1v1Url;
  }
  final int? albumSize = jsonConvert.convert<int>(json['albumSize']);
  if (albumSize != null) {
    entity.albumSize = albumSize;
  }
  final int? musicSize = jsonConvert.convert<int>(json['musicSize']);
  if (musicSize != null) {
    entity.musicSize = musicSize;
  }
  final int? mvSize = jsonConvert.convert<int>(json['mvSize']);
  if (mvSize != null) {
    entity.mvSize = mvSize;
  }
  final String? briefDesc = jsonConvert.convert<String>(json['briefDesc']);
  if (briefDesc != null) {
    entity.briefDesc = briefDesc;
  }
  return entity;
}

Map<String, dynamic> $ArtistSongsArtistToJson(ArtistSongsArtist entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  data['img1v1Url'] = entity.img1v1Url;
  data['albumSize'] = entity.albumSize;
  data['musicSize'] = entity.musicSize;
  data['mvSize'] = entity.mvSize;
  data['briefDesc'] = entity.briefDesc;
  return data;
}

ArtistHotSong $ArtistHotSongFromJson(Map<String, dynamic> json) {
  final ArtistHotSong entity = ArtistHotSong();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    entity.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    entity.name = name;
  }
  final List<ArtistHotSongAr>? ar = (json['ar'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<ArtistHotSongAr>(e) as ArtistHotSongAr)
      .toList();
  if (ar != null) {
    entity.ar = ar;
  }
  final ArtistHotSongAl? al = jsonConvert.convert<ArtistHotSongAl>(
    json['al'],
  );
  if (al != null) {
    entity.al = al;
  }
  final int? dt = jsonConvert.convert<int>(json['dt']);
  if (dt != null) {
    entity.dt = dt;
  }
  final int? fee = jsonConvert.convert<int>(json['fee']);
  if (fee != null) {
    entity.fee = fee;
  }
  return entity;
}

Map<String, dynamic> $ArtistHotSongToJson(ArtistHotSong entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['ar'] = entity.ar?.map((v) => v.toJson()).toList();
  data['al'] = entity.al?.toJson();
  data['dt'] = entity.dt;
  data['fee'] = entity.fee;
  return data;
}

ArtistHotSongAr $ArtistHotSongArFromJson(Map<String, dynamic> json) {
  final ArtistHotSongAr entity = ArtistHotSongAr();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    entity.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    entity.name = name;
  }
  return entity;
}

Map<String, dynamic> $ArtistHotSongArToJson(ArtistHotSongAr entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  return data;
}

ArtistHotSongAl $ArtistHotSongAlFromJson(Map<String, dynamic> json) {
  final ArtistHotSongAl entity = ArtistHotSongAl();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    entity.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    entity.name = name;
  }
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) {
    entity.picUrl = picUrl;
  }
  return entity;
}

Map<String, dynamic> $ArtistHotSongAlToJson(ArtistHotSongAl entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}
