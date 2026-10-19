import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:polar/polar.dart';
import 'package:polar/src/model/convert.dart';

part 'polar_offline_recording.g.dart';

dynamic _dataTypeToJson(PolarDataType type) => type.toJson();

PolarSensorSetting? _settingsFromJson(Map<String, dynamic>? json) =>
    json == null ? null : PolarSensorSetting.fromJson(json);

/// Polar offline recording entry container
@JsonSerializable()
@immutable
class PolarOfflineRecordingEntry {
  /// Recording entry path in device
  final String path;

  /// Recording size in bytes
  final int size;

  /// The date and time of the recording entry i.e. the moment recording is
  /// started
  @UnixTimeConverter()
  final DateTime date;

  /// Data type of the recording
  @JsonKey(fromJson: PolarDataType.fromJson, toJson: _dataTypeToJson)
  final PolarDataType type;

  /// Constructor
  const PolarOfflineRecordingEntry({
    required this.path,
    required this.size,
    required this.date,
    required this.type,
  });

  /// From json
  factory PolarOfflineRecordingEntry.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingEntryFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarOfflineRecordingEntryToJson(this);

  @override
  String toString() {
    return 'PolarOfflineRecordingEntry(path: $path, size: $size, date: $date, type: $type)';
  }
}

/// Polar recording secret is used to encrypt the recording
@immutable
class PolarRecordingSecret {
  /// Secret key of size 16 bytes. Supported encryption is AES_128
  final Uint8List key;

  /// Constructor
  PolarRecordingSecret(this.key) {
    if (key.length != 16) {
      throw ArgumentError.value(
        key,
        'key',
        'must be size of 16 bytes (128bits), was ${key.length}',
      );
    }
  }
}

/// Polar offline recording data
sealed class PolarOfflineRecordingData {
  /// The time recording was started in UTC time
  final DateTime startTime;

  /// The settings used while recording. Only available for data types that
  /// support settings.
  final PolarSensorSetting? settings;

  /// The type of the recorded data. Null for [PolarEmptyOfflineRecording].
  PolarDataType? get type;

  /// The recorded data. Null for [PolarEmptyOfflineRecording].
  PolarStreamingData? get data;

  const PolarOfflineRecordingData._({required this.startTime, this.settings});

  /// From json
  factory PolarOfflineRecordingData.fromJson(Map<String, dynamic> json) {
    final startTime = const UnixTimeConverter().fromJson(json['startTime']);
    final settings = _settingsFromJson(json['settings']);
    final type = json['type'];
    final data = json['data'] as Map<String, dynamic>?;

    if (type == null || data == null) {
      return PolarEmptyOfflineRecording(startTime: startTime);
    }

    return switch (PolarDataType.fromJson(type)) {
      PolarDataType.acc => PolarAccOfflineRecording(
        data: PolarAccData.fromJson(data),
        startTime: startTime,
        settings: settings,
      ),
      PolarDataType.gyro => PolarGyroOfflineRecording(
        data: PolarGyroData.fromJson(data),
        startTime: startTime,
        settings: settings,
      ),
      PolarDataType.magnetometer => PolarMagnetometerOfflineRecording(
        data: PolarMagnetometerData.fromJson(data),
        startTime: startTime,
        settings: settings,
      ),
      PolarDataType.ppg => PolarPpgOfflineRecording(
        data: PolarPpgData.fromJson(data),
        startTime: startTime,
        settings: settings,
      ),
      PolarDataType.ppi => PolarPpiOfflineRecording(
        data: PolarPpiData.fromJson(data),
        startTime: startTime,
      ),
      PolarDataType.hr => PolarHrOfflineRecording(
        data: PolarHrData.fromJson(data),
        startTime: startTime,
      ),
      PolarDataType.temperature => PolarTemperatureOfflineRecording(
        data: PolarTemperatureData.fromJson(data),
        startTime: startTime,
      ),
      PolarDataType.skinTemperature => PolarSkinTemperatureOfflineRecording(
        data: PolarTemperatureData.fromJson(data),
        startTime: startTime,
      ),
      final type => throw UnsupportedError(
        'Unsupported offline recording type: $type',
      ),
    };
  }

  /// To json
  Map<String, dynamic> toJson() => {
    'type': type?.toJson(),
    'startTime': const UnixTimeConverter().toJson(startTime),
    'settings': settings?.toJson(),
    'data': data?.toJson(),
  };
}

/// Accelerometer offline recording data
final class PolarAccOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.acc;

  @override
  final PolarAccData data;

  /// Constructor
  const PolarAccOfflineRecording({
    required this.data,
    required super.startTime,
    super.settings,
  }) : super._();
}

/// Gyroscope offline recording data
final class PolarGyroOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.gyro;

  @override
  final PolarGyroData data;

  /// Constructor
  const PolarGyroOfflineRecording({
    required this.data,
    required super.startTime,
    super.settings,
  }) : super._();
}

/// Magnetometer offline recording data
final class PolarMagnetometerOfflineRecording
    extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.magnetometer;

  @override
  final PolarMagnetometerData data;

  /// Constructor
  const PolarMagnetometerOfflineRecording({
    required this.data,
    required super.startTime,
    super.settings,
  }) : super._();
}

/// PPG offline recording data
final class PolarPpgOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.ppg;

  @override
  final PolarPpgData data;

  /// Constructor
  const PolarPpgOfflineRecording({
    required this.data,
    required super.startTime,
    super.settings,
  }) : super._();
}

