import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _autoFollowKey = 'auto_follow_on_share';
const bool autoFollowDefaultValue = true;

final autoFollowProvider = AsyncNotifierProvider<AutoFollowNotifier, bool>(
  AutoFollowNotifier.new,
);

class AutoFollowNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoFollowKey) ?? autoFollowDefaultValue;
  }

  Future<void> setAutoFollow(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoFollowKey, value);
    state = AsyncData(value);
  }
}
