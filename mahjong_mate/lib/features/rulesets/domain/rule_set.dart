import 'rule_item.dart';
import 'rule_set_visibility.dart';

class RuleSet {
  const RuleSet({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerName,
    required this.items,
    this.shareCode,
    this.visibility = RuleSetVisibility.private,
    this.ownerDeviceId,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String ownerName;
  final List<RuleItem> items;
  final String? shareCode;
  final RuleSetVisibility visibility;
  final String? ownerDeviceId;
  final DateTime? updatedAt;

  bool get isPublic => visibility == RuleSetVisibility.public;
}
