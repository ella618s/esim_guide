import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'providers.dart';

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
    case 'power':
      return Icons.power_settings_new;
    case 'roaming':
      return Icons.public;
    case 'sim':
      return Icons.sim_card_outlined;
    default:
      return Icons.help_outline;
  }
}

/// 外層只負責「載入教學內容」，載入好之後交給 _GuideBody
class GuidePage extends ConsumerWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(stepsProvider);
    const title = Text('出發前：安裝 eSIM');

    return stepsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: title),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: title),
        body: Center(child: Text('讀取教學失敗：$error')),
      ),
      data: (steps) {
        if (steps.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: title),
            body: const Center(child: Text('目前沒有教學內容')),
          );
        }
        return _GuideBody(steps: steps);
      },
    );
  }
}

class _GuideBody extends ConsumerStatefulWidget {
  const _GuideBody({required this.steps});

  final List<GuideStep> steps;

  @override
  ConsumerState<_GuideBody> createState() => _GuideBodyState();
}

class _GuideBodyState extends ConsumerState<_GuideBody> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    // 只在一開始讀一次上次看到哪裡（所以用 read，不用 watch）。
    // clamp 是保險：萬一之後教學步驟變少，不會跳到不存在的頁。
    final saved = ref.read(guideIndexProvider);
    _index = saved.clamp(0, widget.steps.length - 1).toInt();
    _controller = PageController(initialPage: _index);
  }

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

  void _onPageChanged(int i) {
    setState(() => _index = i);
    ref.read(guideIndexProvider.notifier).set(i);
  }

  void _finish() {
    // 完成後把進度歸零，下次打開就從第一步開始
    ref.read(guideIndexProvider.notifier).set(0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('準備完成，旅途愉快！')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final isLast = _index == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('出發前：安裝 eSIM'),
        actions: [
          IconButton(
            tooltip: '從頭開始',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _go(0),
          ),
        ],
      ),
      body: Column(
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
              onPageChanged: _onPageChanged,
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
                      onPressed: isLast ? _finish : () => _go(_index + 1),
                      child: Text(isLast ? '完成' : '下一步'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