/// PPI offline recording data
final class PolarPpiOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.ppi;

  @override
  final PolarPpiData data;

  /// Constructor
  const PolarPpiOfflineRecording({required this.data, required super.startTime})
    : super._();
}

/// HR offline recording data
final class PolarHrOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.hr;

  @override
  final PolarHrData data;

  /// Constructor
  const PolarHrOfflineRecording({required this.data, required super.startTime})
    : super._();
}

/// Temperature offline recording data
final class PolarTemperatureOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.temperature;

  @override
  final PolarTemperatureData data;

  /// Constructor
  const PolarTemperatureOfflineRecording({
    required this.data,
    required super.startTime,
  }) : super._();
}

/// Skin temperature offline recording data
final class PolarSkinTemperatureOfflineRecording
    extends PolarOfflineRecordingData {
  @override
  PolarDataType get type => PolarDataType.skinTemperature;

  @override
  final PolarTemperatureData data;

  /// Constructor
  const PolarSkinTemperatureOfflineRecording({
    required this.data,
    required super.startTime,
  }) : super._();
}

/// Offline recording without any data. Only returned by iOS.
final class PolarEmptyOfflineRecording extends PolarOfflineRecordingData {
  @override
  PolarDataType? get type => null;

  @override
  PolarStreamingData? get data => null;

  /// Constructor
  const PolarEmptyOfflineRecording({required super.startTime}) : super._();
}

/// Result of an offline recording fetch with progress
sealed class PolarOfflineRecordingResult {
  const PolarOfflineRecordingResult._();

  /// From json
  factory PolarOfflineRecordingResult.fromJson(Map<String, dynamic> json) {
    if (json['progress'] case final Map<String, dynamic> progress) {
      return PolarOfflineRecordingProgress.fromJson(progress);
    }
    return PolarOfflineRecordingComplete(
      PolarOfflineRecordingData.fromJson(json['complete']),
    );
  }

  /// To json
  Map<String, dynamic> toJson();
}

/// Progress update during an offline recording download
@JsonSerializable()
@immutable
final class PolarOfflineRecordingProgress extends PolarOfflineRecordingResult {
  /// Number of bytes downloaded so far
  final int bytesDownloaded;

  /// Total size of the recording in bytes
  final int totalBytes;

  /// Progress as percentage (0-100)
  final int progressPercent;

  /// Constructor
  const PolarOfflineRecordingProgress({
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.progressPercent,
  }) : super._();

  /// From json
  factory PolarOfflineRecordingProgress.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingProgressFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'progress': _$PolarOfflineRecordingProgressToJson(this),
  };
}

/// Offline recording download completed
@immutable
final class PolarOfflineRecordingComplete extends PolarOfflineRecordingResult {
  /// The downloaded offline recording data
  final PolarOfflineRecordingData data;

  /// Constructor
  const PolarOfflineRecordingComplete(this.data) : super._();

  @override
  Map<String, dynamic> toJson() => {'complete': data.toJson()};
}

/// Offline recording trigger mode
enum PolarOfflineRecordingTriggerMode {
  /// The automatic start of offline recording is disabled
  triggerDisabled,

  /// Triggers the offline recording when device is powered on
  triggerSystemStart,

  /// Triggers the offline recording when exercise is started in device
  triggerExerciseStart;

  /// Create a [PolarOfflineRecordingTriggerMode] from json
  static PolarOfflineRecordingTriggerMode fromJson(dynamic json) =>
      platformEnumFromJson(PolarOfflineRecordingTriggerMode.values, json);

  /// Convert a [PolarOfflineRecordingTriggerMode] to json
  dynamic toJson() => platformEnumToJson(this);
}

dynamic _triggerModeToJson(PolarOfflineRecordingTriggerMode mode) =>
    mode.toJson();

Map<PolarDataType, PolarSensorSetting?> _triggerFeaturesFromJson(
  List<dynamic> json,
) => {
  for (final feature in json.cast<Map<String, dynamic>>())
    PolarDataType.fromJson(feature['type']): _settingsFromJson(
      feature['settings'],
    ),
};

List<Map<String, dynamic>> _triggerFeaturesToJson(
  Map<PolarDataType, PolarSensorSetting?> features,
) => [
  for (final MapEntry(:key, :value) in features.entries)
    {'type': key.toJson(), 'settings': value?.toJson()},
];

/// Polar offline recording trigger
@JsonSerializable()
@immutable
class PolarOfflineRecordingTrigger {
  /// The trigger mode
  @JsonKey(
    fromJson: PolarOfflineRecordingTriggerMode.fromJson,
    toJson: _triggerModeToJson,
  )
  final PolarOfflineRecordingTriggerMode triggerMode;

  /// The data types to record when the trigger fires, and the settings to
  /// record them with. Settings are null for data types that do not support
  /// settings (e.g. PPI and HR).
  @JsonKey(fromJson: _triggerFeaturesFromJson, toJson: _triggerFeaturesToJson)
  final Map<PolarDataType, PolarSensorSetting?> triggerFeatures;

  /// Constructor
  const PolarOfflineRecordingTrigger({
    required this.triggerMode,
    required this.triggerFeatures,
  });

  /// From json
  factory PolarOfflineRecordingTrigger.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingTriggerFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarOfflineRecordingTriggerToJson(this);

  @override
  String toString() {
    return 'PolarOfflineRecordingTrigger(triggerMode: $triggerMode, triggerFeatures: $triggerFeatures)';
  }
}
