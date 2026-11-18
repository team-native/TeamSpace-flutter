import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/models/my_space_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import '../app/router.dart';

class MyPermissionAccessScreen extends StatefulWidget {
  const MyPermissionAccessScreen({super.key});

  @override
  State<MyPermissionAccessScreen> createState() => _MyPermissionAccessScreenState();
}

class _MyPermissionAccessScreenState extends State<MyPermissionAccessScreen> {
  MyProfile? _me; // GET /me (roles 로 역할을 판단해요)
  String? _errorMessage;

  /// 모든 구성원이 할 수 있는 일
  static const List<String> _baseFeatures = [
    '내 알림 · 프로필 · 일정 확인',
    '문서 작성 · 제출, 내 문서 결과 확인',
    '프로젝트 탐색 · 참여 신청',
    '게시글 · 댓글 실명/익명 선택 작성',
    '공식 문의 제출 · 내 문의 확인',
    '공개 규칙 · 재정 요약 열람',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errorMessage = null);
    try {
      final me = await HomeRepository.instance.getMe();
      if (!mounted) return;
      setState(() => _me = me);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    }
  }

  /// 내 역할에 따라 더 할 수 있는 일
  List<String> _extraFeatures(Set<String> roles) {
    return [
      if (roles.contains('admin')) ...[
        '일정 등록 · 삭제, 공지 게시',
        '가입 요청 승인 · 계정 관리',
      ],
      if (roles.contains('fa') || roles.contains('admin')) '재정 세부 내역 열람 · 예산 검토',
      if (roles.contains('leader') || roles.contains('lead')) '지정된 결재 처리 · 조직 운영 범위 확인',
      if (roles.contains('pm')) '담당 프로젝트 편집 · 지원자 검토',
    ];
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final me = _me;
    final role = me == null ? null : RoleInfo.of(me.roles);
    final roleSet = me == null ? <String>{} : me.roles.map((r) => r.trim().toLowerCase()).toSet();
    final affiliation = me == null
        ? '-'
        : [
      if (me.dept.isNotEmpty) me.dept,
      if (me.major.isNotEmpty) me.major,
    ].join(' · ');
    final features = [..._baseFeatures, ..._extraFeatures(roleSet)];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (뒤로가기, 타이틀, 더보기 버튼)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.workspace);
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
                  const Text(
                    '내 권한과 접근 범위',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),
            ),

            // 2. 본문 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 서브 헤더 태그
                    const Text(
                      '12 · 역할과 권한 안내',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 메인 타이틀
                    const Text(
                      '내가 할 수 있는 일을 확인해요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 보라색 태그
                    const Text(
                      '권한 정책 예시 · 운영 확정 필요',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 파란색 안내 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '역할별 범위는 화면 설계를 위한 예시이며 사용자에게 확정된 운영정책이 아니에요. 실제 권한은 운영자 검토 후 부여돼요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 카드 1: 현재 내 역할
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '현재 내 역할',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  me == null ? '확인 중' : '${role!.label} · ${me.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('소속', style: TextStyle(fontSize: 13, color: textSub)),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Text(
                                  affiliation,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('추가 운영 권한', style: TextStyle(fontSize: 13, color: textSub)),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Text(
                                  role == null ? '-' : (role.hasExtra ? role.description : '없음'),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _load,
                              child: Text(
                                '$_errorMessage 눌러서 다시 시도',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Text(
                            '여기서는 역할을 직접 변경할 수 없어요.',
                            style: TextStyle(fontSize: 11, color: textLightGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카드 2: 허용되는 기능
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '허용되는 기능',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (int i = 0; i < features.length; i++)
                            _buildCheckItem(
                              features[i],
                              isExtra: i >= _baseFeatures.length,
                              isLast: i == features.length - 1,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카드 3: 역할별 기능 범위 예시
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '역할별 기능 범위 예시',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildRoleScopeRow('구성원', '기본 업무와 본인 활동 확인'),
                          _buildRoleScopeRow('PM', '담당 프로젝트 편집 · 지원자 검토 · 일정 관리'),
                          _buildRoleScopeRow('NativeOps', '배정된 문의 처리 · 조직 운영 · 공지 게시'),
                          _buildRoleScopeRow('FA', '허용된 재정 세부 내역 · 예산 검토'),
                          _buildRoleScopeRow('Leader', '지정된 결재 · 조직 운영 범위 확인', isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카드 4: 제한되는 재정 항목
                    _buildCardContainer(
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '제한되는 재정 항목',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '계좌 정보 · 계약 원문 · 개별 배분금',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textSub,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '소속이나 직책만으로 자동 공개되지 않아요. 승인된 업무 범위에 따라 세부 접근 권한이 달라질 수 있어요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카드 5: 권한이 더 필요하다면
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '권한이 더 필요하다면',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStepItem(
                            step: 1,
                            title: '업무 목적과 필요한 범위 정리',
                            desc: '프로젝트 · 기간 · 자료 범위를 함께 적어요.',
                            isActive: true,
                          ),
                          _buildStepItem(
                            step: 2,
                            title: 'NativeOps에 권한 요청',
                            desc: '해당 부서와 운영자가 적정 범위를 검토해요.',
                            isActive: false,
                          ),
                          _buildStepItem(
                            step: 3,
                            title: '승인 결과 확인',
                            desc: '검토 후 계정에 적용된 범위를 다시 확인해요.',
                            isActive: false,
                            isLast: true,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              // 공식 문의 작성 화면으로 가요 (담당: NativeOps)
                              onPressed: () => context.push(AppRoutes.anonymousInquiry),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                '업무용 권한 요청 문의',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildCardContainer({required Widget child}) {
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

  /// isExtra: 내 역할 덕분에 추가로 할 수 있는 일 (파란색으로 보여줘요)
  Widget _buildCheckItem(String text, {bool isExtra = false, bool isLast = false}) {
    final color = isExtra ? const Color(0xFF3182F6) : const Color(0xFF64748B);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✓ ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isExtra ? FontWeight.bold : FontWeight.normal,
                color: isExtra ? const Color(0xFF3182F6) : const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleScopeRow(String role, String scope, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              scope,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int step,
    required String title,
    required String desc,
    required bool isActive,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3182F6) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF64748B),
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
                    color: isActive ? const Color(0xFF3182F6) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}