import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings_controller.dart';
import 'theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _number;
  late final TextEditingController _template;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _number = TextEditingController(text: s.smsNumber);
    _template = TextEditingController(text: s.smsTemplate);
  }

  @override
  void dispose() {
    _number.dispose();
    _template.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Battery / travel', style: _h),
          Card(
            child: SwitchListTile(
              title: const Text('Monitoring'),
              subtitle: const Text(
                'Uses location to detect trips. Turn off abroad to save battery.',
              ),
              value: s.monitoringEnabled,
              onChanged: n.setMonitoring,
            ),
          ),
          const SizedBox(height: 22),
          const Text('Parking SMS', style: _h),
          const SizedBox(height: 8),
          const Text(
            'Put parking opens Messages with this number and message as typed.',
            style: TextStyle(color: PP.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _number,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'SMS number / short code',
              filled: true,
              fillColor: PP.card,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onChanged: n.setSmsNumber,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _template,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Exact text to open in Messages',
              filled: true,
              fillColor: PP.card,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onChanged: n.setSmsTemplate,
          ),
          const SizedBox(height: 22),
          const Text('Timing', style: _h),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Snooze'),
                  subtitle: Text('${s.snoozeMinutes} minutes'),
                  trailing: DropdownButton<int>(
                    value: s.snoozeMinutes,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 15, child: Text('15')),
                    ],
                    onChanged: (v) {
                      if (v != null) n.setSnoozeMinutes(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _h = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: PP.muted,
  letterSpacing: 0.4,
);
