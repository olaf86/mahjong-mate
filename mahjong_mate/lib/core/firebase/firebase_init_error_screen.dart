import 'package:flutter/material.dart';

class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase 初期化エラー')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase の設定が完了していません。',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Firebase プロジェクトを作成し、Android と iOS の設定ファイルを追加してください。',
            ),
            const SizedBox(height: 12),
            Text(
              'エラー詳細: $error',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
