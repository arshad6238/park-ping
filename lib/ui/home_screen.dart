import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/monitor_controller.dart';
import '../core/settings_controller.dart';
import 'parking_sheet.dart';
import 'settings_screen.dart';
import 'theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(monitorProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen(monitorProvider, (prev, next) {
      if (next.showPrompt && !(prev?.showPrompt ?? false)) {
        showParkingPromptSheet(context, ref);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParkPing', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _StatusHero(snap: snap),
            const SizedBox(height: 18),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                title: const Text('Monitoring', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  settings.monitoringEnabled
                      ? 'Location on — detects drive → stop'
                      : 'Off to save battery (e.g. traveling abroad)',
                  style: const TextStyle(color: PP.muted, fontSize: 13),
                ),
                value: settings.monitoringEnabled,
                onChanged: (v) => ref.read(monitorProvider.notifier).setMonitoring(v),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last event', style: TextStyle(color: PP.muted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      snap.lastEvent ?? 'No trips yet',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 18, color: PP.muted),
                        const SizedBox(width: 8),
                        Text(
                          'Speed ${(snap.speedMps * 3.6).toStringAsFixed(0)} km/h',
                          style: const TextStyle(color: PP.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!snap.permissionOk && settings.monitoringEnabled)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_off, color: PP.warn),
                  title: const Text('Permissions needed'),
                  subtitle: const Text('Allow Location (Always) and Notifications'),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(monitorProvider.notifier).requestPermissions(),
                    child: const Text('Fix'),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => ref.read(monitorProvider.notifier).simulateArrival(),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Test parking prompt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PP.text,
                side: const BorderSide(color: PP.card),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tip: keep Monitoring on while driving. Turn it off on flights or holidays to save battery.',
              style: TextStyle(color: PP.muted, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.snap});
  final MonitorSnapshot snap;

  Color get _color => switch (snap.phase) {
        TripPhase.traveling => PP.warn,
        TripPhase.arrived || TripPhase.prompted => PP.accent,
        TripPhase.idle => snap.monitoringEnabled ? PP.accent : PP.muted,
      };

  IconData get _icon => switch (snap.phase) {
        TripPhase.traveling => Icons.directions_car_filled,
        TripPhase.arrived || TripPhase.prompted => Icons.local_parking,
        TripPhase.idle => snap.monitoringEnabled ? Icons.radar : Icons.power_settings_new,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _color.withValues(alpha: 0.25),
            PP.card,
          ],
        ),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(_icon, size: 52, color: _color),
          const SizedBox(height: 14),
          Text(
            snap.statusLine,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            snap.monitoringEnabled
                ? 'Drive → stop → we’ll ask about parking'
                : 'Enable Monitoring when you’re back home',
            textAlign: TextAlign.center,
            style: const TextStyle(color: PP.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}
