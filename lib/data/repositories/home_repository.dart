import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/models/notification_settings.dart';

/// 홈 화면, 내 프로필, 알림, 알림 설정 관련 API
class HomeRepository {
  HomeRepository._();
  static final HomeRepository instance = HomeRepository._();

  /// GET /dashboard/home
  /// 내 프로필, 요약 숫자, 할 일, 최근 알림, 결재 대기, 일정, 프로젝트를 한 번에 받아요.
  /// 재정 권한(Admin, FA, Leader)이 있으면 finance도 같이 와요.
  Future<HomeDashboard> getDashboard() async {
    final data = await ApiClient.instance.get('/dashboard/home');
    return HomeDashboard.fromJson(_asMap(data));
  }

  /// GET /me  (내 프로필)
  Future<MyProfile> getMe() async {
    final data = await ApiClient.instance.get('/me');
    return MyProfile.fromJson(_asMap(data));
  }

  // ───────────── 알림 ─────────────

  /// GET /notifications?kind=&unread=&cursor=&limit=
  /// - kind: 내 업무, 재정, 일정, 공지 (null이면 전체)
  /// - unreadOnly: true면 안 읽은 알림만
  /// - cursor: 이전 응답의 nextCursor (다음 페이지)
  Future<NotificationPage> getNotifications({
    String? kind,
    bool unreadOnly = false,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/notifications',
      query: {
        'kind': kind,
        if (unreadOnly) 'unread': true,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return NotificationPage.fromJson(_asMap(data));
  }

  /// POST /notifications/read  { id }  → 알림 하나 읽음 처리
  /// 반환값: 서버가 읽음 처리한 개수
  Future<int> markNotificationRead(String id) async {
    final data = await ApiClient.instance.post(
      '/notifications/read',
      body: {'id': id, 'all': false},
    );
    return _updatedCount(data);
  }

  /// POST /notifications/read  { all: true }  → 전체 읽음 처리
  Future<int> markAllNotificationsRead() async {
    final data = await ApiClient.instance.post(
      '/notifications/read',
      body: {'all': true},
    );
    return _updatedCount(data);
  }

  // ───────────── 알림 설정 ─────────────

  /// GET /me/notification-settings
  Future<NotificationSettings> getNotificationSettings() async {
    final data = await ApiClient.instance.get('/me/notification-settings');
    return NotificationSettings.fromJson(_asMap(data));
  }

  /// PATCH /me/notification-settings  (보낸 값만 바뀌어요)
  /// - kinds: {'내 업무': false} 처럼 바꿀 분류만 보내도 돼요
  /// - current: 지금 화면의 설정. 서버 응답을 이 값 위에 합쳐서 돌려줘요.
  Future<NotificationSettings> updateNotificationSettings({
    required NotificationSettings current,
    bool? push,
    Map<String, bool>? kinds,
    bool? dnd,
    String? dndFrom,
    String? dndTo,
    List<String>? dndDays,
  }) async {
    final data = await ApiClient.instance.patch(
      '/me/notification-settings',
      body: {
        if (push != null) 'push': push,
        if (kinds != null) 'kinds': kinds,
        if (dnd != null) 'dnd': dnd,
        if (dndFrom != null) 'dndFrom': dndFrom,
        if (dndTo != null) 'dndTo': dndTo,
        if (dndDays != null) 'dndDays': dndDays,
      },
    );
    return current.mergedWith(_asMap(data));
  }

  // ───────────── 헬퍼 ─────────────

  int _updatedCount(dynamic data) {
    if (data is Map) {
      final v = data['updated'];
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}