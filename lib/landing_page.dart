import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guide_page.dart' show iconFor;
import 'models.dart';
import 'providers.dart';
import 'troubleshoot_page.dart';

/// 落地後：三步驟開啟網路。每完成一步就勾起來，進度會被記住。
/// 選擇的手機機型不同，每一步會顯示對應的設定路徑。
class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = ref.watch(landingDoneProvider);
    final stepsAsync = ref.watch(landingStepsProvider);
    final profilesAsync = ref.watch(deviceProfilesProvider);
    final device = ref.watch(currentDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('落地了！開啟網路'),
        actions: [
          IconButton(
            tooltip: '重新開始',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => ref.read(landingDoneProvider.notifier).reset(),
          ),
        ],
      ),
      body: stepsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('讀取步驟失敗：$error')),
        data: (allSteps) {
          if (profilesAsync.hasError) {
            return Center(child: Text('讀取機型資料失敗：${profilesAsync.error}'));
          }
          if (device == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = profilesAsync.requireValue;
          final steps = allSteps[device.os] ?? const <GuideStep>[];
          final doneCount = done.where((i) => i < steps.length).length;
          final allDone = steps.isNotEmpty && doneCount == steps.length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('你的手機是？', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final profile in profiles)
                    ChoiceChip(
                      label: Text(profile.name),
                      selected: profile.id == device.id,
                      onSelected: (_) => ref
                          .read(selectedDeviceIdProvider.notifier)
                          .set(profile.id),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('依序完成這三步，就能上網了', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: steps.isEmpty ? 0 : doneCount / steps.length,
              ),
              const SizedBox(height: 4),
              Text('已完成 $doneCount / ${steps.length}',
                  style: theme.textTheme.labelMedium),
              const SizedBox(height: 16),
              for (var i = 0; i < steps.length; i++)
                _LandingStepCard(
                  number: i + 1,
                  step: steps[i],
                  device: device,
                  done: done.contains(i),
                  onChanged: (value) =>
                      ref.read(landingDoneProvider.notifier).setDone(i, value),
                ),
              if (allDone) ...[
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.celebration_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('三步都完成了！如果還是沒有網路，先把手機重新開機試試看。'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TroubleshootPage(),
                  ),
                ),
                child: const Text('還是沒有網路？一起排查'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 顯示「在哪裡操作」的路徑。給落地頁和排查頁共用。
/// 這個機型沒有這個路徑時，不顯示任何東西。
class DevicePathBox extends StatelessWidget {
  const DevicePathBox({super.key, required this.device, required this.pathKey});

  final DeviceProfile device;
  final String? pathKey;

  @override
  Widget build(BuildContext context) {
    final path = pathKey == null ? null : device.paths[pathKey];
    if (path == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined, size: 18),
                const SizedBox(width: 6),
                Text('${device.name} 的路徑', style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 6),
            Text(path, style: theme.textTheme.bodyLarge),
            if (!device.verified) ...[
              const SizedBox(height: 6),
              Text(
                '※ 依一般情況整理，系統版本不同時，名稱可能略有差異。',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LandingStepCard extends StatelessWidget {
  const _LandingStepCard({
    required this.number,
    required this.step,
    required this.device,
    required this.done,
    required this.onChanged,
  });

  final int number;
  final GuideStep step;
  final DeviceProfile device;
  final bool done;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: done ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('$number')),
                const SizedBox(width: 12),
                Icon(iconFor(step.icon), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(step.title, style: theme.textTheme.titleMedium),
                ),
                Checkbox(
                  value: done,
                  onChanged: (value) => onChanged(value ?? false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(step.body),
            const SizedBox(height: 12),
            DevicePathBox(device: device, pathKey: step.pathKey),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(step.tip)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
