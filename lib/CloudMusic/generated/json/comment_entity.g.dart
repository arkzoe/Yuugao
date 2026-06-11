import 'package:yuugao/CloudMusic/generated/json/base/json_convert_content.dart';
import 'package:yuugao/CloudMusic/api/song/entity/comment_entity.dart';

CommentEntity $CommentEntityFromJson(Map<String, dynamic> json) {
  final CommentEntity commentEntity = CommentEntity();
  final int? code = jsonConvert.convert<int>(json['code']);
  if (code != null) {
    commentEntity.code = code;
  }
  final int? total = jsonConvert.convert<int>(json['total']);
  if (total != null) {
    commentEntity.total = total;
  }
  final bool? more = jsonConvert.convert<bool>(json['more']);
  if (more != null) {
    commentEntity.more = more;
  }
  final List<CommentItem>? hotComments = (json['hotComments'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<CommentItem>(e) as CommentItem)
      .toList();
  if (hotComments != null) {
    commentEntity.hotComments = hotComments;
  }
  final List<CommentItem>? comments = (json['comments'] as List<dynamic>?)
      ?.map((e) => jsonConvert.convert<CommentItem>(e) as CommentItem)
      .toList();
  if (comments != null) {
    commentEntity.comments = comments;
  }
  return commentEntity;
}

Map<String, dynamic> $CommentEntityToJson(CommentEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['code'] = entity.code;
  data['total'] = entity.total;
  data['more'] = entity.more;
  data['hotComments'] = entity.hotComments?.map((v) => v.toJson()).toList();
  data['comments'] = entity.comments?.map((v) => v.toJson()).toList();
  return data;
}

CommentItem $CommentItemFromJson(Map<String, dynamic> json) {
  final CommentItem commentItem = CommentItem();
  final int? commentId = jsonConvert.convert<int>(json['commentId']);
  if (commentId != null) {
    commentItem.commentId = commentId;
  }
  final String? content = jsonConvert.convert<String>(json['content']);
  if (content != null) {
    commentItem.content = content;
  }
  final int? time = jsonConvert.convert<int>(json['time']);
  if (time != null) {
    commentItem.time = time;
  }
  final String? timeStr = jsonConvert.convert<String>(json['timeStr']);
  if (timeStr != null) {
    commentItem.timeStr = timeStr;
  }
  final int? likedCount = jsonConvert.convert<int>(json['likedCount']);
  if (likedCount != null) {
    commentItem.likedCount = likedCount;
  }
  final bool? liked = jsonConvert.convert<bool>(json['liked']);
  if (liked != null) {
    commentItem.liked = liked;
  }
  final CommentUser? user = jsonConvert.convert<CommentUser>(json['user']);
  if (user != null) {
    commentItem.user = user;
  }
  return commentItem;
}

Map<String, dynamic> $CommentItemToJson(CommentItem entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['commentId'] = entity.commentId;
  data['content'] = entity.content;
  data['time'] = entity.time;
  data['timeStr'] = entity.timeStr;
  data['likedCount'] = entity.likedCount;
  data['liked'] = entity.liked;
  data['user'] = entity.user?.toJson();
  return data;
}

CommentUser $CommentUserFromJson(Map<String, dynamic> json) {
  final CommentUser commentUser = CommentUser();
  final int? userId = jsonConvert.convert<int>(json['userId']);
  if (userId != null) {
    commentUser.userId = userId;
  }
  final String? nickname = jsonConvert.convert<String>(json['nickname']);
  if (nickname != null) {
    commentUser.nickname = nickname;
  }
  final String? avatarUrl = jsonConvert.convert<String>(json['avatarUrl']);
  if (avatarUrl != null) {
    commentUser.avatarUrl = avatarUrl;
  }
  return commentUser;
}

Map<String, dynamic> $CommentUserToJson(CommentUser entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['userId'] = entity.userId;
  data['nickname'] = entity.nickname;
  data['avatarUrl'] = entity.avatarUrl;
  return data;
}
