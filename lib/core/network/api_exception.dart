import 'package:dio/dio.dart';

/// 화면에 그대로 보여줄 수 있는 서버 통신 에러
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('서버 응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.');
      case DioExceptionType.connectionError:
        return const ApiException('서버에 연결할 수 없어요. 인터넷 연결을 확인해 주세요.');
      default:
        break;
    }

    final body = e.response?.data;
    if (body is Map) {
      // 1) FastAPI 형식: { "detail": "..." } 또는 { "detail": [ {loc, msg, type}, ... ] }
      final fromDetail = _messageFromDetail(body['detail']);
      if (fromDetail != null) {
        return ApiException(fromDetail, statusCode: status);
      }

      // 2) 기존 명세 형식: { "code", "message", "errors": [{ "field", "reason" }] }
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty && errors.first is Map) {
        final reason = (errors.first as Map)['reason'];
        if (reason is String && reason.isNotEmpty) {
          return ApiException(reason, statusCode: status);
        }
      }
      final message = body['message'];
      if (message is String && message.isNotEmpty) {
        return ApiException(message, statusCode: status);
      }
    }

    return ApiException(_defaultMessage(status), statusCode: status);
  }

  // ───────────── 내부 ─────────────

  static String? _messageFromDetail(dynamic detail) {
    // 서버가 직접 쓴 한국어 메시지 (409, 404, 400 등)
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }

    // 422 입력값 검증 에러: 첫 번째 항목만 사용자에게 보여줘요
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final first = detail.first as Map;
      final loc = first['loc'];
      final field = (loc is List && loc.isNotEmpty) ? '${loc.last}' : '';
      final label = _fieldLabels[field];

      if (label != null) return '$label을(를) 확인해 주세요.';

      // 알 수 없는 필드인데 서버 메시지가 한국어면 그대로 사용
      final msg = first['msg'];
      if (msg is String && RegExp(r'[가-힣]').hasMatch(msg)) {
        return msg.replaceFirst('Value error, ', '');
      }
      return '입력한 내용을 다시 확인해 주세요.';
    }

    return null;
  }

  // 422 에러에서 필드 이름을 한국어로 바꿔 보여줄 때 사용
  static const Map<String, String> _fieldLabels = {
    'email': '이메일',
    'password': '비밀번호',
    'name': '이름',
    'dept': '소속 부서',
    'department': '소속 부서',
    'major': '전공',
    'cohort': '기수',
    'message': '남길 말',
    'title': '제목',
    'body': '내용',
    'content': '내용',
    'dueDate': '마감일',
    'token': '재설정 링크',
  };

  static String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return '요청 내용이 올바르지 않아요.';
      case 401:
        return '로그인이 만료됐어요. 다시 로그인해 주세요.';
      case 403:
        return '접근 권한이 없어요.';
      case 404:
        return '요청한 정보를 찾을 수 없어요.';
      case 409:
        return '이미 처리된 요청이에요.';
      case 422:
        return '입력한 내용을 다시 확인해 주세요.';
    }
    if (status != null && status >= 500) {
      return '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
    }
    return '알 수 없는 오류가 발생했어요.';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}