import 'package:flutter/material.dart';
import '../../shared/widgets/default_profile_avatar.dart';

/// 일정 상세 모달 바텀시트 호출 함수
void showScheduleDetailBottomSheet(
    BuildContext context, {
      String category = 'Native 일정 · 변경됨',
      String title = 'Book-on 디자인 리뷰',
      String date = '10월 14일 (화)',
      String time = '15:00 – 16:00',
      String location = '온라인 · Discode',
      String organizer = '참여 6명 · 주최자 이시우',
      int participantCount = 6,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScheduleDetailBottomSheet(
      category: category,
      title: title,
      date: date,
      time: time,
      location: location,
      organizer: organizer,
      participantCount: participantCount,
    ),
  );
}

class ScheduleDetailBottomSheet extends StatefulWidget {
  final String category;
  final String title;
  final String date;
  final String time;
  final String location;
  final String organizer;
  final int participantCount;

  const ScheduleDetailBottomSheet({
    super.key,
    required this.category,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.organizer,
    this.participantCount = 6,
  });

  @override
  State<ScheduleDetailBottomSheet> createState() =>
      _ScheduleDetailBottomSheetState();
}

class _ScheduleDetailBottomSheetState
    extends State<ScheduleDetailBottomSheet> {
  bool? _isAttending; // null: 미선택, true: 참석, false: 불참

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 드래그 핸들 바
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 카테고리 태그 & 닫기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. 일정 제목
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // 4. 메타 정보 리스트 (날짜, 시간, 장소, 주최자)
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              text: widget.date,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.access_time_rounded,
              text: widget.time,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              text: widget.location,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.people_outline_rounded,
              text: widget.organizer,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // 5. 참석자 프로필 아바타 리스트
            Row(
              children: [
                for (int i = 0; i < widget.participantCount; i++)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: DefaultProfileAvatar(
                      size: 32,
                      backgroundColor: Color(0xFFF1F5F9),
                      silhouetteColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 6. 하단 상태 결정 버튼 (불참 / 참석할게요)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _isAttending = false);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAttending == false
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFFF1F5F9),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '불참',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _isAttending = true);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '참석할게요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}