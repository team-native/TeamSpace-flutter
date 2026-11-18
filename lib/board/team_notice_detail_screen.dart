import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class UnconfirmedUser {
  final String name;
  final String email;

  UnconfirmedUser({required this.name, required this.email});
}

class TeamNoticeDetailScreen extends StatefulWidget {
  final bool canEdit;

  const TeamNoticeDetailScreen({
    super.key,
    this.canEdit = true,
  });

  @override
  State<TeamNoticeDetailScreen> createState() => _TeamNoticeDetailScreenState();
}

class _TeamNoticeDetailScreenState extends State<TeamNoticeDetailScreen> {
  bool _isConfirmed = false;

  // 피그마 명세 미확인자 리스트 (이름순)
  final List<UnconfirmedUser> _unconfirmedUsers = [
    UnconfirmedUser(name: '옥물결', email: 's26103@gsm.hs.kr'),
    UnconfirmedUser(name: '유다인', email: 's26107@gsm.hs.kr'),
    UnconfirmedUser(name: '조현우', email: 's26105@gsm.hs.kr'),
  ];

  // 💡 피그마 10-6c 확인 안 한 사람 모달 바텀시트
  void _showUnconfirmedUserBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const textDark = Color(0xFF111827);
        const textLightGrey = Color(0xFF94A3B8);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 상단 핸들 바
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. 타이틀 & 미확인 인원 수
                const Text(
                  '확인 안 한 사람',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_unconfirmedUsers.length}명',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textLightGrey,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. 미확인자 리스트
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _unconfirmedUsers.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final user = _unconfirmedUsers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFEAEFF5),
                            child: Icon(
                              Icons.person_rounded,
                              size: 22,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textLightGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFFFFF);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 24,
                      ),
                    ),
                  ),
                  const Text(
                    '공지',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  if (widget.canEdit)
                    InkWell(
                      onTap: () => context.push(AppRoutes.teamNoticeEdit),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: textDark,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 태그 칩
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '재무',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '필독',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF43F5E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 공지 제목
                    const Text(
                      '10월 프로젝트\n정산 기준 안내',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 작성자 프로필 정보
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: textLightGrey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '김민준 · FA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '2026.10.10 · 조회 52',
                              style: TextStyle(
                                fontSize: 12,
                                color: textLightGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    // 본문 내용
                    const Text(
                      '이번 달부터 외주 프로젝트 정산은 입금 확인 후 3영업일 안에 진행돼요.\n\n'
                          '• 운영풀 40% · 적립풀 30% · 배당풀 30%로 자동 배분해요.\n'
                          '• 배당풀은 프로젝트 기여도 시트를 기준으로 나눠요.\n'
                          '• 기여도 시트는 PM이 프로젝트 종료 후 1주 안에 제출해요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textDark,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 첨부 문서 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: primaryBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '외주 수금 및 풀 배분 기준',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '문서함 · FINANCE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: textLightGrey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 💡 관리자 확인 현황 카드
                    if (widget.canEdit) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.02),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  '확인 현황',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  '12 / 24명 확인',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                value: 12 / 24,
                                minHeight: 6,
                                backgroundColor: Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 💡 터치 시 바텀 시트 호출 연동
                            InkWell(
                              onTap: () => _showUnconfirmedUserBottomSheet(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          '확인 안 한 사람 보기',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '관리자만 볼 수 있어요',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSub,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: textLightGrey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 하단 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isConfirmed = !_isConfirmed;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConfirmed ? const Color(0xFFE2E8F0) : primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isConfirmed ? '확인 완료' : '확인했어요',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isConfirmed ? textSub : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}