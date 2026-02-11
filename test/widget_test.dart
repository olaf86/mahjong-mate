// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mahjong_mate/features/rulesets/application/rule_sets_provider.dart';
import 'package:mahjong_mate/features/rulesets/domain/rule_set.dart';
import 'package:mahjong_mate/features/rulesets/presentation/rule_set_list_screen.dart';

void main() {
  testWidgets('Rule set list shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleSetsProvider.overrideWith(
            (ref) => Stream<List<RuleSet>>.value(const []),
          ),
        ],
        child: const MaterialApp(home: RuleSetListScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('まだルールセットがありません。'), findsOneWidget);
  });
}
