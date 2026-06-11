import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/song/entity/song_lyric_entity.dart';

SongLyricEntity $SongLyricEntityFromJson(Map<String, dynamic> json) {
  final SongLyricEntity songLyricEntity = SongLyricEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    songLyricEntity.code = code;
  }
  final SongLyricLrc? lrc = jsonConvert.convert<SongLyricLrc>(json['lrc']);
  if (lrc != null) {
    songLyricEntity.lrc = lrc;
  }
  final SongLyricLrc? klyric = jsonConvert.convert<SongLyricLrc>(
    json['klyric'],
  );
  if (klyric != null) {
    songLyricEntity.klyric = klyric;
  }
  final SongLyricLrc? tlyric = jsonConvert.convert<SongLyricLrc>(
    json['tlyric'],
  );
  if (tlyric != null) {
    songLyricEntity.tlyric = tlyric;
  }
  return songLyricEntity;
}

Map<String, dynamic> $SongLyricEntityToJson(SongLyricEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['lrc'] = entity.lrc?.toJson();
  data['klyric'] = entity.klyric?.toJson();
  data['tlyric'] = entity.tlyric?.toJson();
  return data;
}

extension SongLyricEntityExtension on SongLyricEntity {
  SongLyricEntity copyWith({
    int? code,
    SongLyricLrc? lrc,
    SongLyricLrc? klyric,
    SongLyricLrc? tlyric,
  }) {
    return SongLyricEntity()
      ..code = code ?? this.code
      ..lrc = lrc ?? this.lrc
      ..klyric = klyric ?? this.klyric
      ..tlyric = tlyric ?? this.tlyric;
  }
}

SongLyricLrc $SongLyricLrcFromJson(Map<String, dynamic> json) {
  final SongLyricLrc songLyricLrc = SongLyricLrc();
  final String? lyric = jsonConvert.convert<String>(json['lyric']);
  if (lyric != null) {
    songLyricLrc.lyric = lyric;
  }
  final int? version = jsonConvert.convert<int>(json['version']);
  if (version != null) {
    songLyricLrc.version = version;
  }
  return songLyricLrc;
}

Map<String, dynamic> $SongLyricLrcToJson(SongLyricLrc entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['lyric'] = entity.lyric;
  data['version'] = entity.version;
  return data;
}

extension SongLyricLrcExtension on SongLyricLrc {
  SongLyricLrc copyWith({String? lyric, int? version}) {
    return SongLyricLrc()
      ..lyric = lyric ?? this.lyric
      ..version = version ?? this.version;
  }
}
