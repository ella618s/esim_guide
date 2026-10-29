import 'package:flutter/material.dart';

import 'models.dart';

IconData iconFor(String name) {
  switch (name) {
    case 'phone':
      return Icons.phone_iphone;
    case 'wifi':
      return Icons.wifi;
    case 'qr':
      return Icons.qr_code_scanner;
    case 'label':
      return Icons.label_outline;
    case 'block':
      return Icons.pause_circle_outline;
    case 'check':
      return Icons.check_circle_outline;
    default:
      return Icons.help_outline;
  }
}

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final PageController _controller = PageController();
  late final Future<List<GuideStep>> _stepsFuture = loadSteps();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int target) {
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('出發前：安裝 eSIM')),
      body: FutureBuilder<List<GuideStep>>(
        future: _stepsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('讀取教學失敗：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final steps = snapshot.data!;
          final isLast = _index == steps.length - 1;

          return Column(
            children: [
              LinearProgressIndicator(value: (_index + 1) / steps.length),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '第 ${_index + 1} 步，共 ${steps.length} 步',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => StepCard(step: steps[i]),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _index == 0 ? null : () => _go(_index - 1),
                          child: const Text('上一步'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: isLast
                              ? () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('準備完成，旅途愉快！')),
                                  )
                              : () => _go(_index + 1),
                          child: Text(isLast ? '完成' : '下一步'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.step});

  final GuideStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconFor(step.icon), size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(step.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(step.body, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(step.tip)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
