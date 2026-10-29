import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'esim_support.dart';
import 'providers.dart';

/// 檢查這支手機支不支援 eSIM。
/// 結果有三種：支援、不支援、無法判斷，每一種告訴使用者「接下來該做什麼」。
class EsimCheckPage extends ConsumerWidget {
  const EsimCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportAsync = ref.watch(esimSupportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的手機支援 eSIM 嗎？'),
        actions: [
          IconButton(
            tooltip: '重新檢查',
            icon: const Icon(Icons.refresh),
            // invalidate：丟掉舊結果，重新問一次原生程式
            onPressed: () => ref.invalidate(esimSupportProvider),
          ),
        ],
      ),
      body: supportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // checkEsimSupport 已經把所有錯誤轉成 unknown，這裡只是保險
        error: (_, __) => const _ResultView(support: EsimSupport.unknown),
        data: (support) => _ResultView(support: support),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.support});

  final EsimSupport support;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    final String title;
    final String body;
    final Color? color;

    switch (support) {
      case EsimSupport.supported:
        icon = Icons.check_circle_outline;
        title = '你的手機支援 eSIM';
        body = '這支手機有 eSIM 的功能，可以安裝旅遊 eSIM。';
        color = theme.colorScheme.tertiaryContainer;
      case EsimSupport.unsupported:
        icon = Icons.cancel_outlined;
        title = '你的手機目前無法使用 eSIM';
        body = '可能是手機沒有 eSIM 晶片，或是 eSIM 功能被電信業者或地區停用了。'
            '這種情況建議改用實體的旅遊 SIM 卡、行動 Wi-Fi 分享器，或是請同行的人開熱點。';
        color = theme.colorScheme.errorContainer;
      case EsimSupport.unknown:
        icon = Icons.help_outline;
        title = '沒辦法自動判斷';
        body = '這個環境（例如網頁版）查不到手機的資訊，請用下面的方法自己確認。';
        color = theme.colorScheme.secondaryContainer;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 48),
                const SizedBox(height: 12),
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(body, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('還要確認一件事：手機有沒有被鎖', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          '「支援 eSIM」不代表一定能用別家電信的 eSIM。如果手機是跟電信公司綁約買的，'
          '可能被鎖住，只能用原本那家電信的卡。這一點 App 沒辦法偵測，請自己確認。',
        ),
        const SizedBox(height: 12),
        const _CheckTip(
          title: 'iPhone',
          text: '到「設定 > 一般 > 關於本機」，找「電信業者鎖定」這一項，'
              '顯示沒有 SIM 卡限制，就代表沒有被鎖。',
        ),
        const _CheckTip(
          title: 'Android',
          text: '各品牌查詢方式不同，最準的方法是直接問你的電信公司客服，'
              '詢問「這支手機有沒有 SIM 鎖」。',
        ),
        const SizedBox(height: 16),
        Text('也可以自己確認有沒有 eSIM', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          '在撥號畫面輸入 *#06#，如果畫面上有 EID 這一項（一長串數字），'
          '通常就代表手機有 eSIM 晶片。',
        ),
      ],
    );
  }
}

class _CheckTip extends StatelessWidget {
  const _CheckTip({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }
}
