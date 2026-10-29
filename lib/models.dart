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
  });

  final String icon;
  final String title;
  final String body;
  final String tip;

  factory GuideStep.fromJson(Map<String, dynamic> json) => GuideStep(
        icon: json['icon'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        tip: json['tip'] as String,
      );
}

Future<List<GuideStep>> loadSteps() async {
  final raw = await rootBundle.loadString('assets/steps.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => GuideStep.fromJson(e as Map<String, dynamic>))
      .toList();
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
