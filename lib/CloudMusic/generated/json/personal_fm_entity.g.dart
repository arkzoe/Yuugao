import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/fm/entity/personal_fm_entity.dart';

PersonalFmEntity $PersonalFmEntityFromJson(Map<String, dynamic> json) {
  final PersonalFmEntity entity = PersonalFmEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    entity.code = code;
  }
  final List<PersonalFmData>? data = (json['data'] as List<dynamic>?)
      ?.map(
        (e) =>
            jsonConvert.convert<PersonalFmData>(e) as PersonalFmData,
      )
      .toList();
  if (data != null) {
    entity.data = data;
  }
  return entity;
}

Map<String, dynamic> $PersonalFmEntityToJson(PersonalFmEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['data'] = entity.data?.map((v) => v.toJson()).toList();
  return data;
}

PersonalFmData $PersonalFmDataFromJson(Map<String, dynamic> json) {
  final PersonalFmData entity = PersonalFmData();
  final int? id = jsonConvert.convert<int>(json['id']);
  if (id != null) {
    entity.id = id;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    entity.name = name;
  }
  final List<PersonalFmDataAr>? ar = (json['ar'] as List<dynamic>?)
      ?.map(
        (e) =>
            jsonConvert.convert<PersonalFmDataAr>(e) as PersonalFmDataAr,
      )
      .toList();
  if (ar != null) {
    entity.ar = ar;
  }
  final PersonalFmDataAl? al =
      jsonConvert.convert<PersonalFmDataAl>(json['al']);
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
  final int? pop = jsonConvert.convert<int>(json['pop']);
  if (pop != null) {
    entity.pop = pop;
  }
  final int? mv = jsonConvert.convert<int>(json['mv']);
  if (mv != null) {
    entity.mv = mv;
  }
  final String? cf = jsonConvert.convert<String>(json['cf']);
  if (cf != null) {
    entity.cf = cf;
  }
  final String? rt = jsonConvert.convert<String>(json['rt']);
  if (rt != null) {
    entity.rt = rt;
  }
  final int? cp = jsonConvert.convert<int>(json['cp']);
  if (cp != null) {
    entity.cp = cp;
  }
  final int? djId = jsonConvert.convert<int>(json['djId']);
  if (djId != null) {
    entity.djId = djId;
  }
  final int? copyright = jsonConvert.convert<int>(json['copyright']);
  if (copyright != null) {
    entity.copyright = copyright;
  }
  final int? rtype = jsonConvert.convert<int>(json['rtype']);
  if (rtype != null) {
    entity.rtype = rtype;
  }
  final dynamic rurl = json['rurl'];
  if (rurl != null) {
    entity.rurl = rurl;
  }
  final dynamic reason = json['reason'];
  if (reason != null) {
    entity.reason = reason;
  }
  final dynamic recommendReason = json['recommendReason'];
  if (recommendReason != null) {
    entity.recommendReason = recommendReason;
  }
  final dynamic privilege = json['privilege'];
  if (privilege != null) {
    entity.privilege = privilege;
  }
  return entity;
}

Map<String, dynamic> $PersonalFmDataToJson(PersonalFmData entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['ar'] = entity.ar?.map((v) => v.toJson()).toList();
  data['al'] = entity.al?.toJson();
  data['dt'] = entity.dt;
  data['fee'] = entity.fee;
  data['pop'] = entity.pop;
  data['mv'] = entity.mv;
  data['cf'] = entity.cf;
  data['rt'] = entity.rt;
  data['cp'] = entity.cp;
  data['djId'] = entity.djId;
  data['copyright'] = entity.copyright;
  data['rtype'] = entity.rtype;
  data['rurl'] = entity.rurl;
  data['reason'] = entity.reason;
  data['recommendReason'] = entity.recommendReason;
  data['privilege'] = entity.privilege;
  return data;
}

PersonalFmDataAr $PersonalFmDataArFromJson(Map<String, dynamic> json) {
  final PersonalFmDataAr entity = PersonalFmDataAr();
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

Map<String, dynamic> $PersonalFmDataArToJson(PersonalFmDataAr entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  return data;
}

PersonalFmDataAl $PersonalFmDataAlFromJson(Map<String, dynamic> json) {
  final PersonalFmDataAl entity = PersonalFmDataAl();
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

Map<String, dynamic> $PersonalFmDataAlToJson(PersonalFmDataAl entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['id'] = entity.id;
  data['name'] = entity.name;
  data['picUrl'] = entity.picUrl;
  return data;
}
