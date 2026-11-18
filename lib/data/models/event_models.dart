// 일정 API 응답 모델
// - GET  /events/{id}             (services/events.py event_response)
// - POST /events/{id}/rsvp        → { eventId, rsvp, respondedAt }
// - GET / PATCH /events/{id}/reminders → { eventId, oneDayBefore, oneHourBefore, tenMinutesBefore }

String _str(dynamic v) => v == null ? '' : v.toString();
int _int(dynamic v) => v is int ? v : (int.tryParse('$v') ?? 0);

DateTime? _date(dynamic v) {
  if (v == null || '$v'.isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

/// 안건 한 줄 (시간이 없으면 time은 빈 문자열)
class EventAgendaItem {
  final String time;
  final String title;

  const EventAgendaItem({required this.time, required this.title});

  static final RegExp _timePrefix = RegExp(
      r'^\s*(\d{1,2}:\d{2}(?:\s*[~\-–]\s*\d{1,2}:\d{2})?)\s*[·:\-]?\s*(.*)$');

  /// 서버 agenda는 문자열(줄바꿈 구분) 또는 목록일 수 있어서 둘 다 처리해요.
  /// "14:00~14:20 팀 운영 소식 공유" 처럼 앞에 시간이 있으면 나눠요.
  static List<EventAgendaItem> parse(dynamic raw) {
    final lines = <String>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final time = _str(e['time']);
          final title = _str(e['title'] ?? e['name']);
          if (title.isNotEmpty) {
            lines.add(time.isEmpty ? title : '$time $title');
          }
        } else if (_str(e).trim().isNotEmpty) {
          lines.add(_str(e));
        }
      }
    } else {
      lines.addAll(_str(raw)
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty));
    }

    return lines.map((line) {
      final m = _timePrefix.firstMatch(line);
      if (m != null && (m.group(2) ?? '').isNotEmpty) {
        return EventAgendaItem(
            time: m.group(1)!.replaceAll(' ', ''), title: m.group(2)!);
      }
      return EventAgendaItem(time: '', title: line.replaceFirst(RegExp(r'^[-·•]\s*'), ''));
    }).toList();
  }
}

/// 변경 이력 한 줄 { action, who, at, changes }
/// changes 는 일정 수정 때 서버가 남기는 { 필드: { before, after } } 예요.
class EventHistoryEntry {
  final String action; // created, updated, ...
  final String who;
  final DateTime? at;
  final String note;
  final List<String> changedFields;

  const EventHistoryEntry({
    required this.action,
    required this.who,
    required this.at,
    required this.note,
    this.changedFields = const [],
  });

  static const Map<String, String> _fieldLabels = {
    'title': '제목',
    'date': '날짜',
    'start': '시작',
    'end': '끝',
    'place': '장소',
    'host': '주최',
    'agenda': '안건',
    'audience': '참석 대상',
    'scope': '구분',
    'rsvp': '참석 확인',
    'relatedDocs': '관련 문서',
  };

  static String _short(dynamic v) {
    if (v == null || '$v'.isEmpty) return '없음';
    if (v is bool) return v ? '받음' : '안 받음';
    if (v is List) return v.isEmpty ? '없음' : '${v.length}개';
    final text = '$v'.replaceAll('\n', ' ');
    return text.length > 18 ? '${text.substring(0, 18)}…' : text;
  }

  factory EventHistoryEntry.fromJson(Map<String, dynamic> json) {
    final fields = <String>[];
    final lines = <String>[];
    final changes = json['changes'];
    if (changes is Map) {
      changes.forEach((key, value) {
        final label = _fieldLabels['$key'];
        if (label == null) return; // time, target 같은 중복 필드는 건너뛰어요
        fields.add(label);
        if (value is Map) {
          lines.add('$label ${_short(value['before'])} → ${_short(value['after'])}');
        } else {
          lines.add('$label 변경');
        }
      });
    }

    final note = _str(json['note'] ?? json['summary'] ?? json['detail']);
    return EventHistoryEntry(
      action: _str(json['action']),
      who: _str(json['who']),
      at: _date(json['at']),
      note: [if (note.isNotEmpty) note, ...lines].join('\n'),
      changedFields: fields,
    );
  }

  /// 화면에 보여줄 이름 (created → 일정 등록, 장소만 바뀌면 장소 변경)
  String get label {
    switch (action) {
      case 'created':
        return '일정 등록';
      case 'updated':
        return changedFields.length == 1 ? '${changedFields.first} 변경' : '일정 수정';
      case 'canceled':
      case 'cancelled':
        return '일정 취소';
      case 'rescheduled':
        return '시간 변경';
      default:
        return action.isEmpty ? '변경' : action;
    }
  }
}

