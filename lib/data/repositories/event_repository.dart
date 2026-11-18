import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/event_models.dart';
import 'package:teamspace/data/models/home_models.dart';

/// 일정 API (홈의 알림 상세, 내 공간 캘린더에서 같이 써요)
class EventRepository {
  EventRepository._();
  static final EventRepository instance = EventRepository._();

  static final DateFormat _monthFmt = DateFormat('yyyy-MM');
  static final DateFormat _dayFmt = DateFormat('yyyy-MM-dd');

  /// GET /events?month=YYYY-MM&scope=&q=
  /// 서버가 cursor로 나눠 주면 끝까지 이어서 받아요.
  Future<List<EventDetail>> getMonth(
      DateTime month, {
        String? scope,
        String? q,
      }) async {
    final result = <EventDetail>[];
    String? cursor;
    do {
      final data = await ApiClient.instance.get(
        '/events',
        query: {
          'month': _monthFmt.format(month),
          'scope': scope,
          'q': q,
          'cursor': cursor,
          'limit': 200,
        },
      );
      final map = _asMap(data);
      final items = map['items'];
      if (items is List) {
        result.addAll(items
            .whereType<Map>()
            .map((e) => EventDetail.fromJson(Map<String, dynamic>.from(e))));
      }
      final next = map['nextCursor'];
      cursor = next == null || '$next'.isEmpty ? null : '$next';
    } while (cursor != null);
    return result;
  }

  /// GET /events/{id}
  Future<EventDetail> getEvent(String id) async {
    final data = await ApiClient.instance.get('/events/$id');
    return EventDetail.fromJson(_asMap(data));
  }

  /// POST /admin/events (관리자만) → 새 일정 id
  /// 등록하면 서버가 전체 구성원에게 '새 일정' 알림을 보내요.
  Future<String> createEvent({
    required String title,
    required String scope, // 팀, 프로젝트, 개인
    required DateTime date,
    String start = '', // HH:mm (비우면 하루 종일)
    String end = '',
    String place = '',
    String agenda = '',
    bool rsvp = false,
  }) async {
    final data = await ApiClient.instance.post(
      '/admin/events',
      body: {
        'title': title.trim(),
        'scope': scope,
        'date': _dayFmt.format(date),
        'start': start,
        'end': end,
        'place': place.trim(),
        'agenda': agenda.trim(),
        'rsvp': rsvp,
      },
    );
    return data is Map ? '${data['id'] ?? ''}' : '';
  }

  /// DELETE /admin/events/{id} (관리자만)
  /// 일정과 그 일정의 리마인더 설정이 함께 지워져요.
  Future<void> deleteEvent(String id) async {
    await ApiClient.instance.delete('/admin/events/$id');
  }

  /// POST /events/{id}/rsvp  { rsvp: 참석 | 불참 | 미정, reason }
  /// 반환: 서버에 저장된 응답 시각 (없으면 지금 시각)
  Future<DateTime> rsvp(String id, String rsvp, {String? reason}) async {
    final data = await ApiClient.instance.post(
      '/events/$id/rsvp',
      body: {
        'rsvp': rsvp,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
      },
    );
    final at = data is Map ? DateTime.tryParse('${data['respondedAt']}') : null;
    return at?.toLocal() ?? DateTime.now();
  }

  /// GET /events/{id}/reminders
  Future<EventReminders> getReminders(String id) async {
    final data = await ApiClient.instance.get('/events/$id/reminders');
    return EventReminders.fromJson(_asMap(data));
  }

  /// PATCH /events/{id}/reminders  (세 값 모두 보내요)
  Future<EventReminders> updateReminders(EventReminders value) async {
    final data = await ApiClient.instance.patch(
      '/events/${value.eventId}/reminders',
      body: {
        'oneDayBefore': value.oneDayBefore,
        'oneHourBefore': value.oneHourBefore,
        'tenMinutesBefore': value.tenMinutesBefore,
      },
    );
    return EventReminders.fromJson(_asMap(data));
  }

  /// 일정 알림이 가리키는 일정을 찾아요.
  ///
  /// 실제 서버의 일정 알림은 href가 '/inhouse/my/calendar' 라서 id가 없어요.
  /// 그래서 href에 /events/{id}가 있으면 그걸 쓰고, 없으면 알림 제목
  /// ("새 일정: 주간 팀 회의", "일정이 변경됐어요: 주간 팀 회의")에서 일정 이름을 꺼내
  /// 알림이 온 달부터 3달 안에서 검색해요.
  Future<({EventDetail event, NotificationItem source})?> findForNotifications(
      List<NotificationItem> items) async {
    // 1) href에 id가 있는 알림
    for (final item in items) {
      final m = RegExp(r'/events/([^/?#]+)').firstMatch(item.href);
      if (m != null) {
        try {
          return (event: await getEvent(m.group(1)!), source: item);
        } on ApiException catch (e) {
          if (!e.isNotFound) rethrow; // 지워진 일정이면 다음 알림으로
        }
      }
    }

    // 2) 제목으로 검색 (최근 알림부터)
    for (final item in items) {
      final name = _eventNameFrom(item.title);
      if (name.isEmpty) continue;

      final base = item.createdAt ?? DateTime.now();
      for (var add = 0; add < 3; add++) {
        final month = DateTime(base.year, base.month + add);
        final found = await getMonth(month, q: name);
        if (found.isEmpty) continue;
        final exact = found.where((e) => e.title == name);
        return (event: exact.isNotEmpty ? exact.first : found.first, source: item);
      }
    }
    return null;
  }

  static String _eventNameFrom(String title) {
    final index = title.indexOf(':');
    if (index < 0) return '';
    return title.substring(index + 1).trim();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}