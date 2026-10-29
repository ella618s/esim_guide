import 'package:flutter/material.dart';

import 'guide_page.dart';
import 'recommend_page.dart';

/// 目前支援的國家（之後可以改成從資料載入）
const supportedCountries = ['日本', '冰島','韓國', '泰國'];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _country = supportedCountries.first;
  int _days = 5;

  void _changeDays(int delta) {
    setState(() {
      _days = (_days + delta).clamp(1, 30).toInt();
    });
  }

  void _openRecommend() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecommendPage(country: _country, days: _days),
      ),
    );
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GuidePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  selected: country == _country,
                  onSelected: (_) => setState(() => _country = country),
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
                onPressed: _days > 1 ? () => _changeDays(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_days 天', style: theme.textTheme.headlineMedium),
              ),
              IconButton.filledTonal(
                onPressed: _days < 30 ? () => _changeDays(1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: _openRecommend,
            child: const Text('看推薦方案'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _openGuide,
            child: const Text('先看 eSIM 安裝教學'),
          ),
        ],
      ),
    );
  }
}
