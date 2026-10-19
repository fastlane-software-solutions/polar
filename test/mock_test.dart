import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:polar/polar.dart';

import 'tests.dart';

const identifier = 'asdf';
final info = jsonEncode(
  const PolarDeviceInfo(
    deviceId: identifier,
    address: '',
    rssi: 0,
    name: '',
    isConnectable: true,
  ),
);
const methodChannel = MethodChannel('polar/methods');
const eventChannel = EventChannel('polar/events');
const searchChannel = EventChannel('polar/search');

final eventHandler = EventHandler();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, handleMethodCall);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, eventHandler);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(searchChannel, SearchHandler());
  });

  testSearch(identifier);
  testConnection(identifier);
  testBasicData(
    identifier,
    expectedChargeState: PolarChargeState.dischargingActive,
  );
  testBleSdkFeatures(identifier, features: PolarSdkFeature.values.toSet());
  testStreaming(identifier, features: PolarDataType.values.toSet());
  testRecording(identifier, wait: false);
  testOfflineRecording(
    identifier,
    features: offlineRecordingFeatures,
    recordingDuration: Duration.zero,
  );
  testOfflineRecordChannelLifecycle();
  testSdkMode(identifier);
  testMisc(identifier, supportsLedConfig: true);
  testFtu(identifier);
  testShutDown(identifier);
}

final exercises = <PolarExerciseEntry>[];
var recording = false;
var exerciseId = '';
var sdkModeEnabled = false;

const offlineRecordingFeatures = {
  PolarDataType.acc,
  PolarDataType.gyro,
  PolarDataType.magnetometer,
  PolarDataType.ppg,
  PolarDataType.ppi,
  PolarDataType.hr,
  PolarDataType.temperature,
  PolarDataType.skinTemperature,
};
final offlineRecordings = <PolarDataType>{};
final offlineRecordingEntries = <PolarOfflineRecordingEntry>[];
final createdOfflineRecordChannels = <String>[];
final listenedOfflineRecordChannels = <String>[];
final cancelledOfflineRecordChannels = <String>[];
final disposedOfflineRecordChannels = <String>[];
var failOfflineRecord = false;
var offlineRecordingTrigger = const PolarOfflineRecordingTrigger(
  triggerMode: PolarOfflineRecordingTriggerMode.triggerDisabled,
  triggerFeatures: {},
);

String offlineRecord(String entry) {
  final type = PolarOfflineRecordingEntry.fromJson(jsonDecode(entry)).type;
  final settings = type.supportsStreamSettings
      ? PolarSensorSetting(const {PolarSettingType.sampleRate: 52})
      : null;
  return jsonEncode({
    'type': type.toJson(),
    'startTime': DateTime.timestamp().millisecondsSinceEpoch,
    'settings': settings?.toJson(),
    'data': sampleData(type).toJson(),
  });
}

