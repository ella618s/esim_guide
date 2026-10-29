import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guide_page.dart';
import 'models.dart';
import 'providers.dart';
import 'recommend_page.dart';

/// 現在不需要 StatefulWidget 了：狀態放在 tripProvider，畫面只負責「顯示」和「通知改變」
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // watch：資料一變，這個畫面就會自動重畫
    final trip = ref.watch(tripProvider);
    // read(...notifier)：只是要呼叫方法，不需要因為它重畫
    final tripNotifier = ref.read(tripProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('eSIM 小幫手')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('你要去哪裡？', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final country in supportedCountries)
                ChoiceChip(
                  label: Text(country),
                  selected: country == trip.country,
                  onSelected: (_) => tripNotifier.setCountry(country),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Text('要去幾天？', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed:
                    trip.days > 1 ? () => tripNotifier.changeDays(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child:
                    Text('${trip.days} 天', style: theme.textTheme.headlineMedium),
              ),
              IconButton.filledTonal(
                onPressed:
                    trip.days < 30 ? () => tripNotifier.changeDays(1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RecommendPage()),
            ),
            child: const Text('看推薦方案'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GuidePage()),
            ),
            child: const Text('先看 eSIM 安裝教學'),
          ),
        ],
      ),
    );
  }
}
