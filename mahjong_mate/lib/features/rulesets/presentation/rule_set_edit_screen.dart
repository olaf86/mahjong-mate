import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../application/rule_sets_provider.dart';
import '../domain/rule_category.dart';
import '../domain/rule_item.dart';
import '../domain/rule_set.dart';
import '../domain/rule_set_visibility.dart';
import '../data/rule_set_repository.dart';
import '../../../shared/device/device_id_provider.dart';

class RuleSetEditScreen extends ConsumerStatefulWidget {
  const RuleSetEditScreen({super.key, this.ruleSetId});

  final String? ruleSetId;

  @override
  ConsumerState<RuleSetEditScreen> createState() => _RuleSetEditScreenState();
}

class _RuleSetEditScreenState extends ConsumerState<RuleSetEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _descriptionController;
  bool _initialized = false;
  bool _saving = false;
  RuleSetVisibility _visibility = RuleSetVisibility.private;
  final Map<RuleCategory, List<_EditableRuleItem>> _itemsByCategory = {};
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
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
      _ownerNameController.text = ruleSet.ownerName;
      _descriptionController.text = ruleSet.description;
      _visibility = ruleSet.visibility;
      _itemsByCategory.clear();
      for (final item in ruleSet.items) {
        _itemsByCategory.putIfAbsent(item.category, () => []).add(
          _EditableRuleItem(
            id: item.id,
            category: item.category,
            title: item.title,
            description: item.description,
            priority: item.priority,
          ),
        );
      }
      if (mounted) {
        setState(() {});
      }
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
            return _buildForm(
              context,
              ruleSetId == null ? 'ルールセット作成' : 'ルールセット編集',
              ruleSet,
            );
          },
        ) ??
        _buildForm(context, 'ルールセット作成', null);
  }

  Widget _buildForm(BuildContext context, String title, RuleSet? ruleSet) {
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
            controller: _ownerNameController,
            decoration: const InputDecoration(labelText: 'オーナー名'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '説明'),
          ),
          const SizedBox(height: 20),
          Text('公開設定', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('公開する'),
              subtitle: Text(
                _visibility == RuleSetVisibility.public
                    ? '共有コードが発行され、\n誰でも閲覧できます。'
                    : '自分の端末だけが閲覧できます。\n',
                maxLines: 2,
              ),
              value: _visibility == RuleSetVisibility.public,
              onChanged: (value) {
                setState(() {
                  _visibility = value ? RuleSetVisibility.public : RuleSetVisibility.private;
                });
              },
            ),
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
                    if (_itemsFor(category).isEmpty)
                      Text(
                        'このカテゴリのルールを追加してください。',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      ..._itemsFor(category).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RuleItemTile(
                            title: item.title,
                            description: item.description,
                            onDelete: () => _removeRuleItem(category, item),
                            onEdit: () => _showRuleItemDialog(
                              context,
                              category,
                              existing: item,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRuleItemDialog(context, category),
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
            onPressed: _saving ? null : () => _save(ruleSet),
            child: Text(_saving ? '保存中...' : '保存する'),
          ),
        ],
      ),
    );
  }

  List<_EditableRuleItem> _itemsFor(RuleCategory category) {
    return _itemsByCategory[category] ?? const [];
  }

  void _removeRuleItem(RuleCategory category, _EditableRuleItem item) {
    setState(() {
      _itemsByCategory[category]?.removeWhere((entry) => entry.id == item.id);
    });
  }

  Future<void> _showRuleItemDialog(
    BuildContext context,
    RuleCategory category, {
    _EditableRuleItem? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    final result = await showDialog<_EditableRuleItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'ルールを追加' : 'ルールを編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'ルール名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '説明'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(
                _EditableRuleItem(
                  id: existing?.id ?? _uuid.v4(),
                  category: category,
                  title: title,
                  description: description,
                  priority: existing?.priority ?? 0,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == null) return;
    setState(() {
      final list = _itemsByCategory.putIfAbsent(category, () => []);
      final index = list.indexWhere((entry) => entry.id == result.id);
      if (index == -1) {
        list.add(result);
      } else {
        list[index] = result;
      }
    });
  }

  Future<void> _save(RuleSet? ruleSet) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルールセット名を入力してください。')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final ownerName = _ownerNameController.text.trim().isEmpty
          ? 'あなた'
          : _ownerNameController.text.trim();
      final deviceId = await ref.read(deviceIdProvider.future);
      final repository = ref.read(ruleSetRepositoryProvider);
      final items = _itemsByCategory.values.expand((list) => list).map((item) {
        return RuleItem(
          id: item.id,
          category: item.category,
          title: item.title,
          description: item.description,
          priority: item.priority,
        );
      }).toList();

      if (ruleSet == null) {
        final created = await repository.createRuleSet(
          name: name,
          description: description,
          ownerName: ownerName,
          ownerDeviceId: deviceId,
          visibility: _visibility,
          items: items,
        );
        if (!mounted) return;
        context.goNamed(
          'ruleset-detail',
          pathParameters: {'id': created.id},
        );
      } else {
        await repository.updateRuleSet(
          id: ruleSet.id,
          name: name,
          description: description,
          ownerName: ownerName,
          ownerDeviceId: ruleSet.ownerDeviceId ?? deviceId,
          visibility: _visibility,
          items: items,
          shareCode: ruleSet.shareCode,
        );
        if (!mounted) return;
        context.goNamed(
          'ruleset-detail',
          pathParameters: {'id': ruleSet.id},
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _EditableRuleItem {
  _EditableRuleItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
  });

  final String id;
  final RuleCategory category;
  final String title;
  final String description;
  final int priority;
}

class _RuleItemTile extends StatelessWidget {
  const _RuleItemTile({
    required this.title,
    required this.description,
    required this.onDelete,
    required this.onEdit,
  });

  final String title;
  final String description;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(title),
        subtitle: description.isEmpty ? null : Text(description),
        onTap: onEdit,
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: '削除',
        ),
      ),
    );
  }
}