Future<dynamic> handleMethodCall(MethodCall call) async {
  switch (call.method) {
    case 'connectToDevice':
      eventHandler.emitConnecting();
      eventHandler.emitConnected();
      return null;
    case 'disconnectFromDevice':
      eventHandler.emitDisconnected();
      return null;
    case 'getAvailableOnlineStreamDataTypes':
      return jsonEncode(PolarDataType.values.map((e) => e.toJson()).toList());
    case 'requestStreamSettings':
      return jsonEncode(PolarSensorSetting(const {}));
    case 'createStreamingChannel':
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            EventChannel(call.arguments[0] as String),
            StreamingHandler(PolarDataType.fromJson(call.arguments[2])),
          );
      return null;
    case 'startRecording':
      recording = true;
      exerciseId = call.arguments[1];
      return null;
    case 'stopRecording':
      recording = false;
      exercises.add(
        PolarExerciseEntry(
          path: '',
          date: DateTime.timestamp(),
          entryId: exerciseId,
        ),
      );
      return null;
    case 'requestRecordingStatus':
      return [recording, exerciseId];
    case 'listExercises':
      return exercises.map(jsonEncode).toList();
    case 'fetchExercise':
      return jsonEncode({
        'recordingInterval': 0,
        'hrSamples': [0],
      });
    case 'removeExercise':
      exercises.clear();
      return null;
    case 'getAvailableOfflineRecordingDataTypes':
      return jsonEncode(
        offlineRecordingFeatures.map((e) => e.toJson()).toList(),
      );
    case 'requestOfflineRecordingSettings':
    case 'requestFullOfflineRecordingSettings':
      return jsonEncode(
        PolarSensorSetting(const {PolarSettingType.sampleRate: 52}),
      );
    case 'getOfflineRecordingStatus':
      return jsonEncode(offlineRecordings.map((e) => e.toJson()).toList());
    case 'startOfflineRecording':
      offlineRecordings.add(PolarDataType.fromJson(call.arguments[1]));
      return null;
    case 'stopOfflineRecording':
      final type = PolarDataType.fromJson(call.arguments[1]);
      offlineRecordings.remove(type);
      offlineRecordingEntries.add(
        PolarOfflineRecordingEntry(
          path: '/U/0/${type.name}.REC',
          size: 0,
          date: DateTime.timestamp(),
          type: type,
        ),
      );
      return null;
    case 'listOfflineRecordings':
      return offlineRecordingEntries.map(jsonEncode).toList();
    case 'getOfflineRecord':
      return offlineRecord(call.arguments[1]);
    case 'createOfflineRecordChannel':
      final name = call.arguments[0] as String;
      createdOfflineRecordChannels.add(name);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            EventChannel(name),
            OfflineRecordHandler(name, call.arguments[2]),
          );
      return null;
    case 'disposeOfflineRecordChannel':
      final name = call.arguments as String;
      disposedOfflineRecordChannels.add(name);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(EventChannel(name), null);
      return null;
    case 'removeOfflineRecord':
      final path = jsonDecode(call.arguments[1])['path'];
      offlineRecordingEntries.removeWhere((e) => e.path == path);
      return null;
    case 'setOfflineRecordingTrigger':
      offlineRecordingTrigger = PolarOfflineRecordingTrigger.fromJson(
        jsonDecode(call.arguments[1]),
      );
      return null;
    case 'getOfflineRecordingTriggerSetup':
      return jsonEncode(offlineRecordingTrigger);
    case 'setLedConfig':
      return null;
    case 'enableSdkMode':
      sdkModeEnabled = true;
      return null;
    case 'disableSdkMode':
      sdkModeEnabled = false;
      return null;
    case 'isSdkModeEnabled':
      return sdkModeEnabled;
    case 'doFactoryReset':
      return null;
    case 'doFirstTimeUse':
      return null;
    case 'isFtuDone':
      return true;
    case 'shutDown':
      return null;
    default:
      throw UnimplementedError();
  }
}

class EventHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    _sink = events;
  }

  @override
  void onCancel(dynamic arguments) {
    _sink = null;
  }

  void emitConnecting() {
    _sink?.success({'event': 'deviceConnecting', 'data': info});
  }

  void emitConnected() {
    _sink?.success({'event': 'deviceConnected', 'data': info});
    _sink?.success({
      'event': 'disInformationReceived',
      'data': [identifier, '', ''],
    });
    _sink?.success({
      'event': 'batteryLevelReceived',
      'data': [identifier, 100],
    });
    _sink?.success({
      'event': 'batteryChargingStatusReceived',
      'data': [identifier, PolarChargeState.dischargingActive.toJson()],
    });
    for (final feature in PolarSdkFeature.values) {
      _sink?.success({
        'event': 'sdkFeatureReady',
        'data': [identifier, feature.toJson()],
      });
    }
    _sink?.success({
      'event': 'sdkFeaturesReadiness',
      'data': [
        identifier,
        PolarSdkFeature.values.map((e) => e.toJson()).toList(),
        <String>[],
      ],
    });
  }

  void emitDisconnected() {
    _sink?.success({
      'event': 'deviceDisconnected',
      'data': [info, false],
    });
  }
}

class SearchHandler extends MockStreamHandler {
  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    events.success(info);
  }

  @override
  void onCancel(dynamic arguments) {}
}

@immutable
class StreamingHandler extends MockStreamHandler {
  final PolarDataType type;

  const StreamingHandler(this.type);

  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    events.success(jsonEncode(sampleData(type)));
  }

  @override
  void onCancel(dynamic arguments) {}
}

