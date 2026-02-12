import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/profile/owner_name_provider.dart';

class OwnerNameSettingsScreen extends ConsumerStatefulWidget {
  const OwnerNameSettingsScreen({super.key});

  @override
  ConsumerState<OwnerNameSettingsScreen> createState() => _OwnerNameSettingsScreenState();
}

class _OwnerNameSettingsScreenState extends ConsumerState<OwnerNameSettingsScreen> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerNameAsync = ref.watch(ownerNameProvider);
    ownerNameAsync.whenData((value) {
      if (!_initialized) {
        _initialized = true;
        _controller.text = value;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('オーナー名の設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'ルールセット作成時に使用する表示名を設定します。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'オーナー名',
              helperText: '空欄の場合は「あなた」になります。',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref.read(ownerNameProvider.notifier).setOwnerName(_controller.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('オーナー名を保存しました。')),
              );
            },
            child: const Text('保存する'),
          ),
        ],
      ),
    );
  }
}