/// GET /events/{id}
class EventDetail {
  final String id;
  final String title;
  final String description;
  final DateTime? date;
  final String start; // HH:mm
  final String end; // HH:mm
  final String place;
  final String host;
  final String audience;
  final String scope; // 팀, 프로젝트, 개인
  final List<EventAgendaItem> agenda;
  final List<String> relatedDocs;
  final List<EventHistoryEntry> history;
  final bool rsvpEnabled; // 참석 응답을 받는 일정인지
  final String? myRsvp; // 참석, 불참, 미정 (응답 안 했으면 null)
  final DateTime? respondedAt;
  final int rsvpCount; // 참석 응답 수
  final Map<String, dynamic> raw;

  const EventDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.start,
    required this.end,
    required this.place,
    required this.host,
    required this.audience,
    required this.scope,
    required this.agenda,
    required this.relatedDocs,
    required this.history,
    required this.rsvpEnabled,
    required this.myRsvp,
    required this.respondedAt,
    required this.rsvpCount,
    required this.raw,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final docs = json['relatedDocs'];
    final history = json['history'];
    final rsvp = _str(json['myRsvp']);

    return EventDetail(
      id: _str(json['id']),
      title: _str(json['title']),
      description: _str(json['description'] ?? json['desc'] ?? json['memo']),
      date: DateTime.tryParse(_str(json['date'])),
      start: _str(json['start'] ?? json['time']),
      end: _str(json['end']),
      place: _str(json['place']),
      host: _str(json['host']),
      audience: _str(json['audience'] ?? json['target']),
      scope: _str(json['scope'] ?? json['kind']),
      agenda: EventAgendaItem.parse(json['agenda']),
      relatedDocs: docs is List
          ? docs
          .map((e) => e is Map ? _str(e['title'] ?? e['name'] ?? e['slug']) : _str(e))
          .where((e) => e.isNotEmpty)
          .toList()
          : const [],
      history: history is List
          ? history
          .whereType<Map>()
          .map((e) => EventHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
      rsvpEnabled: json['rsvp'] == true,
      myRsvp: rsvp.isEmpty ? null : rsvp,
      respondedAt: _date(json['respondedAt']),
      rsvpCount: _int(json['rsvpCount']),
      raw: json,
    );
  }

  /// 시작 시각이 없으면 하루 종일 일정이에요
  bool get isAllDay => start.isEmpty;

  /// "19:00 – 20:00" / "19:00" / "하루 종일"
  String get timeText {
    if (start.isEmpty) return '하루 종일';
    return end.isEmpty ? start : '$start – $end';
  }

  /// 생성 이후 한 번이라도 수정됐는지
  bool get wasChanged => history.any((h) => h.action != 'created');

  /// 같은 날짜인지 (캘린더 칸 비교용)
  bool isOn(DateTime day) =>
      date != null &&
          date!.year == day.year &&
          date!.month == day.month &&
          date!.day == day.day;

  EventDetail withRsvp(String rsvp, DateTime? respondedAt) => EventDetail(
    id: id,
    title: title,
    description: description,
    date: date,
    start: start,
    end: end,
    place: place,
    host: host,
    audience: audience,
    scope: scope,
    agenda: agenda,
    relatedDocs: relatedDocs,
    history: history,
    rsvpEnabled: rsvpEnabled,
    myRsvp: rsvp,
    respondedAt: respondedAt,
    rsvpCount: rsvpCount,
    raw: raw,
  );
}

/// GET / PATCH /events/{id}/reminders
class EventReminders {
  final String eventId;
  final bool oneDayBefore;
  final bool oneHourBefore;
  final bool tenMinutesBefore;

  const EventReminders({
    required this.eventId,
    required this.oneDayBefore,
    required this.oneHourBefore,
    required this.tenMinutesBefore,
  });

  factory EventReminders.fromJson(Map<String, dynamic> json) => EventReminders(
    eventId: _str(json['eventId']),
    oneDayBefore: json['oneDayBefore'] == true,
    oneHourBefore: json['oneHourBefore'] == true,
    tenMinutesBefore: json['tenMinutesBefore'] == true,
  );

  /// "하루 전 · 1시간 전" / 없으면 "받지 않음"
  String get summary {
    final parts = [
      if (oneDayBefore) '하루 전',
      if (oneHourBefore) '1시간 전',
      if (tenMinutesBefore) '10분 전',
    ];
    return parts.isEmpty ? '받지 않음' : parts.join(' · ');
  }

  EventReminders copyWith({
    bool? oneDayBefore,
    bool? oneHourBefore,
    bool? tenMinutesBefore,
  }) =>
      EventReminders(
        eventId: eventId,
        oneDayBefore: oneDayBefore ?? this.oneDayBefore,
        oneHourBefore: oneHourBefore ?? this.oneHourBefore,
        tenMinutesBefore: tenMinutesBefore ?? this.tenMinutesBefore,
      );
}