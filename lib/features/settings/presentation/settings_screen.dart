import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/auth/auth_user_provider.dart';
import '../../../shared/profile/auto_follow_provider.dart';
import '../../../shared/profile/owner_name_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _initialized = false;
  bool _authBusy = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerNameAsync = ref.watch(ownerNameProvider);
    final autoFollowAsync = ref.watch(autoFollowProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
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
          Text('アカウント', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            user == null
                ? 'ログイン状態を確認中です。'
                : user.isAnonymous
                    ? '未登録'
                    : 'ログイン中: ${user.email ?? 'メール未設定'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AutofillGroup(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    helperText: '8文字以上・英大文字/英小文字/数字を含めてください。',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _authBusy
                      ? null
                      : () => _registerAccount(context, auth, user),
                  child: const Text('登録する'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _authBusy ? null : () => _signIn(context, auth, user),
                  child: const Text('ログイン'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '登録はこの端末のデータを引き継ぐための操作です。'
            '既存アカウントに切り替える場合はログインをご利用ください。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (user != null && !user.isAnonymous) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _authBusy ? null : () => _signOut(context, auth),
              child: const Text('ログアウト'),
            ),
          ],
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

  Future<void> _registerAccount(
    BuildContext context,
    FirebaseAuth auth,
    User? user,
  ) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnack(context, 'メールアドレスとパスワードを入力してください。');
      return;
    }
    final validationMessage = _validateRegistrationPassword(password);
    if (validationMessage != null) {
      _showSnack(context, validationMessage);
      return;
    }
    if (user == null || !user.isAnonymous) {
      _showSnack(context, 'この端末のデータを引き継ぐには匿名状態で登録してください。');
      return;
    }
    setState(() => _authBusy = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);
      _showSnack(context, 'アカウントを登録しました。');
      setState(() {});
    } on FirebaseAuthException catch (error) {
      _showSnack(context, _authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Future<void> _signIn(
    BuildContext context,
    FirebaseAuth auth,
    User? user,
  ) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnack(context, 'メールアドレスとパスワードを入力してください。');
      return;
    }
    if (user != null && user.isAnonymous) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('ログインの確認'),
            content: const Text(
              '既存アカウントにログインすると、この端末の未引き継ぎデータは表示されなくなります。続行しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ログイン'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }
    setState(() => _authBusy = true);
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _showSnack(context, 'ログインしました。');
      setState(() {});
    } on FirebaseAuthException catch (error) {
      _showSnack(context, _authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Future<void> _signOut(BuildContext context, FirebaseAuth auth) async {
    setState(() => _authBusy = true);
    try {
      await auth.signOut();
      _showSnack(context, 'ログアウトしました。');
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'weak-password':
        return 'パスワードが弱すぎます。';
      case 'wrong-password':
        return 'パスワードが正しくありません。';
      case 'user-not-found':
        return 'アカウントが見つかりません。';
      default:
        return '認証に失敗しました: ${error.message ?? error.code}';
    }
  }

  String? _validateRegistrationPassword(String password) {
    if (password.length < 8) {
      return 'パスワードは8文字以上で設定してください。';
    }
    final hasUpper = RegExp('[A-Z]').hasMatch(password);
    final hasLower = RegExp('[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    if (!hasUpper || !hasLower || !hasDigit) {
      return 'パスワードは英大文字・英小文字・数字を含めてください。';
    }
    return null;
  }
}
