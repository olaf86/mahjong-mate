import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/auth/auth_user_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _authBusy = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAuthState(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAuthState(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final isAnonymousSession = user?.isAnonymous ?? false;
    final canUseCredentialAuth = user == null || isAnonymousSession;
    final canDeleteAccount = user != null && !isAnonymousSession;

    return Scaffold(
      appBar: AppBar(title: const Text('認証')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('現在の認証状態', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _authStatusLabel(user),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (isAnonymousSession) ...[
                    const SizedBox(height: 8),
                    Text(
                      '匿名ログイン中でもルールセットの作成・フォローは可能です。'
                      'ただし、アプリのアンインストールや端末変更時にはデータが消える可能性があります。',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canUseCredentialAuth) ...[
            const SizedBox(height: 16),
            Text('アカウント登録 / ログイン', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
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
                    onPressed: _authBusy
                        ? null
                        : () => _signIn(context, auth, user),
                    child: const Text('ログイン'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '登録はこの端末の匿名データを引き継ぐ操作です。'
              '既存アカウントに切り替える場合はログインを利用してください。',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (user != null && !isAnonymousSession) ...[
            const SizedBox(height: 16),
            Text('ログイン中の操作', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _authBusy ? null : () => _signOut(context, auth),
              child: const Text('ログアウト'),
            ),
          ],
          const SizedBox(height: 24),
          Text('アカウント削除', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canDeleteAccount
                        ? '登録済みアカウントを削除します。削除後は復元できません。'
                        : '未登録（匿名）状態では削除操作は不要です。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: _authBusy || !canDeleteAccount
                        ? null
                        : () => _confirmAndDeleteAccount(context, auth),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('アカウントを削除'),
                  ),
                ],
              ),
            ),
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
      await _sendVerification(context, auth);
      await auth.currentUser?.reload();
      _showSnack(context, 'アカウントを登録しました。認証メールをご確認ください。');
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
      await auth.signInWithEmailAndPassword(email: email, password: password);
      final current = auth.currentUser;
      if (current != null && !current.emailVerified) {
        await _promptUnverified(context, auth);
        _showSnack(context, 'ログインしました（未認証）。');
      } else {
        _showSnack(context, 'ログインしました。');
      }
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
      await auth.signInAnonymously();
      _showSnack(context, 'ログアウトしました。');
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Future<void> _confirmAndDeleteAccount(
    BuildContext context,
    FirebaseAuth auth,
  ) async {
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = confirmController.text.trim() == '削除する';
            return AlertDialog(
              title: const Text('アカウント削除の確認'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'アカウントを削除します。作成したルールセットやフォロー中のルールセットなどが全てクリアされますが、本当によろしいでしょうか？',
                  ),
                  const SizedBox(height: 12),
                  const Text('確認のため「削除する」と入力してください。'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '削除する',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: canDelete
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: const Text('削除する'),
                ),
              ],
            );
          },
        );
      },
    );
    confirmController.dispose();

    if (confirmed != true) return;
    await _deleteAccount(context, auth);
  }

  Future<void> _deleteAccount(BuildContext context, FirebaseAuth auth) async {
    setState(() => _authBusy = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteAccountData',
      );
      await callable.call();
      await auth.signInAnonymously();
      _showSnack(context, 'アカウントを削除しました。');
      if (mounted) {
        setState(() {});
      }
    } on FirebaseFunctionsException catch (error) {
      _showSnack(context, _accountDeleteFunctionErrorMessage(error));
    } on FirebaseAuthException catch (error) {
      _showSnack(context, _accountDeleteErrorMessage(error));
    } catch (error) {
      _showSnack(context, 'アカウント削除に失敗しました: $error');
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Future<void> _refreshAuthState({bool silent = false}) async {
    setState(() => _authBusy = true);
    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.currentUser?.reload();
      if (!silent && mounted) {
        _showSnack(context, '認証状態を更新しました。');
      }
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Future<void> _sendVerification(
    BuildContext context,
    FirebaseAuth auth,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
      _showSnack(context, '認証メールを送信しました。');
    } on FirebaseAuthException catch (error) {
      _showSnack(context, _authErrorMessage(error));
    }
  }

  Future<void> _promptUnverified(
    BuildContext context,
    FirebaseAuth auth,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('メールアドレス未認証'),
          content: const Text('ログインは完了していますが、メールアドレスの認証が必要です。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('後で'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _sendVerification(context, auth);
              },
              child: const Text('認証メールを送信'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _authStatusLabel(User? user) {
    if (user == null) {
      return 'ログイン状態を確認中です。';
    }
    if (user.isAnonymous) {
      return '匿名ログイン中';
    }
    if (user.emailVerified) {
      return 'メールアカウントでログイン中: ${user.email ?? 'メール未設定'}';
    }
    return 'メールアカウント未認証: ${user.email ?? 'メール未設定'}';
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'operation-not-allowed':
        return 'この認証方法は現在無効です。';
      case 'weak-password':
        return 'パスワードが弱すぎます。';
      case 'too-many-requests':
        return '試行回数が多すぎます。しばらく待ってからお試しください。';
      case 'wrong-password':
        return 'パスワードが正しくありません。';
      case 'user-not-found':
        return 'アカウントが見つかりません。';
      default:
        return '認証に失敗しました: ${error.message ?? error.code}';
    }
  }

  String _accountDeleteErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return '再ログイン後にもう一度お試しください。';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました。接続を確認して再試行してください。';
      default:
        return 'アカウント削除に失敗しました: ${error.message ?? error.code}';
    }
  }

  String _accountDeleteFunctionErrorMessage(FirebaseFunctionsException error) {
    final code = error.code.toLowerCase();
    if (code.contains('unauthenticated')) {
      return '認証状態を確認できません。再ログイン後にお試しください。';
    }
    if (code.contains('permission-denied')) {
      return '削除権限がありません。';
    }
    return 'アカウント削除に失敗しました: ${error.message ?? error.code}';
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
