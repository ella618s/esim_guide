import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'usage_logic.dart';

/// 設定提醒的結果。name 同時是 assets/usage_texts.json 裡 results 的 key。
enum ReminderResult {
  scheduled,
  nothingToSchedule,
  permissionDenied,
  failed,
  unsupported,
}

/// 包裝 flutter_local_notifications：只負責「把提醒排進系統」。
class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _idDayBefore = 1001;
  static const _idLastDay = 1002;

  static int _idOf(ReminderKind kind) => switch (kind) {
        ReminderKind.dayBefore => _idDayBefore,
        ReminderKind.lastDay => _idLastDay,
      };

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        // 權限等到真的要設定提醒時才問，不要一打開 App 就跳
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> _requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// 先取消舊提醒，再依目前方案重新設定。
  Future<ReminderResult> scheduleFor(
    EsimUsage plan,
    UsageTexts texts, {
    DateTime? now,
  }) async {
    if (!_isSupported) return ReminderResult.unsupported;
    try {
      await _ensureReady();
      await _cancelBoth();

      final reminders = plan.reminders(now ?? DateTime.now());
      if (reminders.isEmpty) return ReminderResult.nothingToSchedule;

      if (!await _requestPermission()) return ReminderResult.permissionDenied;

      for (final reminder in reminders) {
        final text = texts.reminder(reminder.kind, plan.planName);
        await _plugin.zonedSchedule(
          id: _idOf(reminder.kind),
          title: text.title,
          body: text.body,
          // 提醒只需要「在某個瞬間響」，所以用 UTC 的絕對時間，
          // 不用另外查手機的時區名稱。
          scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
          notificationDetails: NotificationDetails(
            android: const AndroidNotificationDetails(
              'esim_expiry',
              'eSIM 到期提醒',
              channelDescription: 'eSIM 方案快到期時的提醒',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          // 不要求「精準鬧鐘」權限，早上 9 點晚幾分鐘沒關係
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      return ReminderResult.scheduled;
    } catch (e, st) {
      debugPrint('設定提醒失敗：$e\n$st');
      return ReminderResult.failed;
    }
  }

  Future<void> cancelAll() async {
    if (!_isSupported) return;
    try {
      await _ensureReady();
      await _cancelBoth();
    } catch (e) {
      debugPrint('取消提醒失敗：$e');
    }
  }

  Future<void> _cancelBoth() async {
    await _plugin.cancel(id: _idDayBefore);
    await _plugin.cancel(id: _idLastDay);
  }
}
