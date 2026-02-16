import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/auth/auth_user_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with WidgetsBindingObserver {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('認証'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            user == null
                ? 'ログイン状態を確認中です。'
                : user.isAnonymous
                    ? '未登録'
                    : user.emailVerified
                        ? 'ログイン中: ${user.email ?? 'メール未設定'}'
                        : '未認証: ${user.email ?? 'メール未設定'}',
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
                  onPressed: _authBusy ? null : () => _registerAccount(context, auth, user),
                  child: const Text('登録する'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _authBusy ? null : () => _signIn(context, auth, user),
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
            if (!user.emailVerified) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Colors.deepOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'メールアドレスが未認証です。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _authBusy ? null : () => _sendVerification(context, auth),
                child: const Text('認証メールを再送'),
              ),
            ],
            TextButton(
              onPressed: _authBusy ? null : () => _signOut(context, auth),
              child: const Text('ログアウト'),
            ),
          ],
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
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

  Future<void> _sendVerification(BuildContext context, FirebaseAuth auth) async {
    final user = auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
      _showSnack(context, '認証メールを送信しました。');
    } on FirebaseAuthException catch (error) {
      _showSnack(context, _authErrorMessage(error));
    }
  }

  Future<void> _promptUnverified(BuildContext context, FirebaseAuth auth) async {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
