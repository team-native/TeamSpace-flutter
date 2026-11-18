import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAvailableSelected = true;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const bgColor = Color(0xFFF5F6F8);
    const textGrey = Color(0xFF8E8E93);
    const greenColor = Color(0xFF27AE60);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 앱바
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo-lockup.png',
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Row(
                        children: [
                          Icon(Icons.waves_rounded, color: Color(0xFFFFD600), size: 22),
                          SizedBox(width: 6),
                          Text(
                            'Native',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => context.push(AppRoutes.notificationList),
                        icon: const Icon(Icons.notifications_none_rounded, size: 26),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEB5757),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '5',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. 타이틀 & 서브타이틀
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'NATIVE TEAMSPACE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Native의 일을\n한곳에서.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '옥물결 님, 오늘 확인할 일이 3건 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: textGrey,
                ),
              ),

              const SizedBox(height: 16),

              // 3. 결재 요청 카드
              InkWell(
                onTap: () => context.push(AppRoutes.notificationDetail),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '새 결재 요청이 도착했어요',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '이사유 · 프로젝트 인력 지원 · 뱅군',
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
                        color: textGrey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. 재무 트래커 카드
              _buildFinanceTrackerCard(primaryBlue, textGrey, greenColor),

              const SizedBox(height: 20),

              // 5. 수주 · 입금 카드
              _buildOrdersRevenueCard(primaryBlue, textGrey, greenColor),

              const SizedBox(height: 20),

              // 6. 진행 중인 프로젝트 카드
              _buildOngoingProjectsCard(primaryBlue, textGrey),

              const SizedBox(height: 20),

              // 7. 주요 일정 카드
              _buildScheduleCard(primaryBlue, textGrey),

              const SizedBox(height: 20),

              // 8. 지금 팀이 알아야 할 것들
              _buildAnnouncementsCard(primaryBlue, textGrey),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // 홈 화면: index 0
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildFinanceTrackerCard(Color primaryBlue, Color textGrey, Color greenColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '재무 트래커',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '2026년 10월',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAvailableSelected = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isAvailableSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isAvailableSelected
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '사용 가능',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            _isAvailableSelected ? FontWeight.bold : FontWeight.normal,
                            color: _isAvailableSelected ? Colors.black : textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAvailableSelected = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isAvailableSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isAvailableSelected
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          'Native 보유금',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            !_isAvailableSelected ? FontWeight.bold : FontWeight.normal,
                            color: !_isAvailableSelected ? Colors.black : textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            '지금 사용할 수 있는 금액',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text(
                '3,560,000',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                ' 원',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                '지난달보다 ',
                style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
              ),
              Text(
                '+12.8%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: greenColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildPoolItem('운영풀', '40%', '3,560,000', const Color(0xFFEBF3FF)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPoolItem('직침풀', '30%', '2,670,000', const Color(0xFFF3F0FF)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPoolItem('배당풀', '30%', '2,670,000', const Color(0xFFFFF4E5)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('이번 달 수입',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    const SizedBox(height: 4),
                    Text(
                      '+7,260,000원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: greenColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFEAECEF)),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이번 달 지출',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                      SizedBox(height: 4),
                      Text(
                        '-3,480,000원',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.financeDashboard);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F6F8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '재무 자세히 보기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolItem(String title, String percent, String amount, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              Text(
                percent,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F80ED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersRevenueCard(Color primaryBlue, Color textGrey, Color greenColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '수주 · 입금',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.financeDashboard),
                child: const Text(
                  '전체 보기',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('누적 수주 금액', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                '12,700,000',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                '원',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '올해 9건',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '최근 수주',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildOrderItem('예약 서비스 앱 UI 제작', '4,200,000원', '10월 21일', '계약 완료'),
          const Divider(height: 16, color: Color(0xFFF5F6F8)),
          _buildOrderItem('IoT 학과 홍보 웹 페이지', '1,309,000원', '10월 20일', '계약 완료'),
          const SizedBox(height: 16),
          const Text(
            '최근 입금',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildRevenueItem('먼작귀 포켓앱 UI 제작', '+800,000원', '선금 · 10월 31일', greenColor),
          const Divider(height: 16, color: Color(0xFFF5F6F8)),
          _buildRevenueItem('카피바라 키우기 제작', '+4,200,000원', '선금 · 10월 15일', greenColor),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String title, String amount, String date, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: const TextStyle(fontSize: 10, color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueItem(String title, String amount, String detail, Color greenColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(detail, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: greenColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingProjectsCard(Color primaryBlue, Color textGrey) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '진행 중인 프로젝트',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Text('2건', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.projectList),
                child: const Text('전체 보기', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProjectProgressItem('먼작귀 포켓앱 UI 제작', 'D-37', '팀원 5명 · 마감 11월 11일', 0.35, '35%'),
          const SizedBox(height: 16),
          _buildProjectProgressItem('MoSS', 'D-14', '팀원 6명 · 마감 11월 14일', 0.60, '60%'),
        ],
      ),
    );
  }

  Widget _buildProjectProgressItem(
      String title, String badge, String subtitle, double progress, String percentStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 11, color: Color(0xFFEB5757), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF5F6F8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            Text(percentStr, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Color primaryBlue, Color textGrey) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '주요 일정',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Text('2건', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.scheduleCalendar),
                child: const Text('캘린더', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleItem('10월', '26', '주간 팀 회의', '월요일 · 온라인', const Color(0xFFEBF3FF), primaryBlue),
          const SizedBox(height: 12),
          _buildScheduleItem('11월', '06', 'IoT 학과 홍보 홈페이지 납품', '금요일 · D-14', const Color(0xFFFFF4E5), const Color(0xFFF2994A)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
      String month, String day, String title, String subtitle, Color badgeBg, Color badgeTextColor) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                month,
                style: TextStyle(fontSize: 9, color: badgeTextColor, fontWeight: FontWeight.bold),
              ),
              Text(
                day,
                style: TextStyle(fontSize: 14, color: badgeTextColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
      ],
    );
  }

  Widget _buildAnnouncementsCard(Color primaryBlue, Color textGrey) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '지금 팀이 알아야 할 것들',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.noticeList),
                child: const Text('전체 보기 >', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoticeItem('재무', '어제 업데이트', '10월 프로젝트 정산 기준 안내', const Color(0xFFEBF3FF), primaryBlue),
          const Divider(height: 20, color: Color(0xFFF5F6F8)),
          _buildNoticeItem('규칙', '3일 전', '외주 프로젝트 착수 전 체크리스트', const Color(0xFFF5F6F8), const Color(0xFF6B7280)),
          const Divider(height: 20, color: Color(0xFFF5F6F8)),
          _buildNoticeItem('공지', '10월 10일', 'NativeLab 계약서 작성 가이드', const Color(0xFFFFF4E5), const Color(0xFFF2994A)),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(
      String category, String date, String title, Color tagBg, Color tagColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(fontSize: 10, color: tagColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
      ],
    );
  }
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2F80ED)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25, size.height * 0.2,
      size.width * 0.5, size.height * 0.85,
      size.width * 0.75, size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2F80ED).withOpacity(0.15),
          const Color(0xFF2F80ED).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}