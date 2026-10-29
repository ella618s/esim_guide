import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guide_page.dart';
import 'models.dart';
import 'providers.dart';

/// 不再需要從上一頁傳參數：直接讀 tripProvider 就知道使用者選了什麼
class RecommendPage extends ConsumerWidget {
  const RecommendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trip = ref.watch(tripProvider);
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${trip.country} ${trip.days} 天')),
      // AsyncValue.when：把「載入中／失敗／成功」三種狀態分開處理，
      // 取代之前的 FutureBuilder
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('讀取方案失敗：$error')),
        data: (allPlans) {
          final plans = recommendPlans(allPlans, trip.country, trip.days);

          if (plans.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('目前沒有涵蓋這麼多天的方案，請減少天數試試看。'),
              ),
            );
          }

          final best = plans.first;
          final others = plans.skip(1).take(2).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('最適合你的方案', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              PlanCard(plan: best, highlighted: true),
              if (others.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('其他選擇', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final plan in others) PlanCard(plan: plan),
              ],
              const SizedBox(height: 16),
              Text(
                '※ 目前顯示的是範例資料，不是真實的方案與價格。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const GuidePage()),
                ),
                child: const Text('看安裝教學'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, this.highlighted = false});

  final EsimPlan plan;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: highlighted ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.days} 天・${plan.dataLabel}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(plan.usageHint),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('NT\$ ${plan.priceTwd}', style: theme.textTheme.titleMedium),
                const Spacer(),
                Icon(
                  plan.hotspot ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(plan.hotspot ? '可開熱點' : '不支援熱點'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
