import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('override in main()');
});

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _key = 'parkping.settings';

  @override
  AppSettings build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _save(AppSettings s) async {
    state = s;
    await ref.read(sharedPrefsProvider).setString(_key, jsonEncode(s.toJson()));
  }

  Future<void> setMonitoring(bool on) =>
      _save(state.copyWith(monitoringEnabled: on));

  Future<void> setSmsNumber(String v) => _save(state.copyWith(smsNumber: v));

  Future<void> setSmsTemplate(String v) =>
      _save(state.copyWith(smsTemplate: v));

  Future<void> setSnoozeMinutes(int m) =>
      _save(state.copyWith(snoozeMinutes: m));

  Future<void> rememberAreaCode(String code) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return;
    final next = [
      cleaned,
      ...state.lastAreaCodes.where((c) => c != cleaned),
    ].take(5).toList();
    await _save(state.copyWith(lastAreaCodes: next));
  }
}
