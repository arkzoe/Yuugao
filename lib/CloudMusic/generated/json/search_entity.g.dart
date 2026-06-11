import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/search/entity/search_entity.dart';

SearchEntity $SearchEntityFromJson(Map<String, dynamic> json) {
  final SearchEntity searchEntity = SearchEntity();
  final SearchResult? result = jsonConvert.convert<SearchResult>(
    json['result'],
  );
  if (result != null) {
    searchEntity.result = result;
  }
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    searchEntity.code = code;
  }
  return searchEntity;
}

Map<String, dynamic> $SearchEntityToJson(SearchEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['result'] = entity.result?.toJson();
  data['code'] = entity.code;
  return data;
}

SearchResult $SearchResultFromJson(Map<String, dynamic> json) {
  final SearchResult searchResult = SearchResult();
  final List<SearchSongItem>? songs = (json['songs'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<SearchSongItem>(e) as SearchSongItem)
      .toList();
  if (songs != null) {
    searchResult.songs = songs;
  }
  final int? songCount = jsonConvert.convert<int>(json['songCount']);
  if (songCount != null) {
    searchResult.songCount = songCount;
  }
  final bool? hasMore = jsonConvert.convert<bool>(json['hasMore']);
  if (hasMore != null) {
    searchResult.hasMore = hasMore;
  }
  return searchResult;
}

Map<String, dynamic> $SearchResultToJson(SearchResult entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['songs'] = entity.songs?.map((v) => v.toJson()).toList();
  data['songCount'] = entity.songCount;
  data['hasMore'] = entity.hasMore;
  return data;
}

SearchSongItem $SearchSongItemFromJson(Map<String, dynamic> json) {
  final SearchSongItem searchSongItem = SearchSongItem();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    searchSongItem.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    searchSongItem.name = name;
  }
  final List<SearchSongArtist>? artists = (json['artists'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<SearchSongArtist>(e) as SearchSongArtist)
      .toList();
  if (artists != null) {
    searchSongItem.artists = artists;
  }
  final SearchSongAlbum? album = jsonConvert.convert<SearchSongAlbum>(
    json['album'],
  );
  if (album != null) {
    searchSongItem.album = album;
  }
  final int? duration = jsonConvert.convert<int>(json['duration']);
  if (duration != null) {
    searchSongItem.duration = duration;
  }
  final int? fee = jsonConvert.convert<int>(json['fee']);
  if (fee != null) {
    searchSongItem.fee = fee;
  }
  return searchSongItem;
}

Map<String, dynamic> $SearchSongItemToJson(SearchSongItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['artists'] = entity.artists?.map((v) => v.toJson()).toList();
  data['album'] = entity.album?.toJson();
  data['duration'] = entity.duration;
  data['fee'] = entity.fee;
  return data;
}

SearchSongArtist $SearchSongArtistFromJson(Map<String, dynamic> json) {
  final SearchSongArtist searchSongArtist = SearchSongArtist();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    searchSongArtist.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    searchSongArtist.name = name;
  }
  return searchSongArtist;
}

Map<String, dynamic> $SearchSongArtistToJson(SearchSongArtist entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  return data;
}

SearchSongAlbum $SearchSongAlbumFromJson(Map<String, dynamic> json) {
  final SearchSongAlbum searchSongAlbum = SearchSongAlbum();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    searchSongAlbum.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    searchSongAlbum.name = name;
  }
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) {
    searchSongAlbum.picUrl = picUrl;
  }
  return searchSongAlbum;
}

Map<String, dynamic> $SearchSongAlbumToJson(SearchSongAlbum entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}
