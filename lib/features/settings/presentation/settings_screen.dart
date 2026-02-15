import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/profile/auto_follow_provider.dart';
import '../../../shared/profile/owner_name_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final autoFollowAsync = ref.watch(autoFollowProvider);
    ownerNameAsync.whenData((value) {
      if (!_initialized) {
        _initialized = true;
        _controller.text = value;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
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
          autoFollowAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (value) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('共有リンクを開いたら自動でフォローする'),
                subtitle: const Text('共有コード経由で開いたルールセットを自動的に一覧へ追加します。'),
                value: value,
                onChanged: (next) =>
                    ref.read(autoFollowProvider.notifier).setAutoFollow(next),
              );
            },
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
