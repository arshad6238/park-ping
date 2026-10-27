import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models.dart';
import 'core/monitor_controller.dart';
import 'core/notifications.dart';
import 'core/settings_controller.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = ParkNotifications();
  await notifications.init();

  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      notificationsProvider.overrideWithValue(notifications),
    ],
  );

  notifications.onAction = (action) {
    final monitor = container.read(monitorProvider.notifier);
    switch (action) {
      case ParkNotifications.paidId:
        monitor.handleChoice(PromptChoice.paid);
      case ParkNotifications.passengerId:
        monitor.handleChoice(PromptChoice.passenger);
      case ParkNotifications.snoozeId:
        monitor.handleChoice(PromptChoice.snooze);
      case ParkNotifications.notParkingId:
        monitor.handleChoice(PromptChoice.notParking);
      default:
        break;
    }
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ParkPingApp(),
    ),
  );
}

class ParkPingApp extends StatelessWidget {
  const ParkPingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkPing',
      debugShowCheckedModeBanner: false,
      theme: buildParkTheme(),
      home: const _Boot(),
    );
  }
}

class _Boot extends ConsumerStatefulWidget {
  const _Boot();

  @override
  ConsumerState<_Boot> createState() => _BootState();
}

class _BootState extends ConsumerState<_Boot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monitorProvider.notifier).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
