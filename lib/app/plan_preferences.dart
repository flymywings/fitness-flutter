import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/models.dart';
import 'providers.dart';

const defaultPlanIsPublic = true;

final defaultPlanPublicProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return defaultPlanIsPublic;
  try {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_visibilityKey(user)) ?? defaultPlanIsPublic;
  } on MissingPluginException {
    return defaultPlanIsPublic;
  } on PlatformException {
    return defaultPlanIsPublic;
  }
});

Future<void> setDefaultPlanPublic(String userId, bool value) async {
  final preferences = await SharedPreferences.getInstance();
  final saved = await preferences.setBool(_visibilityKey(userId), value);
  if (!saved) throw AppException('Could not save your preference. Try again.');
}

String _visibilityKey(String userId) => 'pace.defaultPlanPublic.$userId';
