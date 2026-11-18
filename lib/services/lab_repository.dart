import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/lab_models.dart';

abstract class LabRepository extends ChangeNotifier {
  LabReading? get reading;
  List<LabReading> get history;
  List<LabAlert> get alerts;
  LabSettings get settings;
  bool get connected;
  String? get error;
  String? get commandMessage;
  bool get commandPending;
  int get now;
  bool get online => connected && (reading?.freshAt(now) ?? false);
  Future<void> sendCommand(String action);
  Future<void> saveSettings(LabSettings value);
}

class FirebaseLabRepository extends LabRepository {
  final FirebaseDatabase database;
  final String uid;
  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];
  late final DatabaseReference _root;
  late final Timer _clock;
  Timer? _commandTimer;
  LabReading? _reading;
  List<LabReading> _history = [];
  List<LabAlert> _alerts = [];
  LabSettings _settings = const LabSettings();
  bool _connected = false;
  bool _disposed = false;
  int _offset = 0;
  String? _error;
  String? _pendingId;
  String? _commandMessage;

  FirebaseLabRepository(this.database, this.uid) {
    _root = database.ref('labs/${AppConfig.labId}');
    _listen(database.ref('.info/connected'), (value) {
      _connected = value == true;
    });
    _listen(database.ref('.info/serverTimeOffset'), (value) {
      _offset = number(value)?.round() ?? 0;
    });
    _listen(_root.child('current'), (value) {
      _reading = value == null ? null : LabReading.fromJson(value);
      if (_pendingId != null && _reading?.commandId == _pendingId) {
        _commandMessage = _reading!.commandResult == 'accepted'
            ? 'Command confirmed by ESP32.'
            : 'ESP32 rejected the command.';
        _pendingId = null;
        _commandTimer?.cancel();
      }
    });
    _listen(_root.child('config'), (value) {
      _settings = LabSettings.fromJson(value);
    });
    _listen(
      _root.child('history').orderByChild('updatedAt').limitToLast(2880),
      (value) {
        _history = stringMap(value).values.map(LabReading.fromJson).toList()
          ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      },
    );
    _listen(_root.child('alerts').orderByChild('updatedAt').limitToLast(100), (
      value,
    ) {
      _alerts =
          stringMap(value).entries
              .map((entry) => LabAlert.fromJson(entry.key, entry.value))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _notify());
  }

  void _listen(Query query, void Function(Object?) apply) {
    _subscriptions.add(
      query.onValue.listen(
        (event) {
          apply(event.snapshot.value);
          _notify();
        },
        onError: (Object error) {
          _error = 'Database access failed. Check your membership and database rules, then sign in again.';
          _notify();
        },
      ),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  LabReading? get reading => _reading;
  @override
  List<LabReading> get history => _history;
  @override
  List<LabAlert> get alerts => _alerts;
  @override
  LabSettings get settings => _settings;
  @override
  bool get connected => _connected;
  @override
  String? get error => _error;
  @override
  String? get commandMessage => _commandMessage;
  @override
  bool get commandPending => _pendingId != null;
  @override
  int get now => DateTime.now().millisecondsSinceEpoch + _offset;

  @override
  Future<void> sendCommand(String action) async {
    if (!online || commandPending || _error != null) {
      throw StateError(
        'Wait for a live ESP32 connection before sending a command.',
      );
    }
    if (!['test_alarm', 'stop_test'].contains(action)) {
      throw ArgumentError('Unsupported command');
    }
    final id = _root.child('command').push().key!;
    _pendingId = id;
    _commandMessage = 'Waiting for ESP32 confirmation…';
    _notify();
    _commandTimer = Timer(const Duration(seconds: 15), () {
      if (_pendingId == id) {
        _pendingId = null;
        _commandMessage = 'No confirmation received. Check the physical alarm and connection.';
        _notify();
      }
    });
    try {
      await _root
          .child('command')
          .set({
            'id': id,
            'action': action,
            'issuedAt': ServerValue.timestamp,
            'by': uid,
          })
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      _pendingId = null;
      _commandTimer?.cancel();
      _commandMessage = 'Command delivery is unconfirmed. Check the device.';
      _notify();
      rethrow;
    }
  }

  @override
  Future<void> saveSettings(LabSettings value) async {
    if (!online || _error != null)
      throw StateError('Connect the ESP32 before changing thresholds.');
    if (!value.valid) throw ArgumentError('Invalid thresholds');
    await _root
        .child('config')
        .set(value.toJson())
        .timeout(const Duration(seconds: 8));
  }

  @override
  void dispose() {
    _disposed = true;
    _clock.cancel();
    _commandTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
