import 'package:go_router/go_router.dart';

import '../features/rulesets/presentation/rule_set_detail_screen.dart';
import '../features/rulesets/presentation/rule_set_edit_screen.dart';
import '../features/rulesets/presentation/rule_set_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'ruleset-list',
      builder: (context, state) => const RuleSetListScreen(),
      routes: [
        GoRoute(
          path: 'rulesets/new',
          name: 'ruleset-new',
          builder: (context, state) => const RuleSetEditScreen(),
        ),
        GoRoute(
          path: 'rulesets/:id',
          name: 'ruleset-detail',
          builder: (context, state) => RuleSetDetailScreen(
            ruleSetId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'ruleset-edit',
              builder: (context, state) => RuleSetEditScreen(
                ruleSetId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
