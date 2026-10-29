import 'package:flutter/material.dart';

import 'home_page.dart';

void main() => runApp(const EsimGuideApp());

class EsimGuideApp extends StatelessWidget {
  const EsimGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eSIM 小幫手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
