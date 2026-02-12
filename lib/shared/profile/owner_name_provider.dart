import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _ownerNameKey = 'owner_name';
const String ownerNameDefaultValue = 'あなた';

final ownerNameProvider = AsyncNotifierProvider<OwnerNameNotifier, String>(
  OwnerNameNotifier.new,
);

class OwnerNameNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerNameKey) ?? ownerNameDefaultValue;
  }

  Future<void> setOwnerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim();
    final value = trimmed.isEmpty ? ownerNameDefaultValue : trimmed;
    await prefs.setString(_ownerNameKey, value);
    state = AsyncData(value);
  }
}
