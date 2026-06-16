import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/podcast/entity/dj_program_entity.dart';

DjProgramEntity $DjProgramEntityFromJson(Map<String, dynamic> json) {
  final DjProgramEntity entity = DjProgramEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) entity.code = code;
  final int? count = jsonConvert.convert<int>(json['count']);
  if (count != null) entity.count = count;
  final bool? more = jsonConvert.convert<bool>(json['more']);
  if (more != null) entity.more = more;
  final List<DjProgramItem>? programs = (json['programs'] as List<dynamic>?)
      ?.map((e) =>
          jsonConvert.convert<DjProgramItem>(e) as DjProgramItem)
      .toList();
  if (programs != null) entity.programs = programs;
  return entity;
}

Map<String, dynamic> $DjProgramEntityToJson(DjProgramEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['count'] = entity.count;
  data['more'] = entity.more;
  data['programs'] = entity.programs?.map((v) => v.toJson()).toList();
  return data;
}

DjProgramItem $DjProgramItemFromJson(Map<String, dynamic> json) {
  final DjProgramItem item = DjProgramItem();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? description =
      jsonConvert.convert<String>(json['description']);
  if (description != null) item.description = description;
  final int? duration = jsonConvert.convert<int>(json['duration']);
  if (duration != null) item.duration = duration;
  final int? createTime = jsonConvert.convert<int>(json['createTime']);
  if (createTime != null) item.createTime = createTime;
  final int? listenerCount =
      jsonConvert.convert<int>(json['listenerCount']);
  if (listenerCount != null) item.listenerCount = listenerCount;
  final int? likedCount = jsonConvert.convert<int>(json['likedCount']);
  if (likedCount != null) item.likedCount = likedCount;
  final int? commentCount =
      jsonConvert.convert<int>(json['commentCount']);
  if (commentCount != null) item.commentCount = commentCount;
  final int? fee = jsonConvert.convert<int>(json['fee']);
  if (fee != null) item.fee = fee;
  final DjProgramMainSong? mainSong =
      jsonConvert.convert<DjProgramMainSong>(json['mainSong']);
  if (mainSong != null) item.mainSong = mainSong;
  final DjProgramRadio? radio =
      jsonConvert.convert<DjProgramRadio>(json['radio']);
  if (radio != null) item.radio = radio;
  final DjProgramDj? dj =
      jsonConvert.convert<DjProgramDj>(json['dj']);
  if (dj != null) item.dj = dj;
  return item;
}

Map<String, dynamic> $DjProgramItemToJson(DjProgramItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['description'] = entity.description;
  data['duration'] = entity.duration;
  data['createTime'] = entity.createTime;
  data['listenerCount'] = entity.listenerCount;
  data['likedCount'] = entity.likedCount;
  data['commentCount'] = entity.commentCount;
  data['fee'] = entity.fee;
  data['mainSong'] = entity.mainSong?.toJson();
  data['radio'] = entity.radio?.toJson();
  data['dj'] = entity.dj?.toJson();
  return data;
}

DjProgramMainSong $DjProgramMainSongFromJson(Map<String, dynamic> json) {
  final DjProgramMainSong item = DjProgramMainSong();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final int? duration = jsonConvert.convert<int>(json['duration']);
  if (duration != null) item.duration = duration;
  final String? albumName =
      jsonConvert.convert<String>(json['albumName']);
  if (albumName != null) item.albumName = albumName;
  final String? albumPic =
      jsonConvert.convert<String>(json['albumPic']);
  if (albumPic != null) item.albumPic = albumPic;
  return item;
}

Map<String, dynamic> $DjProgramMainSongToJson(DjProgramMainSong entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['duration'] = entity.duration;
  data['albumName'] = entity.albumName;
  data['albumPic'] = entity.albumPic;
  return data;
}

DjProgramRadio $DjProgramRadioFromJson(Map<String, dynamic> json) {
  final DjProgramRadio item = DjProgramRadio();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) item.id = id;
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) item.name = name;
  final String? picUrl = jsonConvert.convert<String>(json['picUrl']);
  if (picUrl != null) item.picUrl = picUrl;
  return item;
}

Map<String, dynamic> $DjProgramRadioToJson(DjProgramRadio entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}

DjProgramDj $DjProgramDjFromJson(Map<String, dynamic> json) {
  final DjProgramDj item = DjProgramDj();
  final String? nickname = jsonConvert.convert<String>(json['nickname']);
  if (nickname != null) item.nickname = nickname;
  final int? userId = jsonConvert.convert<int>(json['userId']);
  if (userId != null) item.userId = userId;
  return item;
}

Map<String, dynamic> $DjProgramDjToJson(DjProgramDj entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['nickname'] = entity.nickname;
  data['userId'] = entity.userId;
  return data;
}
