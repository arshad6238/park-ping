import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/monitor_controller.dart';
import '../core/settings_controller.dart';
import '../core/sms.dart';
import 'theme.dart';

Future<void> showParkingPromptSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PP.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _ParkingSheet(),
  );
}

class _ParkingSheet extends ConsumerWidget {
  const _ParkingSheet();

  Future<void> _putParking(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.smsNumber.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set the SMS number in Settings first')),
        );
      }
      return;
    }
    final ok = await openParkingSms(
      number: settings.smsNumber,
      body: settings.smsTemplate,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t open Messages')),
      );
      return;
    }
    ref.read(monitorProvider.notifier).dismissPromptAfterSms();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PP.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Looks like you stopped',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Put parking, or skip if you’re a passenger?',
            style: TextStyle(color: PP.muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          _Action(
            color: PP.accent,
            icon: Icons.sms_outlined,
            label: 'Put parking',
            onTap: () async {
              Navigator.pop(context);
              await _putParking(context, ref);
            },
          ),
          _Action(
            color: PP.card,
            icon: Icons.check_circle_outline,
            label: 'Already paid',
            bordered: true,
            onTap: () async {
              Navigator.pop(context);
              await showPaidRemindSheet(context, ref);
            },
          ),
          _Action(
            color: PP.card,
            icon: Icons.airline_seat_recline_normal,
            label: 'I’m a passenger',
            bordered: true,
            onTap: () async {
              Navigator.pop(context);
              await showPassengerQuietSheet(context, ref);
            },
          ),
          _Action(
            color: PP.card,
            icon: Icons.close,
            label: 'Not parking',
            bordered: true,
            onTap: () {
              ref.read(monitorProvider.notifier).notParking();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showPaidRemindSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PP.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _PaidRemindSheet(),
  );
}

class _PaidRemindSheet extends ConsumerWidget {
  const _PaidRemindSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final monitor = ref.read(monitorProvider.notifier);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Want a reminder in 1 hour?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'We’ll nudge you in case the meter runs out.',
            style: TextStyle(color: PP.muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          _Action(
            color: PP.accent,
            icon: Icons.check,
            label: 'Yes',
            onTap: () {
              monitor.markPaid(remindInOneHour: true);
              Navigator.pop(context);
            },
          ),
          _Action(
            color: PP.card,
            icon: Icons.close,
            label: 'No',
            bordered: true,
            onTap: () {
              monitor.markPaid(remindInOneHour: false);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showPassengerQuietSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PP.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _PassengerQuietSheet(),
  );
}

class _PassengerQuietSheet extends ConsumerWidget {
  const _PassengerQuietSheet();

  static const _hours = [1, 2, 3, 4, 6, 8];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'How long to snooze?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'No parking prompts until this ends.',
            style: TextStyle(color: PP.muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          for (final h in _hours)
            _Action(
              color: PP.card,
              icon: Icons.schedule,
              label: h == 1 ? '1 hour' : '$h hours',
              bordered: true,
              onTap: () {
                ref.read(monitorProvider.notifier).passengerQuiet(hours: h);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.bordered = false,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bordered ? PP.bg : color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: bordered
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PP.muted.withValues(alpha: 0.25)),
                  )
                : null,
            child: Row(
              children: [
                Icon(icon, color: bordered ? PP.text : PP.bg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: bordered ? PP.text : PP.bg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
