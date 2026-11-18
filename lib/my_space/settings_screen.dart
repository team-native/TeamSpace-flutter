import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/auth_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import '../app/router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _isSavingTheme = false;
  String? _roleLabel; // 재정 정보 권한 배지 (관리자 / 재정 담당 / 리더 / 구성원)

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadRole();
  }

  /// GET /me/settings
  Future<void> _loadSettings() async {
    try {
      final settings = await MySpaceRepository.instance.getSettings();
      if (!mounted) return;
      setState(() => _isDarkMode = settings.isDark);
    } on ApiException {
      // 못 불러오면 기본값(시스템)으로 둬요
    }
  }

  /// GET /me 의 roles → 재정 정보 권한 배지
  Future<void> _loadRole() async {
    try {
      final me = await HomeRepository.instance.getMe();
      if (!mounted) return;
      final roles = me.roles.map((r) => r.trim().toLowerCase()).toSet();
      setState(() {
        if (roles.contains('admin')) {
          _roleLabel = '관리자';
        } else if (roles.contains('fa')) {
          _roleLabel = '재정 담당';
        } else if (roles.contains('leader')) {
          _roleLabel = '리더';
        } else {
          _roleLabel = '구성원';
        }
      });
    } on ApiException {
      // 못 불러오면 배지를 숨겨요
    }
  }

  /// PATCH /me/settings { theme: 다크 | 시스템 }
  Future<void> _toggleDarkMode(bool value) async {
    if (_isSavingTheme) return;
    final before = _isDarkMode;
    setState(() {
      _isDarkMode = value;
      _isSavingTheme = true;
    });
    try {
      final saved = await MySpaceRepository.instance.updateTheme(value ? '다크' : '시스템');
      if (!mounted) return;
      setState(() => _isDarkMode = saved.isDark);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDarkMode = before);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), duration: const Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _isSavingTheme = false);
    }
  }

  /// 저장된 토큰을 지우고 로그인 화면으로 가요
  /// (서버에는 로그아웃 API가 없어서 기기에서만 지워요)
  Future<void> _logout() async {
    await AuthRepository.instance.logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  // 💡 07-17 로그아웃 확인 모달 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 상단 아이콘 (연한 파란색 원형 배경 + 파란색 로그아웃 아이콘)
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF3182F6),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. 타이틀 & 서브 설명
                const Text(
                  '로그아웃할까요?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '다시 로그인하기 전까지 새 알림을 받을 수 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 3. 메인 로그아웃 버튼 (파란색)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3182F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 4. 취소 버튼 (회색)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (뒤로가기, 타이틀)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
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
                        '설정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 섹션 1: 화면
                    _buildSectionTitle('화면'),
                    const SizedBox(height: 8),
                    _buildCardContainer(
                      child: Row(
                        children: [
                          _buildIconBox(
                            icon: Icons.nightlight_round,
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '다크 모드',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isDarkMode ? '어두운 화면으로 저장했어요' : '시스템 설정을 따라가요',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isDarkMode,
                            onChanged: _isSavingTheme ? null : _toggleDarkMode,
                            activeThumbColor: const Color(0xFF3182F6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 2: 알림
                    _buildSectionTitle('알림'),
                    const SizedBox(height: 8),
                    _buildCardContainer(
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.notificationCategorySetting),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            _buildIconBox(
                              icon: Icons.notifications_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '알림 설정',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '종류별로 받을 알림을 골라요',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFCBD5E1),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 3: 계정
                    _buildSectionTitle('계정'),
                    const SizedBox(height: 8),
                    _buildCardContainer(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => context.push(AppRoutes.changePassword),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                _buildIconBox(
                                  icon: Icons.lock_rounded,
                                  color: const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    '비밀번호 변경',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          InkWell(
                            onTap: () => context.push(AppRoutes.permissionInfo),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                _buildIconBox(
                                  icon: Icons.shield_rounded,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    '재정 정보 권한',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                if (_roleLabel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _roleLabel!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3182F6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 섹션 4: 정보
                    _buildSectionTitle('정보'),
                    const SizedBox(height: 8),
                    _buildCardContainer(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => context.push(AppRoutes.noticeList),
                            borderRadius: BorderRadius.circular(12),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '공지 · 운영 정책',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '버전',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                              ),
                              Text(
                                '1.0.0',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 💡 섹션 5: 로그아웃 버튼 (클릭 시 모달 다이얼로그 노출)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF5F5),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '로그아웃',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconBox({required IconData icon, required Color color}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}