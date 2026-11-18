import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/notification_settings.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class NotificationCategorySettingScreen extends StatefulWidget {
  const NotificationCategorySettingScreen({super.key});

  @override
  State<NotificationCategorySettingScreen> createState() => _NotificationCategorySettingScreenState();
}

class _NotificationCategorySettingScreenState extends State<NotificationCategorySettingScreen> {
  NotificationSettings? _settings; // GET /me/notification-settings
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
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

  /// 스위치를 바꾸면 화면을 먼저 바꾸고 서버에 저장해요. 실패하면 원래대로 돌려요.
  Future<void> _save(
      NotificationSettings optimistic, {
        Map<String, bool>? kinds,
        bool? dnd,
      }) async {
    final before = _settings;
    if (before == null) return;

    setState(() => _settings = optimistic);
    try {
      final saved = await HomeRepository.instance.updateNotificationSettings(
        current: optimistic,
        kinds: kinds,
        dnd: dnd,
      );
      if (!mounted) return;
      setState(() => _settings = saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _settings = before);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  void _toggleKind(String kind, bool value) {
    final current = _settings;
    if (current == null) return;
    _save(current.withKind(kind, value), kinds: {kind: value});
  }

  void _toggleDnd(bool value) {
    final current = _settings;
    if (current == null) return;
    _save(current.copyWith(dnd: value), dnd: value);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
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
                  ),
                  const Text(
                    '알림 설정',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 메인 스크롤 콘텐츠
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF6B7280);
    const textGrey = Color(0xFF8E8E93);

    final settings = _settings;

    if (_isLoading && settings == null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: const [SkeletonList(count: 2)],
      );
    }

    if (settings == null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          ErrorStateView(
            title: '알림 설정을 불러오지 못했어요',
            message: _errorMessage,
            onRetry: _load,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 12),

        const Text(
          '어떤 알림을 받을까요?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Native 앱은 알림 → 확인 → 처리 흐름을 위해 만들어졌어요.',
          style: TextStyle(
            fontSize: 13,
            color: textSub,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildSettingTile(
                iconBgColor: const Color(0xFFEBF3FF),
                iconColor: primaryBlue,
                iconData: Icons.assignment_turned_in_outlined,
                title: '개인 업무',
                subtitle: '결재 승인 · 반려, 새 결재 요청, 프로젝트 일정 변경',
                value: settings.isOn(NotificationSettings.kindMyTask),
                onChanged: (val) =>
                    _toggleKind(NotificationSettings.kindMyTask, val),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              _buildSettingTile(
                iconBgColor: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF97316),
                iconData: Icons.account_balance_wallet_outlined,
                title: 'NativeLab 재정',
                subtitle: '수주 · 입금이 생기면 알려요 (출금 · 지출 제외)',
                value: settings.isOn(NotificationSettings.kindFinance),
                onChanged: (val) =>
                    _toggleKind(NotificationSettings.kindFinance, val),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              _buildSettingTile(
                iconBgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                iconData: Icons.menu_book_rounded,
                title: '제도 · 규칙 변경',
                subtitle: '규칙이 바뀌면 변경 내역과 함께',
                value: settings.isOn(NotificationSettings.kindRule),
                onChanged: (val) =>
                    _toggleKind(NotificationSettings.kindRule, val),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              _buildSettingTile(
                iconBgColor: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFFA855F7),
                iconData: Icons.calendar_today_rounded,
                title: 'Native 일정',
                subtitle: '활동일 · 회의 일정과 변경',
                value: settings.isOn(NotificationSettings.kindEvent),
                onChanged: (val) =>
                    _toggleKind(NotificationSettings.kindEvent, val),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              _buildSettingTile(
                iconBgColor: const Color(0xFFF3F4F6),
                iconColor: textSub,
                iconData: Icons.campaign_outlined,
                title: '전체 공지',
                subtitle: 'Inspace · Native 전체 공지',
                value: settings.isOn(NotificationSettings.kindNotice),
                onChanged: (val) =>
                    _toggleKind(NotificationSettings.kindNotice, val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dark_mode_outlined,
                  color: primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '방해 금지 시간',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${settings.dndFrom} – ${settings.dndTo} 에는 소리 없이 받아요',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: settings.dnd,
                activeColor: primaryBlue,
                onChanged: _toggleDnd,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingTile({
    required Color iconBgColor,
    required Color iconColor,
    required IconData iconData,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: value,
            activeColor: primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}