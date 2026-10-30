import 'package:esim_guide/usage_logic.dart';
import 'package:flutter_test/flutter_test.dart';

EsimUsage plan({
  DateTime? activatedOn,
  int validDays = 7,
  double total = 5,
  double used = 0,
}) =>
    EsimUsage(
      planName: '日本 7 天',
      totalGb: total,
      usedGb: used,
      activatedOn: activatedOn ?? DateTime(2026, 11, 1),
      validDays: validDays,
    );

void main() {
  group('最後一天（啟用當天算第 1 天）', () {
    test('7 天方案，11/1 啟用 → 最後一天 11/7', () {
      expect(plan().lastUseDate, DateTime(2026, 11, 7));
    });

    test('跨月：1/30 啟用 5 天 → 2/3', () {
      final p = plan(activatedOn: DateTime(2026, 1, 30), validDays: 5);
      expect(p.lastUseDate, DateTime(2026, 2, 3));
    });

    test('1 天方案 → 最後一天就是啟用日', () {
      expect(plan(validDays: 1).lastUseDate, DateTime(2026, 11, 1));
    });
  });

  group('剩餘天數與狀態', () {
    test('daysLeft：不受當天幾點影響', () {
      expect(plan().daysLeft(DateTime(2026, 11, 5, 0, 5)), 2);
      expect(plan().daysLeft(DateTime(2026, 11, 5, 23, 59)), 2);
      expect(plan().daysLeft(DateTime(2026, 11, 7, 12)), 0);
      expect(plan().daysLeft(DateTime(2026, 11, 8, 12)), -1);
    });

    test('status 四種狀態', () {
      final p = plan();
      expect(p.status(DateTime(2026, 10, 30)), PlanStatus.notStarted);
      expect(p.daysUntilStart(DateTime(2026, 10, 30)), 2);
      expect(p.status(DateTime(2026, 11, 1)), PlanStatus.active);
      expect(p.status(DateTime(2026, 11, 3)), PlanStatus.active);
      expect(p.status(DateTime(2026, 11, 7)), PlanStatus.lastDay);
      expect(p.status(DateTime(2026, 11, 9)), PlanStatus.expired);
    });
  });

  group('流量', () {
    test('已用比例與剩餘', () {
      final p = plan(total: 5, used: 4);
      expect(p.usedFraction, closeTo(0.8, 1e-9));
      expect(p.remainingGb, closeTo(1, 1e-9));
      expect(p.isLowData, isTrue);
    });

    test('用超過總量：比例不超過 1、剩餘不為負', () {
      final p = plan(total: 5, used: 6);
      expect(p.usedFraction, 1.0);
      expect(p.remainingGb, 0);
    });

    test('用量不到 80% 不算快用完', () {
      expect(plan(total: 5, used: 3.9).isLowData, isFalse);
    });
  });

  group('提醒時間', () {
    test('一般情況：前一天與最後一天，早上 9 點', () {
      final r = plan().reminders(DateTime(2026, 11, 3));
      expect(r.map((e) => e.kind), [ReminderKind.dayBefore, ReminderKind.lastDay]);
      expect(r.map((e) => e.at), [
        DateTime(2026, 11, 6, 9),
        DateTime(2026, 11, 7, 9),
      ]);
    });

    test('前一天 9 點已過 → 只剩最後一天', () {
      final r = plan().reminders(DateTime(2026, 11, 6, 10));
      expect(r.map((e) => e.kind), [ReminderKind.lastDay]);
    });

    test('最後一天 9 點也過了 → 沒有提醒', () {
      expect(plan().reminders(DateTime(2026, 11, 7, 10)), isEmpty);
    });

    test('1 天方案：前一天比啟用日早，不設定「前一天」提醒', () {
      final r = plan(validDays: 1).reminders(DateTime(2026, 10, 30));
      expect(r.map((e) => e.kind), [ReminderKind.lastDay]);
    });
  });

  group('存檔格式', () {
    test('toJson / fromJson 來回一致', () {
      final p = plan(used: 1.5);
      final back = EsimUsage.fromJson(p.toJson());
      expect(back.planName, p.planName);
      expect(back.totalGb, p.totalGb);
      expect(back.usedGb, 1.5);
      expect(back.activatedOn, DateTime(2026, 11, 1));
      expect(back.validDays, 7);
    });
  });

  group('文案', () {
    test('fill 會取代 {key}', () {
      expect(fill('還剩 {n} 天', {'n': '3'}), '還剩 3 天');
    });
  });
}
