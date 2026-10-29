import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// 本地儲存（SharedPreferences）。
/// 它要先「非同步」取得，所以在 main() 取好之後，用 overrideWithValue 塞進來。
/// 這裡先丟錯誤，是為了避免忘記在 main() 設定。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('請在 main() 用 overrideWithValue 提供 SharedPreferences');
});

/// 教學步驟與方案：讀過一次就快取起來，不用每個畫面重複讀檔
final stepsProvider = FutureProvider<List<GuideStep>>((ref) => loadSteps());
final plansProvider = FutureProvider<List<EsimPlan>>((ref) => loadPlans());

/// 行程（國家＋天數）：改變時會自動存進本地，下次開 App 還在
class TripNotifier extends Notifier<Trip> {
  static const _countryKey = 'trip_country';
  static const _daysKey = 'trip_days';

  @override
  Trip build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedCountry = prefs.getString(_countryKey);
    final savedDays = prefs.getInt(_daysKey);

    return Trip(
      // 如果存的國家已經不在支援清單裡，就退回第一個
      country: supportedCountries.contains(savedCountry)
          ? savedCountry!
          : supportedCountries.first,
      days: (savedDays ?? 5).clamp(1, 30).toInt(),
    );
  }

  void setCountry(String country) {
    state = state.copyWith(country: country);
    _save();
  }

  void changeDays(int delta) {
    state = state.copyWith(days: (state.days + delta).clamp(1, 30).toInt());
    _save();
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_countryKey, state.country);
    prefs.setInt(_daysKey, state.days);
  }
}

final tripProvider = NotifierProvider<TripNotifier, Trip>(TripNotifier.new);

/// 安裝教學看到第幾步：下次打開會從上次的地方繼續
class GuideIndexNotifier extends Notifier<int> {
  static const _key = 'guide_index';

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 0;

  void set(int index) {
    state = index;
    ref.read(sharedPreferencesProvider).setInt(_key, index);
  }
}

final guideIndexProvider =
    NotifierProvider<GuideIndexNotifier, int>(GuideIndexNotifier.new);

/// 落地後的操作步驟（iPhone／Android 各一份）
final landingStepsProvider =
    FutureProvider<Map<OsKind, List<GuideStep>>>((ref) => loadLandingSteps());

/// 目前顯示哪一個系統的教學。預設依手機自己的系統，使用者也可以手動切換
/// （例如幫爸媽設定時，可以切到對方的手機系統）
class OsKindNotifier extends Notifier<OsKind> {
  @override
  OsKind build() {
    final platform = defaultTargetPlatform;
    // macOS 也算 iOS：在 Mac 上用 Chrome 測試時，預設顯示 iPhone 的步驟
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return isApple ? OsKind.ios : OsKind.android;
  }

  void set(OsKind kind) => state = kind;
}

final osKindProvider =
    NotifierProvider<OsKindNotifier, OsKind>(OsKindNotifier.new);

/// 落地後三步驟：哪些已經勾選完成（存的是步驟編號 0、1、2）
class LandingDoneNotifier extends Notifier<Set<int>> {
  static const _key = 'landing_done';

  @override
  Set<int> build() {
    final saved = ref.watch(sharedPreferencesProvider).getStringList(_key) ??
        const <String>[];
    return saved.map(int.tryParse).whereType<int>().toSet();
  }

  void setDone(int index, bool done) {
    // 不直接修改舊的 Set，而是建立新的，Riverpod 才知道資料變了
    final next = {...state};
    if (done) {
      next.add(index);
    } else {
      next.remove(index);
    }
    _update(next);
  }

  void reset() => _update(<int>{});

  void _update(Set<int> next) {
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setStringList(_key, next.map((e) => e.toString()).toList());
  }
}

final landingDoneProvider =
    NotifierProvider<LandingDoneNotifier, Set<int>>(LandingDoneNotifier.new);
