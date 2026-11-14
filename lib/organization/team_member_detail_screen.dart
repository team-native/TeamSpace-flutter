import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/member_models.dart';
import 'package:teamspace/data/repositories/member_repository.dart';
import 'package:teamspace/shared/widgets/default_profile_avatar.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 팀원 상세 화면.
/// - memberData에 id가 있으면 GET /users/{id} 로 상세를 불러와요.
/// - memberData가 없으면(마이스페이스 등에서 진입) GET /users/me 로 내 프로필을 보여줘요.
/// - 목록에서 넘겨준 name / role / department는 로딩 중에도 바로 보여줘요.
class TeamMemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? memberData;

  const TeamMemberDetailScreen({
    super.key,
    this.memberData,
  });

  @override
  State<TeamMemberDetailScreen> createState() => _TeamMemberDetailScreenState();
}

class _TeamMemberDetailScreenState extends State<TeamMemberDetailScreen> {
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _primaryBlue = Color(0xFF3182F6);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textSub = Color(0xFF64748B);

  late String _name;
  late String _role;
  late String _department;
  String _email = '';
  List<ProjectSummary> _projects = [];
  List<String> _skills = [];

  bool _isLoading = true;
  String? _errorMessage;

  int? get _memberId {
    final id = widget.memberData?['id'];
    if (id is int) return id;
    return int.tryParse('${id ?? ''}');
  }

  @override
  void initState() {
    super.initState();
    final data = widget.memberData;
    _name = data?['name']?.toString() ?? '';
    _role = data?['role']?.toString() ?? '';
    _department = data?['department']?.toString() ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = _memberId;
      final detail = id != null
          ? await MemberRepository.instance.getMember(id)
          : await MemberRepository.instance.getMe();
      if (!mounted) return;

      setState(() {
        if (detail.name.isNotEmpty) _name = detail.name;
        if (detail.department.isNotEmpty) _department = detail.department;
        if (_role.isEmpty && detail.roles.isNotEmpty) {
          _role = detail.roles.join(' · ');
        }
        _email = detail.email;
        _projects = detail.projects;
        _skills = detail.skills;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '정보를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  // 클립보드 복사
  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _showSnack(message);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ───────────── 공통 위젯 ─────────────

  Widget _buildCircleButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
        child: Icon(icon, color: _textDark, size: iconSize),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _buildDivider({double vertical = 12}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isEmail = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _textSub)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            softWrap: true,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isEmail ? _primaryBlue : _textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ───────────── 화면 ─────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.chevron_left_rounded,
                    iconSize: 24,
                    onTap: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    ..._buildBody(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const DefaultProfileAvatar(size: 100),
        ),
        const SizedBox(height: 16),
        Text(
          _name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_role.isNotEmpty)
              _buildChip(
                _role,
                bg: const Color(0xFFEFF6FF),
                fg: _primaryBlue,
              ),
            if (_department.isNotEmpty)
              _buildChip(
                _department,
                bg: const Color(0xFFF1F5F9),
                fg: _textSub,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_email.isEmpty) {
                  _showSnack('등록된 이메일이 없습니다.');
                  return;
                }
                _copyText(_email, '이메일 주소가 복사되었습니다.');
              },
              icon: const Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                '메일 보내기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack('메시지 기능은 추후 연결 예정입니다.'),
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: _textDark,
              ),
              label: const Text(
                '메시지',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 로딩 / 에러 / 실제 내용
  List<Widget> _buildBody() {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        ErrorStateView(
          title: '정보를 불러오지 못했어요',
          message: _errorMessage,
          onRetry: _load,
        ),
      ];
    }

    // 값이 있는 항목만 보여줘요
    final infoRows = <Widget>[
      if (_department.isNotEmpty) _buildInfoRow('부서', _department),
      if (_role.isNotEmpty) _buildInfoRow('역할', _role),
      if (_email.isNotEmpty) _buildInfoRow('이메일', _email, isEmail: true),
    ];

    return [
      if (infoRows.isNotEmpty)
        _buildCard(
          child: Column(
            children: [
              for (int i = 0; i < infoRows.length; i++) ...[
                infoRows[i],
                if (i != infoRows.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
      if (_projects.isNotEmpty) ...[
        const SizedBox(height: 24),
        _buildSectionTitle('참여 중인 프로젝트'),
        const SizedBox(height: 12),
        _buildCard(
          child: Column(
            children: List.generate(_projects.length, (index) {
              final project = _projects[index];
              final isLast = index == _projects.length - 1;
              final initial =
              project.name.isEmpty ? '' : project.name.substring(0, 1);

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) _buildDivider(vertical: 14),
                ],
              );
            }),
          ),
        ),
      ],
      if (_skills.isNotEmpty) ...[
        const SizedBox(height: 24),
        _buildSectionTitle('기술 스택'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.02),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '# $skill',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _textSub,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ];
  }
}