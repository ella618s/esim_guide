import 'package:flutter/material.dart';

import 'guide_page.dart';
import 'models.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, required this.country, required this.days});

  final String country;
  final int days;

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late final Future<List<EsimPlan>> _plansFuture = loadPlans();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.country} ${widget.days} 天')),
      body: FutureBuilder<List<EsimPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('讀取方案失敗：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = recommendPlans(
            snapshot.data!,
            widget.country,
            widget.days,
          );

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
