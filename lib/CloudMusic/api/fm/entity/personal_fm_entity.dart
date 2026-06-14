import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/personal_fm_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/personal_fm_entity.g.dart';

@JsonSerializable()
class PersonalFmEntity {
  int? code = 0;
  List<PersonalFmData>? data = [];

  PersonalFmEntity();

  factory PersonalFmEntity.fromJson(Map<String, dynamic> json) =>
      $PersonalFmEntityFromJson(json);

  Map<String, dynamic> toJson() => $PersonalFmEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class PersonalFmData {
  int? id = 0;
  String? name = '';
  List<PersonalFmDataAr>? ar = [];
  PersonalFmDataAl? al;
  int? dt = 0;
  int? fee = 0;
  int? pop = 0;
  int? mv = 0;
  String? cf = '';
  String? rt = '';
  int? cp = 0;
  int? djId = 0;
  int? copyright = 0;
  int? rtype = 0;
  dynamic rurl;
  dynamic reason;
  dynamic recommendReason;
  dynamic privilege;

  PersonalFmData();

  factory PersonalFmData.fromJson(Map<String, dynamic> json) =>
      $PersonalFmDataFromJson(json);

  Map<String, dynamic> toJson() => $PersonalFmDataToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class PersonalFmDataAr {
  int? id = 0;
  String? name = '';

  PersonalFmDataAr();

  factory PersonalFmDataAr.fromJson(Map<String, dynamic> json) =>
      $PersonalFmDataArFromJson(json);

  Map<String, dynamic> toJson() => $PersonalFmDataArToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class PersonalFmDataAl {
  int? id = 0;
  String? name = '';
  String? picUrl = '';

  PersonalFmDataAl();

  factory PersonalFmDataAl.fromJson(Map<String, dynamic> json) =>
      $PersonalFmDataAlFromJson(json);

  Map<String, dynamic> toJson() => $PersonalFmDataAlToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
