/// 云盘歌曲列表响应实体。
class CloudSongListEntity {
  int? code;
  List<CloudDataEntity>? data;
  int? count;
  bool? hasMore;
  int? size;
  String? maxSize;

  CloudSongListEntity({
    this.code,
    this.data,
    this.count,
    this.hasMore,
    this.size,
    this.maxSize,
  });

  factory CloudSongListEntity.fromJson(Map<String, dynamic> json) {
    return CloudSongListEntity(
      code: json['code'],
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CloudDataEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'],
      hasMore: json['hasMore'],
      size: json['size'],
      maxSize: json['maxSize']?.toString(),
    );
  }
}

/// 云盘单条歌曲数据。
class CloudDataEntity {
  String? songName;
  String? fileName;
  int? addTime;
  String? artist;
  String? album;
  int? fileSize;
  int? songId;
  CloudSimpleSongEntity? simpleSong;

  CloudDataEntity({
    this.songName,
    this.fileName,
    this.addTime,
    this.artist,
    this.album,
    this.fileSize,
    this.songId,
    this.simpleSong,
  });

  factory CloudDataEntity.fromJson(Map<String, dynamic> json) {
    return CloudDataEntity(
      songName: json['songName'],
      fileName: json['fileName'],
      addTime: json['addTime'],
      artist: json['artist'],
      album: json['album'],
      fileSize: json['fileSize'],
      songId: json['songId'],
      simpleSong: json['simpleSong'] != null
          ? CloudSimpleSongEntity.fromJson(
              json['simpleSong'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 云盘歌曲的简化歌曲信息（id / 名称 / 艺术家 / 专辑 / 时长）。
class CloudSimpleSongEntity {
  int? id;
  String? name;
  int? dt; // 时长 ms
  List<CloudArtistEntity>? ar;
  CloudAlbumEntity? al;
  int? fee;

  CloudSimpleSongEntity({
    this.id,
    this.name,
    this.dt,
    this.ar,
    this.al,
    this.fee,
  });

  factory CloudSimpleSongEntity.fromJson(Map<String, dynamic> json) {
    return CloudSimpleSongEntity(
      id: json['id'],
      name: json['name'],
      dt: json['dt'],
      ar: (json['ar'] as List<dynamic>?)
          ?.map((e) => CloudArtistEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      al: json['al'] != null
          ? CloudAlbumEntity.fromJson(json['al'] as Map<String, dynamic>)
          : null,
      fee: json['fee'],
    );
  }
}

class CloudArtistEntity {
  int? id;
  String? name;

  CloudArtistEntity({this.id, this.name});

  factory CloudArtistEntity.fromJson(Map<String, dynamic> json) {
    return CloudArtistEntity(
      id: json['id'],
      name: json['name'],
    );
  }
}

class CloudAlbumEntity {
  int? id;
  String? name;
  String? picUrl;

  CloudAlbumEntity({this.id, this.name, this.picUrl});

  factory CloudAlbumEntity.fromJson(Map<String, dynamic> json) {
    return CloudAlbumEntity(
      id: json['id'],
      name: json['name'],
      picUrl: json['picUrl'],
    );
  }
}
