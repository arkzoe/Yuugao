import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/artist/entity/artist_desc_entity.dart';

ArtistDescEntity $ArtistDescEntityFromJson(Map<String, dynamic> json) {
  final src = (json.containsKey('data') && json['data'] is Map<String, dynamic>)
      ? json['data'] as Map<String, dynamic>
      : json;

  final ArtistDescEntity entity = ArtistDescEntity();
  final int? code = jsonConvert.convert<int>(src['code']);
  if (code != null) {
    entity.code = code;
  }
  final String? briefDesc = jsonConvert.convert<String>(src['briefDesc']);
  if (briefDesc != null) {
    entity.briefDesc = briefDesc;
  }
  final List<ArtistDescIntroduction>? introduction =
      (src['introduction'] as List<dynamic>?)
          ?.map(
            (e) =>
                jsonConvert.convert<ArtistDescIntroduction>(e)
                    as ArtistDescIntroduction,
          )
          .toList();
  if (introduction != null) {
    entity.introduction = introduction;
  }
  final int? count = jsonConvert.convert<int>(src['count']);
  if (count != null) {
    entity.count = count;
  }
  return entity;
}

Map<String, dynamic> $ArtistDescEntityToJson(ArtistDescEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['briefDesc'] = entity.briefDesc;
  data['introduction'] =
      entity.introduction?.map((v) => v.toJson()).toList();
  data['count'] = entity.count;
  return data;
}

ArtistDescIntroduction $ArtistDescIntroductionFromJson(
  Map<String, dynamic> json,
) {
  final ArtistDescIntroduction entity = ArtistDescIntroduction();
  final String? ti = jsonConvert.convert<String>(json['ti']);
  if (ti != null) {
    entity.ti = ti;
  }
  final String? txt = jsonConvert.convert<String>(json['txt']);
  if (txt != null) {
    entity.txt = txt;
  }
  return entity;
}

Map<String, dynamic> $ArtistDescIntroductionToJson(
  ArtistDescIntroduction entity,
) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['ti'] = entity.ti;
  data['txt'] = entity.txt;
  return data;
}
