// GET / PATCH /me/notification-settings 응답 모델
// 서버(account.py) 기본값: push false, 모든 분류 켜짐(게시판만 꺼짐), 방해 금지 23:00~08:00 매일

class NotificationSettings {
  /// 서버가 쓰는 알림 분류 이름 (kinds 의 키)
  static const String kindMyTask = '내 업무';
  static const String kindFinance = '재정';
  static const String kindEvent = '일정';
  static const String kindNotice = '공지';
  static const String kindRule = '규칙 (제도 변경)';
  static const String kindBoard = '게시판';

  static const List<String> allDays = ['월', '화', '수', '목', '금', '토', '일'];

  final bool push; // 푸시 받기
  final Map<String, bool> kinds; // 분류별 켜짐/꺼짐
  final bool dnd; // 방해 금지
  final String dndFrom; // "23:00"
  final String dndTo; // "08:00"
  final List<String> dndDays; // ["월", "화", ...]

  const NotificationSettings({
    required this.push,
    required this.kinds,
    required this.dnd,
    required this.dndFrom,
    required this.dndTo,
    required this.dndDays,
  });

  static const NotificationSettings defaults = NotificationSettings(
    push: false,
    kinds: {
      kindMyTask: true,
      kindFinance: true,
      kindEvent: true,
      kindNotice: true,
      kindRule: true,
      kindBoard: false,
    },
    dnd: true,
    dndFrom: '23:00',
    dndTo: '08:00',
    dndDays: allDays,
  );

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      defaults.mergedWith(json);

  /// 서버 응답(일부 필드만 있을 수 있음)을 지금 값 위에 덮어써요.
  /// PATCH 응답은 저장된 값만 돌려줄 때가 있어서 이렇게 합쳐서 써요.
  NotificationSettings mergedWith(Map<String, dynamic> json) {
    // dnd가 { enabled, from, to, days } 객체로 올 때도 처리 (서버가 둘 다 지원)
    final dndRaw = json['dnd'];
    final dndMap = dndRaw is Map ? Map<String, dynamic>.from(dndRaw) : null;

    final mergedKinds = Map<String, bool>.from(kinds);
    final kindsRaw = json['kinds'];
    if (kindsRaw is Map) {
      kindsRaw.forEach((k, v) => mergedKinds['$k'] = v == true);
    }

    List<String>? days;
    final daysRaw = json['dndDays'] ?? dndMap?['days'];
    if (daysRaw is List) days = daysRaw.map((e) => '$e').toList();

    return NotificationSettings(
      push: json['push'] is bool ? json['push'] as bool : push,
      kinds: mergedKinds,
      dnd: dndRaw is bool
          ? dndRaw
          : (dndMap?['enabled'] is bool ? dndMap!['enabled'] as bool : dnd),
      dndFrom: (json['dndFrom'] ?? dndMap?['from'] ?? dndFrom).toString(),
      dndTo: (json['dndTo'] ?? dndMap?['to'] ?? dndTo).toString(),
      dndDays: days ?? dndDays,
    );
  }

  /// 분류가 켜져 있는지 (설정에 없으면 서버처럼 켜짐으로 봐요)
  bool isOn(String kind) => kinds[kind] ?? true;

  /// 켜져 있는 분류 개수 (게시판 제외, 화면에 보이는 5개 기준)
  int get enabledCount => [
    kindMyTask,
    kindFinance,
    kindEvent,
    kindNotice,
    kindRule,
  ].where(isOn).length;

  NotificationSettings copyWith({
    bool? push,
    Map<String, bool>? kinds,
    bool? dnd,
    String? dndFrom,
    String? dndTo,
    List<String>? dndDays,
  }) {
    return NotificationSettings(
      push: push ?? this.push,
      kinds: kinds ?? this.kinds,
      dnd: dnd ?? this.dnd,
      dndFrom: dndFrom ?? this.dndFrom,
      dndTo: dndTo ?? this.dndTo,
      dndDays: dndDays ?? this.dndDays,
    );
  }

  NotificationSettings withKind(String kind, bool value) =>
      copyWith(kinds: {...kinds, kind: value});
}