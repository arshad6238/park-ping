enum TripPhase {
  idle,
  traveling,
  arrived,
  prompted,
}

enum PromptChoice {
  putParking,
  paid,
  passenger,
  snooze,
  notParking,
}

class AppSettings {
  const AppSettings({
    this.monitoringEnabled = true,
    this.minDriveSeconds = 120,
    this.minStopSeconds = 75,
    this.snoozeMinutes = 10,
    this.cooldownMinutes = 10,
    this.smsNumber = '',
    this.smsTemplate = '',
    this.lastAreaCodes = const [],
  });

  final bool monitoringEnabled;
  final int minDriveSeconds;
  final int minStopSeconds;
  final int snoozeMinutes;
  final int cooldownMinutes;
  final String smsNumber;
  final String smsTemplate;
  final List<String> lastAreaCodes;

  AppSettings copyWith({
    bool? monitoringEnabled,
    int? minDriveSeconds,
    int? minStopSeconds,
    int? snoozeMinutes,
    int? cooldownMinutes,
    String? smsNumber,
    String? smsTemplate,
    List<String>? lastAreaCodes,
  }) =>
      AppSettings(
        monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
        minDriveSeconds: minDriveSeconds ?? this.minDriveSeconds,
        minStopSeconds: minStopSeconds ?? this.minStopSeconds,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
        smsNumber: smsNumber ?? this.smsNumber,
        smsTemplate: smsTemplate ?? this.smsTemplate,
        lastAreaCodes: lastAreaCodes ?? this.lastAreaCodes,
      );

  Map<String, Object?> toJson() => {
        'monitoringEnabled': monitoringEnabled,
        'minDriveSeconds': minDriveSeconds,
        'minStopSeconds': minStopSeconds,
        'snoozeMinutes': snoozeMinutes,
        'cooldownMinutes': cooldownMinutes,
        'smsNumber': smsNumber,
        'smsTemplate': smsTemplate,
        'lastAreaCodes': lastAreaCodes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        monitoringEnabled: j['monitoringEnabled'] as bool? ?? true,
        minDriveSeconds: j['minDriveSeconds'] as int? ?? 120,
        minStopSeconds: j['minStopSeconds'] as int? ?? 75,
        snoozeMinutes: j['snoozeMinutes'] as int? ?? 10,
        cooldownMinutes: j['cooldownMinutes'] as int? ?? 10,
        smsNumber: j['smsNumber'] as String? ?? '',
        smsTemplate: j['smsTemplate'] as String? ?? '',
        lastAreaCodes:
            (j['lastAreaCodes'] as List?)?.map((e) => '$e').toList() ?? const [],
      );
}

class MonitorSnapshot {
  const MonitorSnapshot({
    this.phase = TripPhase.idle,
    this.monitoringEnabled = true,
    this.speedMps = 0,
    this.lastEvent,
    this.showPrompt = false,
    this.permissionOk = false,
    this.statusLine = 'Monitoring off',
  });

  final TripPhase phase;
  final bool monitoringEnabled;
  final double speedMps;
  final String? lastEvent;
  final bool showPrompt;
  final bool permissionOk;
  final String statusLine;

  MonitorSnapshot copyWith({
    TripPhase? phase,
    bool? monitoringEnabled,
    double? speedMps,
    String? lastEvent,
    bool? showPrompt,
    bool? permissionOk,
    String? statusLine,
  }) =>
      MonitorSnapshot(
        phase: phase ?? this.phase,
        monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
        speedMps: speedMps ?? this.speedMps,
        lastEvent: lastEvent ?? this.lastEvent,
        showPrompt: showPrompt ?? this.showPrompt,
        permissionOk: permissionOk ?? this.permissionOk,
        statusLine: statusLine ?? this.statusLine,
      );
}
