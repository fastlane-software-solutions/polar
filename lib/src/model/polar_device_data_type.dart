import 'package:polar/src/model/convert.dart';

/// Data types available in Polar devices for online streaming or offline
/// recording.
enum PolarDataType {
  /// ECG
  ecg,

  /// ACC
  acc,

  /// PPG
  ppg,

  /// PPI
  ppi(supportsStreamSettings: false),

  /// Gyro
  gyro,

  /// Magnetometer
  magnetometer,

  /// HR
  hr(supportsStreamSettings: false),

  /// Temperature
  temperature,

  /// Pressure
  pressure,

  /// skin temperature
  skinTemperature,

  /// location
  location;

  /// If this feature supports stream settings
  final bool supportsStreamSettings;

  /// Constructor
  const PolarDataType({this.supportsStreamSettings = true});

  /// Create a [PolarDataType] from json
  static PolarDataType fromJson(dynamic json) =>
      platformEnumFromJson(PolarDataType.values, json);

  /// Convert a [PolarDataType] to json
  dynamic toJson() => platformEnumToJson(this);
}
