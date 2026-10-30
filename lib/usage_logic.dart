import 'dart:math' as math;

/// 方案目前的狀態
enum PlanStatus { notStarted, active, lastDay, expired }

/// 提醒的種類
enum ReminderKind { dayBefore, lastDay }

class ScheduledReminder {
  const ScheduledReminder(this.kind, this.at);

  final ReminderKind kind;

  /// 手機當地時間
  final DateTime at;
}

String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 只取日期（去掉時間）
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 使用者手動記錄的一個 eSIM 方案。
///
/// 注意：App 讀不到 eSIM 的實際用量，流量與天數都是使用者自己輸入的。
class EsimUsage {
  const EsimUsage({
    required this.planName,
    required this.totalGb,
    required this.usedGb,
    required this.activatedOn,
    required this.validDays,
  });

  factory EsimUsage.fromJson(Map<String, dynamic> json) {
    final parts = (json['activatedOn'] as String).split('-');
    return EsimUsage(
      planName: json['planName'] as String,
      totalGb: (json['totalGb'] as num).toDouble(),
      usedGb: (json['usedGb'] as num).toDouble(),
      activatedOn: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      validDays: json['validDays'] as int,
    );
  }

  final String planName;
  final double totalGb;
  final double usedGb;

  /// 啟用日（只看日期）
  final DateTime activatedOn;
  final int validDays;

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'totalGb': totalGb,
        'usedGb': usedGb,
        'activatedOn': ymd(activatedOn),
        'validDays': validDays,
      };

  EsimUsage copyWith({double? usedGb}) => EsimUsage(
        planName: planName,
        totalGb: totalGb,
        usedGb: usedGb ?? this.usedGb,
        activatedOn: activatedOn,
        validDays: validDays,
      );

  /// 最後可使用的日期。
  /// 保守推算：把啟用當天算第 1 天，所以 7 天方案從 11/1 啟用，最後一天是 11/7。
  /// 各家供應商算法不同，寧可提醒得早一點，也不要晚。
  DateTime get lastUseDate => DateTime(
        activatedOn.year,
        activatedOn.month,
        activatedOn.day + validDays - 1,
      );

  double get remainingGb => math.max(0, totalGb - usedGb);

  /// 已用比例，0.0 ~ 1.0
  double get usedFraction =>
      totalGb <= 0 ? 0 : (usedGb / totalGb).clamp(0.0, 1.0).toDouble();

  bool get isLowData => usedFraction >= 0.8;

  // 用 UTC 的日期相減，避免夏令時間讓某一天變成 23 或 25 小時
  static int _dayDiff(DateTime a, DateTime b) =>
      DateTime.utc(a.year, a.month, a.day)
          .difference(DateTime.utc(b.year, b.month, b.day))
          .inDays;

  /// 距離最後一天還有幾天：0 = 今天是最後一天，負數 = 已過期
  int daysLeft(DateTime now) => _dayDiff(lastUseDate, now);

  /// 距離啟用日還有幾天（已開始則 <= 0）
  int daysUntilStart(DateTime now) => _dayDiff(activatedOn, now);

  PlanStatus status(DateTime now) {
    if (daysUntilStart(now) > 0) return PlanStatus.notStarted;
    final left = daysLeft(now);
    if (left < 0) return PlanStatus.expired;
    if (left == 0) return PlanStatus.lastDay;
    return PlanStatus.active;
  }

  /// 需要設定的提醒（只包含還沒過去的）：
  /// 最後一天的前一天早上 9 點、最後一天早上 9 點。
  List<ScheduledReminder> reminders(DateTime now) {
    final last = lastUseDate;
    final before = DateTime(last.year, last.month, last.day - 1, 9);
    final onDay = DateTime(last.year, last.month, last.day, 9);

    final result = <ScheduledReminder>[];
    // 前一天如果比啟用日還早（例如 1 天方案），提醒沒有意義
    if (!dateOnly(before).isBefore(activatedOn) && before.isAfter(now)) {
      result.add(ScheduledReminder(ReminderKind.dayBefore, before));
    }
    if (onDay.isAfter(now)) {
      result.add(ScheduledReminder(ReminderKind.lastDay, onDay));
    }
    return result;
  }
}

// ───────────── 文案（來自 assets/usage_texts.json）─────────────

class TextPair {
  const TextPair({required this.title, required this.body});

  factory TextPair.fromJson(Map<String, dynamic> json) =>
      TextPair(title: json['title'] as String, body: json['body'] as String);

  final String title;
  final String body;
}

/// 把文案裡的 {key} 換成實際內容
String fill(String template, Map<String, String> values) {
  var out = template;
  values.forEach((key, value) => out = out.replaceAll('{$key}', value));
  return out;
}

class UsageTexts {
  const UsageTexts({
    required this.verified,
    required this.reminders,
    required this.status,
    required this.results,
    required this.warnings,
    required this.notes,
  });

  factory UsageTexts.fromJson(Map<String, dynamic> json) {
    Map<String, String> strings(String key) =>
        (json[key] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String));

    return UsageTexts(
      verified: json['verified'] == true,
      reminders: (json['reminders'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, TextPair.fromJson(v as Map<String, dynamic>)),
      ),
      status: strings('status'),
      results: strings('results'),
      warnings: strings('warnings'),
      notes: (json['notes'] as List<dynamic>).cast<String>(),
    );
  }

  final bool verified;
  final Map<String, TextPair> reminders;
  final Map<String, String> status;
  final Map<String, String> results;
  final Map<String, String> warnings;
  final List<String> notes;

  TextPair reminder(ReminderKind kind, String planName) {
    final pair = reminders[kind.name];
    if (pair == null) return const TextPair(title: 'eSIM 提醒', body: '');
    return TextPair(
      title: fill(pair.title, {'plan': planName}),
      body: fill(pair.body, {'plan': planName}),
    );
  }

  String statusText(PlanStatus s, int days) =>
      fill(status[s.name] ?? '', {'n': '${days.abs()}'});

  String resultText(String key) => results[key] ?? '';

  String warning(String key) => warnings[key] ?? '';
}
