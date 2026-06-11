import 'package:yuugao/CloudMusic/generated/json/base/json_field.dart';
import 'package:yuugao/CloudMusic/generated/json/comment_entity.g.dart';
import 'dart:convert';
export 'package:yuugao/CloudMusic/generated/json/comment_entity.g.dart';

@JsonSerializable()
class CommentEntity {
  int? code = 0;
  int? total = 0;
  bool? more = false;
  List<CommentItem>? hotComments = [];
  List<CommentItem>? comments = [];

  CommentEntity();

  factory CommentEntity.fromJson(Map<String, dynamic> json) =>
      $CommentEntityFromJson(json);

  Map<String, dynamic> toJson() => $CommentEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class CommentItem {
  int? commentId = 0;
  String? content = '';
  int? time = 0;
  String? timeStr = '';
  int? likedCount = 0;
  bool? liked = false;
  CommentUser? user;

  CommentItem();

  factory CommentItem.fromJson(Map<String, dynamic> json) =>
      $CommentItemFromJson(json);

  Map<String, dynamic> toJson() => $CommentItemToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class CommentUser {
  int? userId = 0;
  String? nickname = '';
  String? avatarUrl = '';

  CommentUser();

  factory CommentUser.fromJson(Map<String, dynamic> json) =>
      $CommentUserFromJson(json);

  Map<String, dynamic> toJson() => $CommentUserToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
