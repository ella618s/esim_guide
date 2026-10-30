import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_service.dart';
import 'usage_logic.dart';

const _storageKey = 'esim_usage_v1';

final reminderServiceProvider =
    Provider<ReminderService>((ref) => ReminderService());

/// 文案：assets/usage_texts.json
final usageTextsProvider = FutureProvider<UsageTexts>((ref) async {
  final raw = await rootBundle.loadString('assets/usage_texts.json');
  return UsageTexts.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// 使用者記錄的方案（null = 還沒有記錄）。要跨畫面、要記住，所以放 Riverpod。
final usageProvider =
    AsyncNotifierProvider<UsageNotifier, EsimUsage?>(UsageNotifier.new);

class UsageNotifier extends AsyncNotifier<EsimUsage?> {
  @override
  Future<EsimUsage?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      return EsimUsage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 存檔壞掉就當作沒有資料，不要讓 App 打不開
      return null;
    }
  }

  Future<void> _persist(EsimUsage plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plan.toJson()));
    state = AsyncData(plan);
  }

  /// 新增或編輯方案，並重新設定到期提醒。
  Future<ReminderResult> savePlan(EsimUsage plan) async {
    await _persist(plan);
    final texts = await ref.read(usageTextsProvider.future);
    return ref.read(reminderServiceProvider).scheduleFor(plan, texts);
  }

  /// 只更新已用流量（提醒不受影響，不用重排）。
  Future<void> updateUsed(double usedGb) async {
    final current = state.value;
    if (current == null) return;
    await _persist(current.copyWith(usedGb: usedGb));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await ref.read(reminderServiceProvider).cancelAll();
    state = const AsyncData(null);
  }
}
