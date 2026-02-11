import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _deviceIdKey = 'device_id';

final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_deviceIdKey);
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }

  final generated = const Uuid().v4();
  await prefs.setString(_deviceIdKey, generated);
  return generated;
});
