import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'landing_page.dart' show LandingPage, DevicePathBox;
import 'models.dart';
import 'providers.dart';

/// 外層只負責「載入流程資料」，載入好之後交給 _TroubleshootBody
class TroubleshootPage extends ConsumerWidget {
  const TroubleshootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowAsync = ref.watch(troubleshootProvider);
    const title = Text('沒有網路？一起排查');

    return flowAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: title),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: title),
        body: Center(child: Text('讀取排查流程失敗：$error')),
      ),
      data: (flow) => _TroubleshootBody(flow: flow),
    );
  }
}

/// 「目前走到哪一題」只有這個畫面自己需要知道，離開畫面就不用記，
/// 所以放在 State 裡（暫時性的畫面狀態），不放進 Riverpod。
class _TroubleshootBody extends ConsumerStatefulWidget {
  const _TroubleshootBody({required this.flow});

  final TroubleFlow flow;

  @override
  ConsumerState<_TroubleshootBody> createState() => _TroubleshootBodyState();
}

class _TroubleshootBodyState extends ConsumerState<_TroubleshootBody> {
  /// 走過的節點 id，最後一個就是現在這一題；按「上一題」就是把最後一個拿掉
  late final List<String> _path = [widget.flow.start];

  TroubleNode get _node => widget.flow.nodes[_path.last]!;

  void _goTo(String id) => setState(() => _path.add(id));

  void _back() {
    if (_path.length > 1) {
      setState(() => _path.removeLast());
    }
  }

  void _restart() {
    setState(() {
      _path
        ..clear()
        ..add(widget.flow.start);
    });
  }

  Widget _wide(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(width: double.infinity, child: child),
      );

  List<Widget> _buildActions(TroubleNode node) {
    final widgets = <Widget>[];

    if (node.action == 'landing') {
      widgets.add(
        _wide(
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LandingPage()),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('打開落地後三步驟'),
          ),
        ),
      );
    }

    for (var i = 0; i < node.options.length; i++) {
      final option = node.options[i];
      void onPressed() => _goTo(option.next);
      final label = Text(option.label);

      final Widget button;
      if (node.kind == TroubleKind.question) {
        button = FilledButton.tonal(onPressed: onPressed, child: label);
      } else {
        // 「試完了」這類第一個選項是主要按鈕
        button = i == 0
            ? FilledButton(onPressed: onPressed, child: label)
            : OutlinedButton(onPressed: onPressed, child: label);
      }
      widgets.add(_wide(button));
    }

    if (node.kind == TroubleKind.done || node.kind == TroubleKind.support) {
      widgets.add(
        _wide(
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('回首頁'),
          ),
        ),
      );
      widgets.add(
        _wide(OutlinedButton(onPressed: _restart, child: const Text('重新排查'))),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;
    final device = ref.watch(currentDeviceProvider);

    // PopScope：在第一題以外的地方按返回，是回到「上一題」，而不是離開整個頁面
    return PopScope(
      canPop: _path.length == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('沒有網路？一起排查'),
          actions: [
            IconButton(
              tooltip: '重新排查',
              icon: const Icon(Icons.restart_alt),
              onPressed: _restart,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_path.length > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('上一題'),
                ),
              ),
            _NodeCard(node: node),
            const SizedBox(height: 16),
            if (device != null)
              DevicePathBox(device: device, pathKey: node.pathKey),
            ..._buildActions(node),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.node});

  final TroubleNode node;

  IconData get _icon {
    switch (node.kind) {
      case TroubleKind.question:
        return Icons.help_outline;
      case TroubleKind.fix:
        return Icons.build_outlined;
      case TroubleKind.done:
        return Icons.check_circle_outline;
      case TroubleKind.support:
        return Icons.support_agent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? cardColor;
    if (node.kind == TroubleKind.done) {
      cardColor = theme.colorScheme.tertiaryContainer;
    } else if (node.kind == TroubleKind.support) {
      cardColor = theme.colorScheme.secondaryContainer;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(node.title, style: theme.textTheme.titleLarge),
            if (node.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(node.text, style: theme.textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
