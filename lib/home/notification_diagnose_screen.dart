import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/core/notification/notification_permission.dart';
import 'package:teamspace/data/models/notification_settings.dart';
import 'package:teamspace/data/repositories/home_repository.dart';

class NotificationDiagnoseScreen extends StatefulWidget {
  const NotificationDiagnoseScreen({super.key});

  @override
  State<NotificationDiagnoseScreen> createState() =>
      _NotificationDiagnoseScreenState();
}

class _NotificationDiagnoseScreenState extends State<NotificationDiagnoseScreen>
    with WidgetsBindingObserver {
  // 앱 쪽 알림 설정 (GET /me/notification-settings)
  NotificationSettings? _settings;

  // 기기(OS) 알림 권한 (null = 확인 중)
  DeviceNotificationStatus? _deviceStatus;
  bool _isLoading = true;
  String? _errorMessage;

  // 화면에 보이는 분류 이름 (서버 키 → 화면 이름)
  static const Map<String, String> _kindLabels = {
    NotificationSettings.kindMyTask: '개인 업무',
    NotificationSettings.kindFinance: '재정',
    NotificationSettings.kindRule: '제도 · 규칙',
    NotificationSettings.kindEvent: '일정',
    NotificationSettings.kindNotice: '전체 공지',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDevice();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 기기 설정에서 권한을 바꾸고 앱으로 돌아오면 다시 확인해요
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkDevice();
  }

  Future<void> _checkDevice() async {
    final status = await NotificationPermission.status();
    if (!mounted) return;
    setState(() => _deviceStatus = status);
  }

  /// [기기 설정 열기]
  /// 아직 거절 전이면 권한 창을 먼저 띄우고, 이미 거절했으면 기기 설정 화면을 열어요.
  Future<void> _openDeviceSettings() async {
    if (_deviceStatus == DeviceNotificationStatus.denied) {
      final status = await NotificationPermission.request();
      if (!mounted) return;
      setState(() => _deviceStatus = status);
      if (status == DeviceNotificationStatus.granted) return;
    }

    final opened = await NotificationPermission.openSettings();
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이 기기에서는 설정 화면을 열 수 없어요. 기기의 설정 → 알림 → Native에서 직접 켜주세요.'),
      ),
    );
  }

  bool get _deviceOn => _deviceStatus == DeviceNotificationStatus.granted;

  String get _deviceText {
    switch (_deviceStatus) {
      case null:
        return '확인 중';
      case DeviceNotificationStatus.granted:
        return '켜짐';
      case DeviceNotificationStatus.denied:
      case DeviceNotificationStatus.permanentlyDenied:
        return '꺼짐 · 설정 필요';
      case DeviceNotificationStatus.unsupported:
        return '이 기기에서는 확인 불가';
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final settings = await HomeRepository.instance.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  /// 알림 종류 설정 화면에 다녀오면 바뀐 값을 다시 받아요
  Future<void> _openCategorySetting() async {
    await context.push(AppRoutes.notificationCategorySetting);
    if (mounted) _load();
  }

  String get _pushText {
    final s = _settings;
    if (s == null) return _isLoading ? '확인 중' : '확인 실패';
    return s.push ? '켜짐' : '꺼짐 · 알림 허용 필요';
  }

  String get _dndText {
    final s = _settings;
    if (s == null) return _isLoading ? '확인 중' : '확인 실패';
    return s.dnd ? '${s.dndFrom} – ${s.dndTo} 조용히 받기' : '꺼짐';
  }

  String get _categoryText {
    final s = _settings;
    if (s == null) return _isLoading ? '확인 중' : '확인 실패';
    final onLabels = _kindLabels.entries
        .where((e) => s.isOn(e.key))
        .map((e) => e.value)
        .toList();
    if (onLabels.isEmpty) return '모두 꺼짐';
    if (onLabels.length == 1) return '${onLabels.first} 수신 중';
    return '${onLabels.first} 등 ${onLabels.length}개 수신 중';
  }

  String get _noticeText {
    final s = _settings;
    if (s == null) return _isLoading ? '확인 중' : '확인 실패';
    return s.isOn(NotificationSettings.kindNotice) ? '수신 중' : '앱 설정에서 꺼짐';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);
    const cardBorderColor = Color(0x1A000000);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 24,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '알림 수신 진단',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(18),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: textGrey,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 메인 스크롤 영역
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  const SizedBox(height: 8),

                  _buildHeader(textDark),

                  const SizedBox(height: 20),

                  // [카드 1] 수신 상태 확인
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '수신 상태 확인',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(NotificationPermission.label, _deviceText),
                        const Divider(height: 24, color: Color(0xFFF3F4F6)),
                        _buildStatusRow('앱 푸시', _pushText),
                        const Divider(height: 24, color: Color(0xFFF3F4F6)),
                        _buildStatusRow('방해 금지', _dndText),
                        const Divider(height: 24, color: Color(0xFFF3F4F6)),
                        _buildStatusRow('앱 카테고리', _categoryText),
                        const Divider(height: 24, color: Color(0xFFF3F4F6)),
                        _buildStatusRow('전체 공지', _noticeText),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _load,
                            child: Text(
                              '설정을 불러오지 못했어요. 눌러서 다시 시도해 주세요.\n$_errorMessage',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 버튼 1: 기기 설정 열기
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _openDeviceSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '기기 설정 열기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 안내 콜아웃
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: lightBlueBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: primaryBlue,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '설정 → 알림 → Native에서 \'알림 허용\'을 켜주세요. 이 화면에서는 시스템 권한을 바꾸지 못해요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSub,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // [카드 2] 그래도 소식이 오지 않나요?
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '그래도 소식이 오지 않나요?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCheckRow(
                          title: '권한과 표시 위치 확인',
                          subtitle: '잠금화면 · 알림센터 · 배너 허용 여부 확인',
                          // 기기 권한이 꺼져 있으면 이 항목을 강조해요
                          isActive: !_deviceOn,
                        ),
                        const SizedBox(height: 14),
                        _buildCheckRow(
                          title: '방해금지 · 집중 모드 확인',
                          subtitle: 'Native가 허용된 앱인지 확인해요.',
                          isActive: false,
                        ),
                        const SizedBox(height: 14),
                        _buildCheckRow(
                          title: '앱 카테고리 확인',
                          subtitle: '알림 종류 설정에서 필요한 분류를 켜주세요.',
                          // 꺼진 분류가 있으면 이 항목을 강조해요
                          isActive: (_settings?.enabledCount ?? 5) < 5,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 버튼 2: 앱으로 돌아와 다시 확인
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '앱으로 돌아와 다시 확인',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 버튼 3: 앱 안 알림센터 보기 -> NotificationCategorySettingScreen 이동
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _openCategorySetting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '앱 안 알림센터 보기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 맨 위 상태 표시 (기기 권한에 따라 바뀌어요)
  Widget _buildHeader(Color textDark) {
    late final IconData icon;
    late final Color color;
    late final Color bg;
    late final String badge;
    late final String title;
    late final String description;

    switch (_deviceStatus) {
      case DeviceNotificationStatus.granted:
        icon = Icons.notifications_active_outlined;
        color = const Color(0xFF10B981);
        bg = const Color(0xFFECFDF5);
        badge = '기기 알림 켜짐';
        title = '기기 알림이\n켜져 있어요.';
        description = _settings?.push == false
            ? '기기 알림은 켜져 있지만 앱 푸시가 꺼져 있어요. 알림 시작하기에서 알림을 허용해 주세요.'
            : '그래도 소식이 오지 않으면 아래 항목을 차례로 확인해 주세요.';
        break;
      case DeviceNotificationStatus.unsupported:
        icon = Icons.help_outline_rounded;
        color = const Color(0xFF6B7280);
        bg = const Color(0xFFF3F4F6);
        badge = '확인 불가';
        title = '이 기기에서는\n알림 권한을 확인할 수 없어요.';
        description = '휴대폰(Android · iOS)에서 열면 기기 알림 상태를 확인할 수 있어요. 앱 안 알림센터에는 계속 쌓이고 있어요.';
        break;
      case null:
        icon = Icons.notifications_none_rounded;
        color = const Color(0xFF6B7280);
        bg = const Color(0xFFF3F4F6);
        badge = '확인 중';
        title = '알림 상태를\n확인하고 있어요.';
        description = '잠시만 기다려 주세요.';
        break;
      case DeviceNotificationStatus.denied:
      case DeviceNotificationStatus.permanentlyDenied:
        icon = Icons.notifications_off_outlined;
        color = const Color(0xFFEF4444);
        bg = const Color(0xFFFEF2F2);
        badge = '기기 알림 꺼짐';
        title = '기기에서 알림이\n차단되어 있어요.';
        description = '새 요청이 와도 잠금화면에 표시되지 않아요. 앱 안 알림센터에는 계속 쌓이고 있어요.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            height: 1.3,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8E93),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckRow({
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    const primaryBlue = Color(0xFF2F80ED);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? primaryBlue : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}