import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'usage_logic.dart';
import 'usage_providers.dart';

String _gb(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

double? _parseNumber(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(usageProvider);
    final texts = ref.watch(usageTextsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('流量與到期提醒')),
      body: texts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('讀取文案失敗：$e')),
        data: (t) => plan.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('讀取資料失敗：$e')),
          data: (p) => p == null
              ? _EmptyView(texts: t)
              : _PlanView(plan: p, texts: t),
        ),
      ),
    );
  }
}

Future<void> _openForm(
  BuildContext context,
  WidgetRef ref,
  UsageTexts texts,
  EsimUsage? initial,
) async {
  final result = await Navigator.of(context).push<EsimUsage>(
    MaterialPageRoute(builder: (_) => _PlanFormPage(initial: initial)),
  );
  if (result == null || !context.mounted) return;

  final reminder = await ref.read(usageProvider.notifier).savePlan(result);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(texts.resultText(reminder.name))),
  );
}

class _EmptyView extends ConsumerWidget {
  const _EmptyView({required this.texts});

  final UsageTexts texts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sim_card_outlined, size: 56),
            const SizedBox(height: 16),
            const Text('還沒有記錄任何 eSIM 方案'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openForm(context, ref, texts, null),
              icon: const Icon(Icons.add),
              label: const Text('新增方案'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan, required this.texts});

  final EsimUsage plan;
  final UsageTexts texts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final status = plan.status(now);
    final days = status == PlanStatus.notStarted
        ? plan.daysUntilStart(now)
        : plan.daysLeft(now);
    final percent = (plan.usedFraction * 100).round();
    final reminders = plan.reminders(now);

    final warnings = <String>[
      if (plan.isLowData) texts.warning('lowData'),
      if (status == PlanStatus.lastDay) texts.warning('lastDay'),
      if (status == PlanStatus.expired) texts.warning('expired'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.planName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  texts.statusText(status, days),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: plan.usedFraction,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  color: plan.isLowData ? Colors.orange : null,
                ),
                const SizedBox(height: 8),
                Text('已用 ${_gb(plan.usedGb)} / ${_gb(plan.totalGb)} GB（$percent%）'),
                Text('剩下 ${_gb(plan.remainingGb)} GB'),
                const SizedBox(height: 8),
                Text('啟用日 ${ymd(plan.activatedOn)}　最後一天 ${ymd(plan.lastUseDate)}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _updateUsed(context, ref),
                      child: const Text('更新已用流量'),
                    ),
                    OutlinedButton(
                      onPressed: () => _openForm(context, ref, texts, plan),
                      child: const Text('編輯'),
                    ),
                    OutlinedButton(
                      onPressed: () => _confirmDelete(context, ref),
                      child: const Text('刪除'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (final w in warnings)
          Card(
            color: Colors.orange.withValues(alpha: 0.15),
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: Text(w),
            ),
          ),
        const SizedBox(height: 8),
        Text('到期提醒', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (reminders.isEmpty)
          Text(texts.resultText('nothingToSchedule'))
        else
          for (final r in reminders)
            Text('• ${ymd(r.at)} 09:00　${texts.reminder(r.kind, plan.planName).title}'),
        const SizedBox(height: 16),
        Text('注意', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final note in texts.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(note)),
              ],
            ),
          ),
        if (!texts.verified)
          Text('※ 說明文字尚未在實機核對', style: theme.textTheme.bodySmall),
      ],
    );
  }

  Future<void> _updateUsed(BuildContext context, WidgetRef ref) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _UsedDialog(initial: plan.usedGb),
    );
    if (value == null) return;
    await ref.read(usageProvider.notifier).updateUsed(value);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除這個方案？'),
        content: const Text('記錄和到期提醒都會一起刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(usageProvider.notifier).clear();
  }
}

class _UsedDialog extends StatefulWidget {
  const _UsedDialog({required this.initial});

  final double initial;

  @override
  State<_UsedDialog> createState() => _UsedDialogState();
}

class _UsedDialogState extends State<_UsedDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: _gb(widget.initial));
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _parseNumber(_controller.text);
    if (v == null || v < 0) {
      setState(() => _error = '請輸入 0 以上的數字');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新已用流量'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '已用流量（GB）',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('儲存')),
      ],
    );
  }
}

class _PlanFormPage extends StatefulWidget {
  const _PlanFormPage({this.initial});

  final EsimUsage? initial;

  @override
  State<_PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<_PlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _total;
  late final TextEditingController _used;
  late final TextEditingController _days;
  late DateTime _activatedOn;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.planName ?? 'eSIM');
    _total = TextEditingController(text: p == null ? '' : _gb(p.totalGb));
    _used = TextEditingController(text: p == null ? '0' : _gb(p.usedGb));
    _days = TextEditingController(text: p == null ? '' : '${p.validDays}');
    _activatedOn = p?.activatedOn ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _used.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activatedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _activatedOn = dateOnly(picked));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    Navigator.of(context).pop(
      EsimUsage(
        planName: name.isEmpty ? 'eSIM' : name,
        totalGb: _parseNumber(_total.text)!,
        usedGb: _parseNumber(_used.text) ?? 0,
        activatedOn: _activatedOn,
        validDays: int.parse(_days.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '編輯方案' : '新增方案')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '方案名稱（選填）',
                hintText: '例如：日本 7 天 5GB',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _total,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '總流量（GB）'),
              validator: (v) {
                final n = _parseNumber(v ?? '');
                return (n == null || n <= 0) ? '請輸入大於 0 的數字' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _used,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '已用流量（GB）'),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return null;
                final n = _parseNumber(v!);
                return (n == null || n < 0) ? '請輸入 0 以上的數字' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '可用天數'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 1 || n > 365) ? '請輸入 1～365 的整數' : null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('啟用日'),
              subtitle: Text(ymd(_activatedOn)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('儲存並設定提醒')),
          ],
        ),
      ),
    );
  }
}
