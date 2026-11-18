import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../shared/widgets/default_profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _bioMax = 60; // 서버 제한
  static const int _interestMax = 5; // 서버 제한

  /// 서버 avatarBackground 값 → 화면 색
  static const Map<String, Color> _avatarColors = {
    'GRAY': Color(0xFFEBEBEB),
    'BLUE': Color(0xFFDBEAFE),
    'YELLOW': Color(0xFFFEF3C7),
    'GREEN': Color(0xFFDCFCE7),
    'PINK': Color(0xFFFCE7F3),
    'WHITE': Color(0xFFFFFFFF),
  };
  static const Map<String, String> _avatarColorNames = {
    'GRAY': '회색',
    'BLUE': '파랑',
    'YELLOW': '노랑',
    'GREEN': '초록',
    'PINK': '분홍',
    'WHITE': '흰색',
  };

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  MyProfile? _original; // GET /me 로 받은 처음 값 (바뀐 것만 보내려고 둬요)
  String? _dept;
  List<String> _interests = [];
  String _avatarBackground = '';
  String _photo = '';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  /// GET /me
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final me = await HomeRepository.instance.getMe();
      if (!mounted) return;
      setState(() {
        _original = me;
        _nameController.text = me.name;
        _bioController.text = me.bio;
        // 예전 값('Native · Design' 등)이면 공식 부서로 못 맞추니 비워두고 다시 고르게 해요
        _dept = Departments.normalize(me.dept);
        _interests = List<String>.from(me.interests);
        _avatarBackground = me.avatarBackground;
        _photo = me.photo;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    }
  }

  /// PATCH /me (바뀐 값만 보내요)
  Future<void> _save() async {
    final original = _original;
    if (original == null || _isSaving) return;
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() => _saveError = '이름을 입력해 주세요.');
      return;
    }
    if (_dept == null) {
      setState(() => _saveError = '부서를 선택해 주세요.');
      return;
    }
    if (bio.length > _bioMax) {
      setState(() => _saveError = '한 줄 소개는 $_bioMax자까지 쓸 수 있어요.');
      return;
    }

    final interestsChanged = _interests.join('\n') != original.interests.join('\n');
    final changed = name != original.name ||
        _dept != original.dept ||
        bio != original.bio ||
        interestsChanged ||
        _avatarBackground != original.avatarBackground ||
        _photo != original.photo;

    if (!changed) {
      context.pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await MySpaceRepository.instance.updateProfile(
        name: name != original.name ? name : null,
        dept: _dept != original.dept ? _dept : null,
        bio: bio != original.bio ? bio : null,
        interests: interestsChanged ? _interests : null,
        avatarBackground: _avatarBackground != original.avatarBackground && _avatarBackground.isNotEmpty
            ? _avatarBackground
            : null,
        photo: _photo != original.photo ? _photo : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필을 저장했어요.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = e.message; // 422: 공식 부서 아님, 관심사 5개 초과 등
      });
    }
  }

  // ───────────────────────── 입력 ─────────────────────────

  void _addInterest() {
    if (_interests.length >= _interestMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('관심사는 $_interestMax개까지 등록할 수 있어요.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '관심사 추가',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '관심사를 입력하세요 (예: UX, Flutter)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim().replaceFirst(RegExp(r'^#\s*'), '');
              if (text.isNotEmpty && !_interests.contains(text)) {
                setState(() {
                  _interests = [..._interests, text];
                  _saveError = null;
                });
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// 공식 부서 11개 중에서 골라요 (PATCH /me 는 목록 밖 값을 422로 거절해요)
  void _pickDepartment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '부서 선택',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final dept in Departments.official)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _dept = dept;
                              _saveError = null;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                            color: _dept == dept ? const Color(0xFFF0F5FF) : Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dept,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: _dept == dept ? FontWeight.bold : FontWeight.w500,
                                      color: _dept == dept
                                          ? const Color(0xFF3182F6)
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (_dept == dept)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF3182F6),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 배경색 고르기 (avatarBackground)
  void _pickAvatarBackground() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '배경색 바꾸기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final entry in _avatarColors.entries)
                      GestureDetector(
                        onTap: () {
                          setState(() => _avatarBackground = entry.key);
                          Navigator.pop(sheetContext);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _avatarBackground == entry.key
                                      ? const Color(0xFF3182F6)
                                      : const Color(0xFFE2E8F0),
                                  width: _avatarBackground == entry.key ? 2.5 : 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _avatarColorNames[entry.key]!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 💡 07-16 미모티콘 바꾸기 모달 바텀시트
  void _showChangeMemojiBottomSheet(BuildContext context) {
    void notReady(BuildContext sheetContext) {
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('사진 올리기는 곧 열려요. 지금은 배경색만 바꿀 수 있어요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 상단 메뉴 카드
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // 드래그 핸들 바
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '미모티콘 바꾸기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 메뉴 1: 사진 보관함에서 선택 (업로드 준비 중)
                      _buildBottomSheetActionItem(
                        text: '사진 보관함에서 선택',
                        onTap: () => notReady(sheetContext),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 메뉴 2: 미모티콘 스티커 붙여넣기 (업로드 준비 중)
                      _buildBottomSheetActionItem(
                        text: '미모티콘 스티커 붙여넣기',
                        onTap: () => notReady(sheetContext),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 메뉴 3: 배경색 바꾸기
                      _buildBottomSheetActionItem(
                        text: '배경색 바꾸기',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickAvatarBackground();
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 메뉴 4: 기본 이미지로 변경 (빨간색 텍스트)
                      _buildBottomSheetActionItem(
                        text: '기본 이미지로 변경',
                        textColor: const Color(0xFFEF4444),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _photo = '';
                            _avatarBackground = 'GRAY';
                          });
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('기본 이미지로 바꿨어요. 저장을 눌러야 반영돼요.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. 독립된 하단 취소 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3182F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildBottomSheetActionItem({
    required String text,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF111827),
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (뒤로가기, 타이틀, 저장 버튼)
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
                    '프로필 편집',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _original == null || _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      elevation: 0,
                      minimumSize: const Size(62, 36),
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    const primaryBlue = Color(0xFF3182F6);

    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [SkeletonList(count: 3)],
      );
    }
    if (_original == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ErrorStateView(
            title: '프로필을 불러오지 못했어요',
            message: _loadError,
            onRetry: _load,
            onBack: () => context.pop(),
          ),
        ],
      );
    }

    final original = _original!;
    final wasUnofficialDept = original.dept.isNotEmpty && _dept == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 프로필 아바타 & 미모티콘 바꾸기 버튼
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.06),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DefaultProfileAvatar(
                    size: 110,
                    imageUrl: _photo,
                    backgroundColor: _avatarColors[_avatarBackground] ?? const Color(0xFFEBEBEB),
                    silhouetteColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 💡 미모티콘 바꾸기 클릭 시 바텀시트 노출
                ElevatedButton(
                  onPressed: () => _showChangeMemojiBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '미모티콘 바꾸기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 폼 필드 1: 이름
          _buildFormLabel('이름'),
          _buildTextField(controller: _nameController, maxLength: 100),
          const SizedBox(height: 18),

          // 폼 필드 2: 부서 (공식 부서 11개 중 선택)
          _buildFormLabel('부서'),
          GestureDetector(
            onTap: _pickDepartment,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: wasUnofficialDept ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dept ?? '부서를 선택해 주세요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _dept == null ? const Color(0xFFA0A5B1) : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (wasUnofficialDept) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '지금 저장된 \'${original.dept}\'는 공식 부서가 아니에요. 다시 골라 주세요.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // 폼 필드 3: 한 줄 소개 (60자)
          _buildFormLabel('한 줄 소개'),
          _buildTextField(controller: _bioController, maxLength: _bioMax),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_bioController.text.length} / $_bioMax',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 12),

          // 폼 필드 4: 관심사 (5개까지)
          _buildFormLabel('관심사 · ${_interests.length}/$_interestMax'),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _interests)
                  _buildInterestTag(
                    tag,
                    onRemove: () => setState(() {
                      _interests = _interests.where((t) => t != tag).toList();
                    }),
                  ),
                if (_interests.length < _interestMax)
                  _buildAddInterestChip(onTap: _addInterest),
              ],
            ),
          ),

          if (_saveError != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _saveError!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // 하단 안내 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'iPhone 메시지 앱 > 미모티콘 > 스티커를 길게 눌러 저장한 뒤 업로드하세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int? maxLength,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        onChanged: (_) {
          if (_saveError != null) setState(() => _saveError = null);
        },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildInterestTag(String tag, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '# $tag',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddInterestChip({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '+ 추가',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3182F6),
          ),
        ),
      ),
    );
  }
}