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
  final List<SearchArtistItem>? artists = (json['artists'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<SearchArtistItem>(e) as SearchArtistItem)
      .toList();
  if (artists != null) {
    searchResult.artists = artists;
  }
  final int? artistCount = jsonConvert.convert<int>(json['artistCount']);
  if (artistCount != null) {
    searchResult.artistCount = artistCount;
  }
  final List<SearchAlbumItem>? albums = (json['albums'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<SearchAlbumItem>(e) as SearchAlbumItem)
      .toList();
  if (albums != null) {
    searchResult.albums = albums;
  }
  final int? albumCount = jsonConvert.convert<int>(json['albumCount']);
  if (albumCount != null) {
    searchResult.albumCount = albumCount;
  }
  final List<SearchPlaylistItem>? playlists = (json['playlists'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<SearchPlaylistItem>(e) as SearchPlaylistItem)
      .toList();
  if (playlists != null) {
    searchResult.playlists = playlists;
  }
  final int? playlistCount = jsonConvert.convert<int>(json['playlistCount']);
  if (playlistCount != null) {
    searchResult.playlistCount = playlistCount;
  }
  return searchResult;
}

Map<String, dynamic> $SearchResultToJson(SearchResult entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['songs'] = entity.songs?.map((v) => v.toJson()).toList();
  data['songCount'] = entity.songCount;
  data['hasMore'] = entity.hasMore;
  data['artists'] = entity.artists?.map((v) => v.toJson()).toList();
  data['artistCount'] = entity.artistCount;
  data['albums'] = entity.albums?.map((v) => v.toJson()).toList();
  data['albumCount'] = entity.albumCount;
  data['playlists'] = entity.playlists?.map((v) => v.toJson()).toList();
  data['playlistCount'] = entity.playlistCount;
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

// ═══ 歌手搜索结果 ═══

SearchArtistItem $SearchArtistItemFromJson(Map<String, dynamic> json) {
  final SearchArtistItem item = SearchArtistItem();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) item.picUrl = picUrl;
  final String? img1v1Url = jsonConvert.convert<String>(json['img1v1Url']);
  if (img1v1Url != null) item.img1v1Url = img1v1Url;
  final int? albumSize = jsonConvert.convert<int>(json['albumSize']);
  if (albumSize != null) item.albumSize = albumSize;
  final int? musicSize = jsonConvert.convert<int>(json['musicSize']);
  if (musicSize != null) item.musicSize = musicSize;
  final List<String>? alias = (json['alias'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<String>(e) as String)
      .toList();
  if (alias != null) item.alias = alias;
  final String? trans = jsonConvert.convert<String>(json['trans']);
  if (trans != null) item.trans = trans;
  return item;
}

Map<String, dynamic> $SearchArtistItemToJson(SearchArtistItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  data['img1v1Url'] = entity.img1v1Url;
  data['albumSize'] = entity.albumSize;
  data['musicSize'] = entity.musicSize;
  data['alias'] = entity.alias;
  data['trans'] = entity.trans;
  return data;
}

// ═══ 专辑搜索结果 ═══

SearchAlbumItem $SearchAlbumItemFromJson(Map<String, dynamic> json) {
  final SearchAlbumItem item = SearchAlbumItem();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) item.picUrl = picUrl;
  final SearchAlbumItemArtist? artist = jsonConvert.convert<SearchAlbumItemArtist>(json['artist']);
  if (artist != null) item.artist = artist;
  final int? size = jsonConvert.convert<int>(json['size']);
  if (size != null) item.size = size;
  final int? publishTime = jsonConvert.convert<int>(json['publishTime']);
  if (publishTime != null) item.publishTime = publishTime;
  return item;
}

Map<String, dynamic> $SearchAlbumItemToJson(SearchAlbumItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  data['artist'] = entity.artist?.toJson();
  data['size'] = entity.size;
  data['publishTime'] = entity.publishTime;
  return data;
}

SearchAlbumItemArtist $SearchAlbumItemArtistFromJson(Map<String, dynamic> json) {
  final SearchAlbumItemArtist item = SearchAlbumItemArtist();
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  return item;
}

Map<String, dynamic> $SearchAlbumItemArtistToJson(SearchAlbumItemArtist entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['name'] = entity.name;
  return data;
}

// ═══ 歌单搜索结果 ═══

SearchPlaylistItem $SearchPlaylistItemFromJson(Map<String, dynamic> json) {
  final SearchPlaylistItem item = SearchPlaylistItem();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? coverImgUrl = jsonConvert.convert<String>(json['coverImgUrl']);
  if (coverImgUrl != null) item.coverImgUrl = coverImgUrl;
  final int? trackCount = jsonConvert.convert<int>(json['trackCount']);
  if (trackCount != null) item.trackCount = trackCount;
  final int? playCount = jsonConvert.convert<int>(json['playCount']);
  if (playCount != null) item.playCount = playCount;
  final int? bookCount = jsonConvert.convert<int>(json['bookCount']);
  if (bookCount != null) item.bookCount = bookCount;
  final SearchPlaylistItemCreator? creator = jsonConvert.convert<SearchPlaylistItemCreator>(json['creator']);
  if (creator != null) item.creator = creator;
  return item;
}

Map<String, dynamic> $SearchPlaylistItemToJson(SearchPlaylistItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['coverImgUrl'] = entity.coverImgUrl;
  data['trackCount'] = entity.trackCount;
  data['playCount'] = entity.playCount;
  data['bookCount'] = entity.bookCount;
  data['creator'] = entity.creator?.toJson();
  return data;
}

SearchPlaylistItemCreator $SearchPlaylistItemCreatorFromJson(Map<String, dynamic> json) {
  final SearchPlaylistItemCreator item = SearchPlaylistItemCreator();
  final String? nickname = jsonConvert.convert<String>(json['nickname']);
  if (nickname != null) item.nickname = nickname;
  return item;
}

Map<String, dynamic> $SearchPlaylistItemCreatorToJson(SearchPlaylistItemCreator entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['nickname'] = entity.nickname;
  return data;
}