PolarStreamingData sampleData(PolarDataType type) {
  final PolarStreamingData data;
  switch (type) {
    case PolarDataType.ecg:
      data = PolarEcgData(
        samples: [PolarEcgSample(timeStamp: DateTime.timestamp(), voltage: 0)],
      );
    case PolarDataType.acc:
      data = PolarAccData(
        samples: [
          PolarAccSample(timeStamp: DateTime.timestamp(), x: 0, y: 0, z: 0),
        ],
      );
    case PolarDataType.ppg:
      data = PolarPpgData(
        type: PpgDataType.ppg3_ambient1,
        samples: [
          PolarPpgSample(
            timeStamp: DateTime.timestamp(),
            channelSamples: const [],
            statusBits: const [],
          ),
        ],
      );
    case PolarDataType.ppi:
      data = const PolarPpiData(
        samples: [
          PolarPpiSample(
            timeStamp: 0,
            ppi: 0,
            errorEstimate: 0,
            hr: 0,
            blockerBit: false,
            skinContactStatus: false,
            skinContactSupported: false,
          ),
        ],
      );
    case PolarDataType.gyro:
      data = PolarGyroData(
        samples: [
          PolarGyroSample(timeStamp: DateTime.timestamp(), x: 0, y: 0, z: 0),
        ],
      );
    case PolarDataType.magnetometer:
      data = PolarMagnetometerData(
        samples: [
          PolarMagnetometerSample(
            timeStamp: DateTime.timestamp(),
            x: 0,
            y: 0,
            z: 0,
          ),
        ],
      );
    case PolarDataType.hr:
      data = const PolarHrData(
        samples: [
          PolarHrSample(
            hr: 0,
            ppgQuality: 0,
            correctedHr: 0,
            rrsMs: [],
            contactStatus: false,
            contactStatusSupported: false,
          ),
        ],
      );
    case PolarDataType.temperature:
      data = PolarTemperatureData(
        samples: [
          PolarTemperatureSample(
            timeStamp: DateTime.timestamp(),
            temperature: 0,
          ),
        ],
      );
    case PolarDataType.pressure:
      data = PolarPressureData(
        samples: [
          PolarPressureSample(timeStamp: DateTime.timestamp(), pressure: 0),
        ],
      );
    case PolarDataType.skinTemperature:
      data = PolarTemperatureData(
        samples: [
          PolarTemperatureSample(
            timeStamp: DateTime.timestamp(),
            temperature: 0,
          ),
        ],
      );
    case PolarDataType.location:
      data = PolarLocationData(
        samples: [
          PolarLocationDataSample(
            timeStamp: DateTime.timestamp(),
            latitude: 0,
            longitude: 0,
            time: '',
            speed: 0,
            cumulativeDistance: 0,
            usedAccelerationSpeed: 0,
            coordinateSpeed: 0,
            accelerationSpeedFactor: 0,
            course: 0,
            gpsChipSpeed: 0,
            fix: true,
            speedFlag: 0,
            fusionState: 0,
          ),
        ],
      );
  }

  return data;
}

@immutable
class OfflineRecordHandler extends MockStreamHandler {
  final String name;
  final String entry;

  const OfflineRecordHandler(this.name, this.entry);

  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    listenedOfflineRecordChannels.add(name);
    events.success(
      jsonEncode(
        const PolarOfflineRecordingProgress(
          bytesDownloaded: 0,
          totalBytes: 1,
          progressPercent: 0,
        ),
      ),
    );
    if (failOfflineRecord) {
      // Mirrors the native plugins, which end the stream after an error
      events.error(code: 'Error fetching offline recording');
      events.endOfStream();
      return;
    }
    events.success(jsonEncode({'complete': jsonDecode(offlineRecord(entry))}));
    events.endOfStream();
  }

  @override
  void onCancel(dynamic arguments) {
    cancelledOfflineRecordChannels.add(name);
  }
}

void testOfflineRecordChannelLifecycle() {
  group('offline record channel lifecycle', () {
    final entry = PolarOfflineRecordingEntry(
      path: '/U/0/20260101/R/100000/ACC.REC',
      size: 0,
      date: DateTime.timestamp(),
      type: PolarDataType.acc,
    );

    tearDown(() => failOfflineRecord = false);

    test('cancelled before listening', () async {
      final subscription = polar
          .getOfflineRecordWithProgress(identifier, entry)
          .listen(null);
      await subscription.cancel();

      final name = createdOfflineRecordChannels.last;
      expect(listenedOfflineRecordChannels, isNot(contains(name)));
      expect(disposedOfflineRecordChannels, contains(name));
    });

    test('download error', () async {
      failOfflineRecord = true;

      final events = <Object>[];
      final done = Completer<void>();
      polar
          .getOfflineRecordWithProgress(identifier, entry)
          .listen(events.add, onError: events.add, onDone: done.complete);
      await done.future;

      expect(events.first, isA<PolarOfflineRecordingProgress>());
      expect(events.last, isA<PlatformException>());

      final name = createdOfflineRecordChannels.last;
      // Native disposes the channel when Dart cancels it
      expect(cancelledOfflineRecordChannels, contains(name));
      expect(disposedOfflineRecordChannels, contains(name));
    });
  });
}
