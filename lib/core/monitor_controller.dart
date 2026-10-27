import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models.dart';
import 'notifications.dart';
import 'settings_controller.dart';

final notificationsProvider = Provider<ParkNotifications>((ref) {
  throw UnimplementedError('override in main()');
});

final monitorProvider =
    NotifierProvider<MonitorController, MonitorSnapshot>(MonitorController.new);

class MonitorController extends Notifier<MonitorSnapshot> {
  StreamSubscription<Position>? _sub;
  DateTime? _fastSince;
  DateTime? _slowSince;
  DateTime? _cooldownUntil;
  Timer? _snoozeTimer;

  // ~18 km/h — clearly a vehicle, not walking.
  static const _driveSpeed = 5.0;
  // ~3.6 km/h — nearly stopped / crawling.
  static const _stopSpeed = 1.0;

  @override
  MonitorSnapshot build() {
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.monitoringEnabled != next.monitoringEnabled) {
        unawaited(_applyMonitoring(next.monitoringEnabled));
      }
    });
    final settings = ref.read(settingsProvider);
    Future.microtask(() => _applyMonitoring(settings.monitoringEnabled));
    return MonitorSnapshot(
      monitoringEnabled: settings.monitoringEnabled,
      statusLine: settings.monitoringEnabled ? 'Starting…' : 'Monitoring off',
    );
  }

  Future<void> requestPermissions() async {
    await Permission.notification.request();
    await Permission.locationWhenInUse.request();
    final always = await Permission.locationAlways.request();
    final ok = always.isGranted ||
        await Permission.locationWhenInUse.status.isGranted;
    state = state.copyWith(permissionOk: ok);
    if (ref.read(settingsProvider).monitoringEnabled) {
      await _start();
    }
  }

  Future<void> setMonitoring(bool on) async {
    await ref.read(settingsProvider.notifier).setMonitoring(on);
    await _applyMonitoring(on);
  }

  Future<void> _applyMonitoring(bool on) async {
    if (!on) {
      await _stop();
      state = state.copyWith(
        monitoringEnabled: false,
        phase: TripPhase.idle,
        showPrompt: false,
        statusLine: 'Monitoring off — battery saver',
        lastEvent: 'Turned off ${ _time() }',
      );
      return;
    }
    state = state.copyWith(monitoringEnabled: true);
    await _start();
  }

  Future<void> _start() async {
    await _sub?.cancel();
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      state = state.copyWith(
        statusLine: 'Turn on Location Services',
        permissionOk: false,
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final ok = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!ok) {
      state = state.copyWith(
        permissionOk: false,
        statusLine: 'Location permission needed',
      );
      return;
    }

    state = state.copyWith(
      permissionOk: true,
      phase: TripPhase.idle,
      statusLine: 'Listening for a trip',
    );

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (Object e) {
        state = state.copyWith(statusLine: 'Location error — retry later');
      },
    );
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    _fastSince = null;
    _slowSince = null;
    _snoozeTimer?.cancel();
  }

  void _onPosition(Position pos) {
    final settings = ref.read(settingsProvider);
    if (!settings.monitoringEnabled) return;

    final speed = pos.speed.isNaN ? 0.0 : pos.speed.clamp(0, 60).toDouble();
    state = state.copyWith(speedMps: speed);

    final now = DateTime.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      state = state.copyWith(
        statusLine: 'Quiet until ${_fmt(_cooldownUntil!)} — no prompts',
      );
      return;
    }
    if (_cooldownUntil != null && !now.isBefore(_cooldownUntil!)) {
      _cooldownUntil = null;
    }

    if (speed >= _driveSpeed) {
      _slowSince = null;
      _fastSince ??= now;
      final driven = now.difference(_fastSince!);
      if (driven.inSeconds >= settings.minDriveSeconds) {
        if (state.phase != TripPhase.traveling) {
          state = state.copyWith(
            phase: TripPhase.traveling,
            showPrompt: false,
            statusLine: 'On a trip',
            lastEvent: 'Trip started ${_time()}',
          );
        } else {
          state = state.copyWith(statusLine: 'On a trip');
        }
      } else {
        state = state.copyWith(
          statusLine: 'Moving… ${driven.inSeconds}s / ${settings.minDriveSeconds}s',
        );
      }
      return;
    }

    if (state.phase == TripPhase.traveling || state.phase == TripPhase.arrived) {
      if (speed <= _stopSpeed) {
        _slowSince ??= now;
        final stopped = now.difference(_slowSince!);
        if (stopped.inSeconds >= settings.minStopSeconds) {
          if (!state.showPrompt) {
            unawaited(_firePrompt());
          }
        } else {
          state = state.copyWith(
            phase: TripPhase.arrived,
            statusLine:
                'Stopped… ${stopped.inSeconds}s / ${settings.minStopSeconds}s',
          );
        }
      } else {
        // Crawling — likely traffic, keep traveling.
        _slowSince = null;
        state = state.copyWith(
          phase: TripPhase.traveling,
          statusLine: 'Slow traffic — still on trip',
        );
      }
    }
  }

  Future<void> _firePrompt() async {
    final now = DateTime.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return;
    }
    state = state.copyWith(
      phase: TripPhase.prompted,
      showPrompt: true,
      statusLine: 'Parking check',
      lastEvent: 'Stop detected ${_time()}',
    );
    await ref.read(notificationsProvider).showParkingPrompt();
  }

  Future<void> handleChoice(PromptChoice choice) async {
    switch (choice) {
      case PromptChoice.putParking:
        // UI opens SMS sheet; stay prompted until paid/dismiss after send.
        return;
      case PromptChoice.paid:
        await markPaid(remindInOneHour: false);
        return;
      case PromptChoice.passenger:
        // Needs hour pick in UI; default quiet if tapped from a notification.
        await passengerQuiet(hours: 2);
        return;
      case PromptChoice.notParking:
        await notParking();
        return;
      case PromptChoice.snooze:
        await markPaid(remindInOneHour: true);
        return;
    }
  }

  /// Already paid — optional 1-hour meter reminder (does not mute trip detection).
  Future<void> markPaid({required bool remindInOneHour}) async {
    _snoozeTimer?.cancel();
    _fastSince = null;
    _slowSince = null;
    state = state.copyWith(
      phase: TripPhase.idle,
      showPrompt: false,
      statusLine: remindInOneHour
          ? 'Paid — remind in 1 hour'
          : 'Listening for a trip',
      lastEvent: remindInOneHour
          ? 'Paid + 1h reminder ${_time()}'
          : 'Marked paid ${_time()}',
    );
    if (!remindInOneHour) return;
    _snoozeTimer = Timer(const Duration(hours: 1), () {
      state = state.copyWith(showPrompt: true, statusLine: 'Parking check');
      unawaited(ref.read(notificationsProvider).showSnoozeReminder());
    });
  }

  /// Passenger — mute all parking prompts/notifications for [hours].
  Future<void> passengerQuiet({required int hours}) async {
    _snoozeTimer?.cancel();
    await ref.read(notificationsProvider).cancelAll();
    _fastSince = null;
    _slowSince = null;
    _cooldownUntil = DateTime.now().add(Duration(hours: hours));
    final until = _fmt(_cooldownUntil!);
    state = state.copyWith(
      phase: TripPhase.idle,
      showPrompt: false,
      statusLine: 'Passenger quiet until $until',
      lastEvent: 'Passenger — quiet ${hours}h ${_time()}',
    );
  }

  Future<void> notParking() async {
    final settings = ref.read(settingsProvider);
    _snoozeTimer?.cancel();
    _fastSince = null;
    _slowSince = null;
    _cooldownUntil =
        DateTime.now().add(Duration(minutes: settings.cooldownMinutes));
    state = state.copyWith(
      phase: TripPhase.idle,
      showPrompt: false,
      statusLine: 'Listening for next trip',
      lastEvent: 'Not parking — skipped ${_time()}',
    );
  }

  void dismissPromptAfterSms() {
    _fastSince = null;
    _slowSince = null;
    state = state.copyWith(
      phase: TripPhase.idle,
      showPrompt: false,
      statusLine: 'Listening for a trip',
      lastEvent: 'Opened parking SMS ${_time()}',
    );
  }

  /// Manual test trigger (dev / demo).
  void simulateArrival() {
    unawaited(_firePrompt());
  }

  String _time() => _fmt(DateTime.now());

  String _fmt(DateTime n) {
    final h = n.hour.toString().padLeft(2, '0');
    final m = n.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
