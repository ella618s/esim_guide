import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 目前支援的國家（之後可以改成從資料載入）
const supportedCountries = ['日本', '韓國', '泰國'];

/// 使用者這次的行程：去哪裡、去幾天
class Trip {
  const Trip({required this.country, required this.days});

  final String country;
  final int days;

  /// 只改其中一個欄位，其他沿用（Kotlin 的 data class copy() 概念）
  Trip copyWith({String? country, int? days}) =>
      Trip(country: country ?? this.country, days: days ?? this.days);
}

/// 一個教學步驟（對應 assets/steps.json 裡的一筆資料）
class GuideStep {
  const GuideStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.tip,
    this.pathKey,
  });

  final String icon;
  final String title;
  final String body;
  final String tip;

  /// 這一步要到手機設定的哪裡操作（'sim'、'roaming'、'dataSim'、'apn'）。
  /// 實際的選單路徑依機型而定，放在 device_paths.json。沒有的話就不顯示路徑。
  final String? pathKey;

  factory GuideStep.fromJson(Map<String, dynamic> json) => GuideStep(
        icon: json['icon'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        tip: json['tip'] as String,
        pathKey: json['pathKey'] as String?,
      );
}

Future<List<GuideStep>> loadSteps() async {
  final raw = await rootBundle.loadString('assets/steps.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => GuideStep.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 手機系統：落地後的操作路徑，iPhone 和 Android 不一樣
enum OsKind { ios, android }

/// 落地後開啟網路的步驟（對應 assets/landing_steps.json）
/// 回傳的是「系統 → 步驟清單」，iPhone 和 Android 各一份
Future<Map<OsKind, List<GuideStep>>> loadLandingSteps() async {
  final raw = await rootBundle.loadString('assets/landing_steps.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;

  List<GuideStep> parse(String key) => (json[key] as List<dynamic>)
      .map((e) => GuideStep.fromJson(e as Map<String, dynamic>))
      .toList();

  return {OsKind.ios: parse('ios'), OsKind.android: parse('android')};
}

/// 一個 eSIM 方案（對應 assets/plans.json）
/// 注意：目前是「範例資料」，不是真實的供應商方案與價格。
class EsimPlan {
  const EsimPlan({
    required this.country,
    required this.days,
    required this.dataGb,
    required this.priceTwd,
    required this.hotspot,
  });

  final String country;
  final int days;
  final double dataGb;
  final int priceTwd;
  final bool hotspot;

  factory EsimPlan.fromJson(Map<String, dynamic> json) => EsimPlan(
        country: json['country'] as String,
        days: json['days'] as int,
        dataGb: (json['dataGb'] as num).toDouble(),
        priceTwd: json['priceTwd'] as int,
        hotspot: json['hotspot'] as bool,
      );

  /// 顯示用的流量文字，整數就不顯示小數點（5GB 而不是 5.0GB）
  String get dataLabel => dataGb == dataGb.roundToDouble()
      ? '${dataGb.toInt()}GB'
      : '${dataGb}GB';

  /// 用「平均每天可用流量」，轉成新手看得懂的白話說明（粗略估計）
  String get usageHint {
    final perDay = dataGb / days;
    if (perDay < 0.8) {
      return '約可查地圖、傳 LINE 訊息，不建議看影片或視訊';
    }
    if (perDay < 1.5) {
      return '地圖、LINE、IG 都夠用，偶爾看短影片也可以';
    }
    return '流量寬裕，可以常看影片、視訊，或分享給同行的人';
  }
}

Future<List<EsimPlan>> loadPlans() async {
  final raw = await rootBundle.loadString('assets/plans.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => EsimPlan.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 推薦邏輯：
/// 1. 只留下同一個國家、而且天數夠用的方案
/// 2. 天數越接近行程越前面（避免買太久浪費），天數一樣就比價格
/// 回傳的第一筆就是「最適合」的方案；空的代表找不到。
List<EsimPlan> recommendPlans(
  List<EsimPlan> all,
  String country,
  int tripDays,
) {
  final candidates =
      all.where((p) => p.country == country && p.days >= tripDays).toList();
  candidates.sort((a, b) {
    final byDays = a.days.compareTo(b.days);
    return byDays != 0 ? byDays : a.priceTwd.compareTo(b.priceTwd);
  });
  return candidates;
}

/// 排查流程裡，每個節點的種類
enum TroubleKind {
  question, // 問一個問題，依回答前往不同節點
  fix, // 請使用者做一件事，再問有沒有解決
  done, // 解決了
  support, // 都試過了，建議聯絡客服
}

/// 節點上的一個按鈕：顯示的文字，與按下後前往哪個節點
class TroubleOption {
  const TroubleOption({required this.label, required this.next});

  final String label;
  final String next;

  factory TroubleOption.fromJson(Map<String, dynamic> json) => TroubleOption(
        label: json['label'] as String,
        next: json['next'] as String,
      );
}

class TroubleNode {
  const TroubleNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.text,
    required this.options,
    this.action,
    this.pathKey,
  });

  final String id;
  final TroubleKind kind;
  final String title;
  final String text;
  final List<TroubleOption> options;

  /// 額外的動作按鈕，目前只有 'landing'（打開落地後三步驟）
  final String? action;

  /// 這個節點要提示到手機設定的哪裡操作，和 GuideStep.pathKey 同一套
  final String? pathKey;

  factory TroubleNode.fromJson(String id, Map<String, dynamic> json) =>
      TroubleNode(
        id: id,
        kind: TroubleKind.values.byName(json['kind'] as String),
        title: json['title'] as String,
        text: (json['text'] as String?) ?? '',
        action: json['action'] as String?,
        pathKey: json['pathKey'] as String?,
        options: ((json['options'] as List<dynamic>?) ?? const [])
            .map((e) => TroubleOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 整個排查流程：一個起點，加上所有節點（像一張「流程圖」）
class TroubleFlow {
  const TroubleFlow({required this.start, required this.nodes});

  final String start;
  final Map<String, TroubleNode> nodes;
}

Future<TroubleFlow> loadTroubleFlow() async {
  final raw = await rootBundle.loadString('assets/troubleshoot.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;

  final nodes = (json['nodes'] as Map<String, dynamic>).map(
    (id, value) => MapEntry(
      id,
      TroubleNode.fromJson(id, value as Map<String, dynamic>),
    ),
  );
  final start = json['start'] as String;

  // 檢查：起點和每個選項指向的節點都要存在。
  // 之後自己改 JSON 時，只要打錯一個 id，這裡會馬上告訴你是哪一個。
  if (!nodes.containsKey(start)) {
    throw FormatException('找不到起點節點：$start');
  }
  for (final node in nodes.values) {
    for (final option in node.options) {
      if (!nodes.containsKey(option.next)) {
        throw FormatException('「${node.id}」的選項指向不存在的節點：${option.next}');
      }
    }
  }

  return TroubleFlow(start: start, nodes: nodes);
}

/// 一種手機機型（或品牌）：iPhone、Samsung、Pixel…
/// 每個機型有自己的設定路徑。資料在 assets/device_paths.json。
class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.name,
    required this.os,
    required this.verified,
    required this.paths,
  });

  final String id;
  final String name;
  final OsKind os;

  /// 這份路徑是否已經在實機上核對過。沒核對過的，畫面上會提醒使用者。
  final bool verified;

  /// pathKey → 選單路徑
  final Map<String, String> paths;

  factory DeviceProfile.fromJson(Map<String, dynamic> json) => DeviceProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        os: OsKind.values.byName(json['os'] as String),
        verified: (json['verified'] as bool?) ?? false,
        paths: (json['paths'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value as String)),
      );
}

Future<List<DeviceProfile>> loadDeviceProfiles() async {
  final raw = await rootBundle.loadString('assets/device_paths.json');
  final list = jsonDecode(raw) as List<dynamic>;
  final profiles = list
      .map((e) => DeviceProfile.fromJson(e as Map<String, dynamic>))
      .toList();
  if (profiles.isEmpty) {
    throw const FormatException('device_paths.json 裡沒有任何機型');
  }
  return profiles;
}
