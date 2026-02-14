import 'package:go_router/go_router.dart';

import '../features/rulesets/presentation/rule_set_detail_screen.dart';
import '../features/rulesets/presentation/rule_set_edit_screen.dart';
import '../features/rulesets/presentation/rule_set_list_screen.dart';
import '../features/rulesets/presentation/rule_set_share_resolver_screen.dart';
import '../features/rulesets/presentation/followed_ruleset_order_screen.dart';
import '../features/settings/presentation/owner_name_settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/r/:code',
      name: 'ruleset-share',
      builder: (context, state) => RuleSetShareResolverScreen(
        shareCode: state.pathParameters['code'] ?? '',
      ),
    ),
    GoRoute(
      path: '/settings/owner',
      name: 'settings-owner',
      builder: (context, state) => const OwnerNameSettingsScreen(),
    ),
    GoRoute(
      path: '/rulesets/followed/order',
      name: 'followed-order',
      builder: (context, state) => const FollowedRuleSetOrderScreen(),
    ),
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
