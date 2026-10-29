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
