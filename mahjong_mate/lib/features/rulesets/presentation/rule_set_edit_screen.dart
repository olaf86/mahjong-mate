import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/rule_sets_provider.dart';
import '../domain/rule_category.dart';

class RuleSetEditScreen extends ConsumerStatefulWidget {
  const RuleSetEditScreen({super.key, this.ruleSetId});

  final String? ruleSetId;

  @override
  ConsumerState<RuleSetEditScreen> createState() => _RuleSetEditScreenState();
}

class _RuleSetEditScreenState extends ConsumerState<RuleSetEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeIfNeeded() {
    if (_initialized) return;
    _initialized = true;
    final ruleSetId = widget.ruleSetId;
    if (ruleSetId == null) return;
    final ruleSetAsync = ref.read(ruleSetByIdProvider(ruleSetId));
    ruleSetAsync.whenData((ruleSet) {
      if (ruleSet == null) return;
      _nameController.text = ruleSet.name;
      _descriptionController.text = ruleSet.description;
    });
  }

  @override
  Widget build(BuildContext context) {
    _initializeIfNeeded();
    final ruleSetId = widget.ruleSetId;
    final ruleSetAsync = ruleSetId == null ? null : ref.watch(ruleSetByIdProvider(ruleSetId));

    return ruleSetAsync?.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('読み込みに失敗しました')),
            body: Center(child: Text(error.toString())),
          ),
          data: (ruleSet) {
            if (ruleSetId != null && ruleSet == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('ルールセットが見つかりません')),
                body: const Center(child: Text('指定されたルールセットは存在しません。')),
              );
            }
            return _buildForm(context, ruleSetId == null ? 'ルールセット作成' : 'ルールセット編集');
          },
        ) ??
        _buildForm(context, 'ルールセット作成');
  }

  Widget _buildForm(BuildContext context, String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ルールセット名'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '説明'),
          ),
          const SizedBox(height: 24),
          Text('カテゴリ別ルール', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...RuleCategory.values.map(
            (category) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'このカテゴリのルールを追加してください。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('ルールを追加'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {},
            child: const Text('保存する'),
          ),
        ],
      ),
    );
  }
}
