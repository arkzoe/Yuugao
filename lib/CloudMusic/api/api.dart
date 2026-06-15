class Api {
  //用户部分
  //手机号登录
  static const String loginCellPhone = '/api/w/login/cellphone';

  //邮箱号登录（与手机登录同路径，参数区分）
  static const String loginCellEmail = '/api/w/login/cellphone';

  //发送验证码
  static const String sendSmsCode = '/api/sms/captcha/sent';

  //验证验证码
  static const String verifySmsCode = '/api/sms/captcha/verify';

  //用户信息
  static const String userInfo = '/api/nuser/account/get';

  //生成二维码key
  static const String qrCodeKey = '/api/login/qrcode/unikey';

  //检测二维码
  static const String checkQrCode = '/api/login/qrcode/client/login';

  //退出登录
  static const String logout = '/api/logout';

  //用户歌单
  static const String userPlaylist = '/api/user/playlist';

  //用户喜欢列表
  static const String userLikeList = '/api/song/like/get';

  ///推荐部分
  //每日推荐歌曲
  static const String recommendSongs = '/api/v3/discovery/recommend/songs';

  //每日推荐歌单
  static const String recommendResource = '/api/v1/discovery/recommend/resource';

  //对推荐不感兴趣
  static const String recommendDislike = '/api/v2/discovery/recommend/dislike';

  ///top系列
  //热门歌手
  static const String topArtist = '/api/artist/top';

  ///album
  //最新专辑
  static const String newAlbum = '/api/album/new';

  //专辑内容
  static const String albumInfo = '/api/v1/album';

  //歌手专辑
  static const String artistAlbum = '/api/artist/albums';

  ///playlist
  //歌单分类
  static const String playlistCatalogue = '/api/playlist/catalogue';

  //创建歌单
  static const String createPlaylist = '/api/playlist/create';

  //删除歌单
  static const String removePlaylist = '/api/playlist/remove';

  //更新歌单描述
  static const String updatePlaylistDesc = '/api/playlist/desc/update';

  //歌单详情
  static const String playlistDetail = '/api/v6/playlist/detail';

  //歌单动态详情
  static const String playlistDetailDynamic = '/api/playlist/detail/dynamic';

  //相关歌单推荐
  static const String recommendByPlaylist = '/api/playlist/detail/rcmd/get';

  //精品歌单tags
  static const String highQualityTags = '/api/playlist/highquality/tags';

  /// song
  //新歌速递
  static const String newSongs = '/api/v1/discovery/new/songs';
  //歌曲地址
  static const String songUrl = '/api/song/enhance/player/url/v1';
  //歌曲详情
  static const String songDetail = '/api/v3/song/detail';
  //检查歌曲是否喜欢
  static const String songLikeCheck = '/api/song/like/check';
  //歌曲音质详情
  static const String songQualityDetail = '/api/song/music/detail/get';
  //歌曲被喜欢数量
  static const String songLikeCount = '/api/song/red/count';

  /// 歌词
  static const String songLyric = '/api/song/lyric';

  /// 喜欢/取消喜欢歌曲
  static const String songLike = '/api/song/like';

  /// 歌曲评论（实际拼接为 R_SO_4_{id}）
  static const String songComments = '/api/v1/resource/comments/R_SO_4_';

  /// 搜索
  static const String search = '/api/search/get';

  /// mv
  //Mv播放地址
  static const String mvUrl = '/weapi/song/enhance/play/mv/url';

  /// 推荐新歌
  static const String recommendNewSong = '/api/v2/personalized/newsong';

  /// 首页龙珠
  static const String homepageDragonBall = '/api/homepage/dragon/ball/static';

  /// 私人FM
  static const String personalFm = '/api/v1/radio/get';

  /// FM垃圾桶
  static const String fmTrash = '/api/radio/trash/add';

  /// 心动模式 / 智能播放列表
  ///
  /// 前缀 `/api/` 是为了让 weApi 拦截器的正则 \w*api 能匹配并改写为
  /// `/weapi/playmode/intelligence/list`，否则原路径不含 "api" 导致
  /// 请求发到错误地址。
  static const String playmodeIntelligenceList =
      '/api/playmode/intelligence/list';

}
