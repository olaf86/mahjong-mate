import 'rule_category.dart';

class RuleItem {
  const RuleItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.priority = 0,
  });

  final String id;
  final RuleCategory category;
  final String title;
  final String description;
  final int priority;
}
