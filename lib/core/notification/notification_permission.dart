import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 기기(OS) 알림 권한 상태
enum DeviceNotificationStatus {
  granted, // 켜짐
  denied, // 꺼짐 (다시 물어볼 수 있음)
  permanentlyDenied, // 꺼짐 (기기 설정에서만 켤 수 있음)
  unsupported, // 이 기기에서는 확인할 수 없음 (Windows, 웹 등)
}

/// 기기 알림 권한 확인 / 요청 / 설정 열기
/// Android, iOS에서만 동작하고 나머지 기기는 unsupported로 돌려줘요.
class NotificationPermission {
  NotificationPermission._();

  static bool get isSupported =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  /// 화면에 보여줄 권한 이름 (예: "iOS 알림 권한")
  static String get label {
    if (kIsWeb) return '브라우저 알림 권한';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS 알림 권한';
      case TargetPlatform.android:
        return 'Android 알림 권한';
      default:
        return '기기 알림 권한';
    }
  }

  /// 지금 권한 상태 (권한 창은 띄우지 않아요)
  static Future<DeviceNotificationStatus> status() async {
    if (!isSupported) return DeviceNotificationStatus.unsupported;
    try {
      return _map(await Permission.notification.status);
    } catch (_) {
      return DeviceNotificationStatus.unsupported;
    }
  }

  /// 권한 창을 띄워요. 이미 거절해서 다시 물어볼 수 없으면 창 없이 결과만 돌려줘요.
  static Future<DeviceNotificationStatus> request() async {
    if (!isSupported) return DeviceNotificationStatus.unsupported;
    try {
      return _map(await Permission.notification.request());
    } catch (_) {
      return DeviceNotificationStatus.unsupported;
    }
  }

  /// 기기 설정의 이 앱 화면을 열어요. 열지 못하면 false
  static Future<bool> openSettings() async {
    if (!isSupported) return false;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static DeviceNotificationStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return DeviceNotificationStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return DeviceNotificationStatus.permanentlyDenied;
    }
    return DeviceNotificationStatus.denied;
  }
}