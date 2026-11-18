import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/approval_models.dart';

/// 결재 API
/// - GET   /approvals?box=mine|received|handled&status=&cursor=&limit=
/// - GET   /approvals/{id}
/// - POST  /approvals                     작성 · 제출 (status '작성 중'이면 임시 저장)
/// - PATCH /approvals/{id}                작성 중 · 반려된 내 결재 수정 (status '결재 대기'로 다시 제출)
/// - POST  /approvals/{id}/approve | reject {reason} | cancel
/// - POST  /approvals/{id}/comments {text}
class ApprovalRepository {
  ApprovalRepository._();
  static final ApprovalRepository instance = ApprovalRepository._();

  /// box: mine(내가 올린), received(받은 · 처리 전), handled(내가 처리한)
  Future<ApprovalPage> getApprovals({
    String box = 'mine',
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/approvals',
      query: {'box': box, 'status': status, 'cursor': cursor, 'limit': limit},
    );
    return ApprovalPage.fromJson(data);
  }

  /// 한 상자를 끝까지 (최대 5페이지 · 500건) — 상태별 숫자를 세려고 써요
  Future<List<Approval>> getAll(String box) async {
    final result = <Approval>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final page = await getApprovals(box: box, cursor: cursor, limit: 100);
      result.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor == null) break;
    }
    return result;
  }

  Future<Approval> getApproval(String id) async {
    final data = await ApiClient.instance.get('/approvals/$id');
    return Approval.fromJson(_asMap(data));
  }

  /// 작성 · 제출 → ({id, status})
  /// [draft] 가 true면 임시 저장('작성 중'), 아니면 바로 결재선이 정해져요('검토 중')
  /// 결재선을 꾸릴 다른 담당자가 없으면 서버가 409를 줘요
  Future<({String id, String status})> create(Map<String, dynamic> body, {bool draft = false}) async {
    final data = await ApiClient.instance.post(
      '/approvals',
      body: {...body, 'status': draft ? ApprovalStatus.draft : ApprovalStatus.waiting},
    );
    final m = _asMap(data);
    return (id: '${m['id']}', status: '${m['status'] ?? ''}');
  }

  /// 작성 중 · 반려된 내 결재 고치기. [submit] 이면 다시 제출해요.
  Future<Approval> update(String id, Map<String, dynamic> changes, {bool submit = false}) async {
    final data = await ApiClient.instance.patch(
      '/approvals/$id',
      body: {...changes, if (submit) 'status': ApprovalStatus.waiting},
    );
    return Approval.fromJson(_asMap(data));
  }

  Future<String> approve(String id) async {
    final data = await ApiClient.instance.post('/approvals/$id/approve');
    return '${_asMap(data)['status'] ?? ''}';
  }

  /// 반려 (사유가 비어 있으면 서버가 400)
  Future<String> reject(String id, String reason) async {
    final data = await ApiClient.instance.post('/approvals/$id/reject', body: {'reason': reason.trim()});
    return '${_asMap(data)['status'] ?? ''}';
  }

  Future<void> cancel(String id) async {
    await ApiClient.instance.post('/approvals/$id/cancel');
  }

  Future<ApprovalComment> addComment(String id, String text) async {
    final data = await ApiClient.instance.post('/approvals/$id/comments', body: {'text': text.trim()});
    return ApprovalComment.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}