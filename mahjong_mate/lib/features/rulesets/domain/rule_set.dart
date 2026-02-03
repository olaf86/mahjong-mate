import 'rule_item.dart';

class RuleSet {
  const RuleSet({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerName,
    required this.items,
    this.shareCode,
    this.isPublic = false,
  });

  final String id;
  final String name;
  final String description;
  final String ownerName;
  final List<RuleItem> items;
  final String? shareCode;
  final bool isPublic;
}
