import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/dj_program_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/dj_program_entity.g.dart';

/// 播客/电台节目列表（by radioId）
@JsonSerializable()
class DjProgramEntity {
  int? code = 0;
  int? count = 0;
  bool? more = false;
  List<DjProgramItem>? programs = [];

  DjProgramEntity();

  factory DjProgramEntity.fromJson(Map<String, dynamic> json) =>
      $DjProgramEntityFromJson(json);

  Map<String, dynamic> toJson() => $DjProgramEntityToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class DjProgramItem {
  int? id = 0;
  String? name = '';
  String? description = '';
  int? duration = 0;
  int? createTime = 0;
  int? listenerCount = 0;
  int? likedCount = 0;
  int? commentCount = 0;
  int? fee = 0;
  DjProgramMainSong? mainSong;
  DjProgramRadio? radio;
  DjProgramDj? dj;

  DjProgramItem();

  factory DjProgramItem.fromJson(Map<String, dynamic> json) =>
      $DjProgramItemFromJson(json);

  Map<String, dynamic> toJson() => $DjProgramItemToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class DjProgramMainSong {
  int? id = 0;
  String? name = '';
  int? duration = 0;
  String? albumName = '';
  String? albumPic = '';

  DjProgramMainSong();

  factory DjProgramMainSong.fromJson(Map<String, dynamic> json) =>
      $DjProgramMainSongFromJson(json);

  Map<String, dynamic> toJson() => $DjProgramMainSongToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class DjProgramRadio {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  DjProgramRadio();

  factory DjProgramRadio.fromJson(Map<String, dynamic> json) =>
      $DjProgramRadioFromJson(json);

  Map<String, dynamic> toJson() => $DjProgramRadioToJson(this);

  @override
  String toString() => jsonEncode(this);
}

@JsonSerializable()
class DjProgramDj {
  String? nickname = '';
  int? userId = 0;

  DjProgramDj();

  factory DjProgramDj.fromJson(Map<String, dynamic> json) =>
      $DjProgramDjFromJson(json);

  Map<String, dynamic> toJson() => $DjProgramDjToJson(this);

  @override
  String toString() => jsonEncode(this);
}
