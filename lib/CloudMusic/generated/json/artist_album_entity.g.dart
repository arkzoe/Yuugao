import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_album_entity.dart';

ArtistAlbumEntity $ArtistAlbumEntityFromJson(Map<String, dynamic> json) {
  final src = (json.containsKey('data') && json['data'] is Map<String, dynamic>)
      ? json['data'] as Map<String, dynamic>
      : json;

  final ArtistAlbumEntity entity = ArtistAlbumEntity();
  final int? code = jsonConvert.convert<int>(src['code']);
  if (code != null) {
    entity.code = code;
  }
  final bool? more = jsonConvert.convert<bool>(src['more']);
  if (more != null) {
    entity.more = more;
  }
  final ArtistAlbumArtist? artist = jsonConvert.convert<ArtistAlbumArtist>(
    src['artist'],
  );
  if (artist != null) {
    entity.artist = artist;
  }
  final List<ArtistAlbumHotAlbum>? hotAlbums =
      (src['hotAlbums'] as List<dynamic>?)
          ?.map(
            (e) =>
                jsonConvert.convert<ArtistAlbumHotAlbum>(e)
                    as ArtistAlbumHotAlbum,
          )
          .toList();
  if (hotAlbums != null) {
    entity.hotAlbums = hotAlbums;
  }
  return entity;
}

Map<String, dynamic> $ArtistAlbumEntityToJson(ArtistAlbumEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['more'] = entity.more;
  data['artist'] = entity.artist?.toJson();
  data['hotAlbums'] = entity.hotAlbums?.map((v) => v.toJson()).toList();
  return data;
}

ArtistAlbumArtist $ArtistAlbumArtistFromJson(Map<String, dynamic> json) {
  final ArtistAlbumArtist entity = ArtistAlbumArtist();
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

Map<String, dynamic> $ArtistAlbumArtistToJson(ArtistAlbumArtist entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}

ArtistAlbumHotAlbum $ArtistAlbumHotAlbumFromJson(Map<String, dynamic> json) {
  final ArtistAlbumHotAlbum entity = ArtistAlbumHotAlbum();
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
  final int? size = jsonConvert.convert<int>(json['size']);
  if (size != null) {
    entity.size = size;
  }
  final int? publishTime = jsonConvert.convert<int>(json['publishTime']);
  if (publishTime != null) {
    entity.publishTime = publishTime;
  }
  final String? company = jsonConvert.convert<String>(json['company']);
  if (company != null) {
    entity.company = company;
  }
  final List<ArtistAlbumHotAlbumArtist>? artists =
      (json['artists'] as List<dynamic>?)
          ?.map(
            (e) =>
                jsonConvert.convert<ArtistAlbumHotAlbumArtist>(e)
                    as ArtistAlbumHotAlbumArtist,
          )
          .toList();
  if (artists != null) {
    entity.artists = artists;
  }
  return entity;
}

Map<String, dynamic> $ArtistAlbumHotAlbumToJson(ArtistAlbumHotAlbum entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  data['size'] = entity.size;
  data['publishTime'] = entity.publishTime;
  data['company'] = entity.company;
  data['artists'] = entity.artists?.map((v) => v.toJson()).toList();
  return data;
}

ArtistAlbumHotAlbumArtist $ArtistAlbumHotAlbumArtistFromJson(
  Map<String, dynamic> json,
) {
  final ArtistAlbumHotAlbumArtist entity = ArtistAlbumHotAlbumArtist();
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

Map<String, dynamic> $ArtistAlbumHotAlbumArtistToJson(
  ArtistAlbumHotAlbumArtist entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  return data;
}
