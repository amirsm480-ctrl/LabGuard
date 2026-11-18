Map<String, dynamic> stringMap(Object? value) {
  if (value is! Map) return {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

double? number(Object? value) => value is num ? value.toDouble() : null;

class LabReading {
  final double? temperature;
  final double? humidity;
  final int? gas;
  final bool flame;
  final bool alarm;
  final bool dhtOk;
  final bool gasReady;
  final int gasWarmupSeconds;
  final String safety;
  final String reason;
  final int updatedAt;
  final int rssi;
  final int uptime;
  final String commandId;
  final String commandResult;
  final String firmware;
  final LabSettings settings;

  const LabReading({
    required this.temperature,
    required this.humidity,
    required this.gas,
    required this.flame,
    required this.alarm,
    required this.dhtOk,
    required this.gasReady,
    required this.gasWarmupSeconds,
    required this.safety,
    required this.reason,
    required this.updatedAt,
    required this.rssi,
    required this.uptime,
    required this.commandId,
    required this.commandResult,
    required this.firmware,
    required this.settings,
  });

  factory LabReading.fromJson(Object? data) {
    final json = stringMap(data);
    return LabReading(
      temperature: number(json['temperatureC']),
      humidity: number(json['humidityPct']),
      gas: number(json['gasRaw'])?.round(),
      flame: json['flameDetected'] == true,
      alarm: json['alarmOn'] == true,
      dhtOk: json['dhtOk'] == true,
      gasReady: json['gasReady'] == true,
      gasWarmupSeconds: number(json['gasWarmupRemainingS'])?.round() ?? 0,
      safety: json['safetyStatus']?.toString() ?? 'unknown',
      reason: json['alarmReason']?.toString() ?? 'unknown',
      updatedAt: number(json['updatedAt'])?.round() ?? 0,
      rssi: number(json['wifiRssi'])?.round() ?? -127,
      uptime: number(json['uptimeS'])?.round() ?? 0,
      commandId: json['ackCommandId']?.toString() ?? '',
      commandResult: json['ackResult']?.toString() ?? '',
      firmware: json['firmwareVersion']?.toString() ?? '',
      settings: LabSettings.fromJson(json['appliedSettings']),
    );
  }

  bool freshAt(int now) =>
      updatedAt > 0 && now - updatedAt >= -5000 && now - updatedAt <= 20000;
  bool get hazard =>
      ['flame', 'gas', 'temperature', 'multiple'].contains(reason);
  double? metric(String key) => switch (key) {
    'Temperature' => dhtOk ? temperature : null,
    'Humidity' => dhtOk ? humidity : null,
    'Gas' => gasReady ? gas?.toDouble() : null,
    _ => null,
  };
}

class LabSettings {
  final double temperatureHigh;
  final double temperatureClear;
  final int gasHigh;
  final int gasClear;

  const LabSettings({
    this.temperatureHigh = 40,
    this.temperatureClear = 38,
    this.gasHigh = 2200,
    this.gasClear = 2000,
  });

  factory LabSettings.fromJson(Object? value) {
    final json = stringMap(value);
    return LabSettings(
      temperatureHigh: number(json['temperatureHigh']) ?? 40,
      temperatureClear: number(json['temperatureClear']) ?? 38,
      gasHigh: number(json['gasHigh'])?.round() ?? 2200,
      gasClear: number(json['gasClear'])?.round() ?? 2000,
    );
  }

  bool get valid =>
      temperatureHigh >= 30 &&
      temperatureHigh <= 60 &&
      temperatureClear >= 20 &&
      temperatureClear <= temperatureHigh - 1 &&
      gasHigh >= 100 &&
      gasHigh <= 4000 &&
      gasClear >= 0 &&
      gasClear < gasHigh;

  Map<String, Object> toJson() => {
    'temperatureHigh': temperatureHigh,
    'temperatureClear': temperatureClear,
    'gasHigh': gasHigh,
    'gasClear': gasClear,
  };

  bool matches(LabSettings other) =>
      temperatureHigh == other.temperatureHigh &&
      temperatureClear == other.temperatureClear &&
      gasHigh == other.gasHigh &&
      gasClear == other.gasClear;
}

class LabAlert {
  final String id;
  final String reason;
  final String state;
  final int timestamp;
  final int occurredAt;

  const LabAlert(
    this.id,
    this.reason,
    this.state,
    this.timestamp,
    this.occurredAt,
  );

  factory LabAlert.fromJson(String id, Object? value) {
    final data = stringMap(value);
    return LabAlert(
      id,
      data['reason']?.toString() ?? 'unknown',
      data['state']?.toString() ?? 'unknown',
      number(data['updatedAt'])?.round() ?? 0,
      number(data['occurredAt'])?.round() ?? 0,
    );
  }

  String get title => state == 'clear'
      ? 'Condition cleared'
      : switch (reason) {
          'flame' => 'Flame detected',
          'gas' => 'Gas threshold exceeded',
          'temperature' => 'Temperature threshold exceeded',
          'multiple' => 'Multiple hazards detected',
          'sensor_fault' => 'Temperature sensor unavailable',
          'manual_test' => 'Alarm test started',
          _ => 'System condition changed',
        };
}

String reasonLabel(String reason) => switch (reason) {
  'flame' => 'Flame detected',
  'gas' => 'Gas level above threshold',
  'temperature' => 'High temperature',
  'multiple' => 'Multiple hazards detected',
  'manual_test' => 'Manual alarm test',
  'none' => 'No active alarm',
  _ => 'Waiting for device status',
};
