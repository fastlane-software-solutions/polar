// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas, rexios_lints/not_null_assertion

part of 'polar_offline_recording.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarOfflineRecordingEntry _$PolarOfflineRecordingEntryFromJson(
  Map<String, dynamic> json,
) => PolarOfflineRecordingEntry(
  path: json['path'] as String,
  size: (json['size'] as num).toInt(),
  date: const UnixTimeConverter().fromJson((json['date'] as num).toInt()),
  type: PolarDataType.fromJson(json['type']),
);

Map<String, dynamic> _$PolarOfflineRecordingEntryToJson(
  PolarOfflineRecordingEntry instance,
) => <String, dynamic>{
  'path': instance.path,
  'size': instance.size,
  'date': const UnixTimeConverter().toJson(instance.date),
  'type': _dataTypeToJson(instance.type),
};

PolarOfflineRecordingProgress _$PolarOfflineRecordingProgressFromJson(
  Map<String, dynamic> json,
) => PolarOfflineRecordingProgress(
  bytesDownloaded: (json['bytesDownloaded'] as num).toInt(),
  totalBytes: (json['totalBytes'] as num).toInt(),
  progressPercent: (json['progressPercent'] as num).toInt(),
);

Map<String, dynamic> _$PolarOfflineRecordingProgressToJson(
  PolarOfflineRecordingProgress instance,
) => <String, dynamic>{
  'bytesDownloaded': instance.bytesDownloaded,
  'totalBytes': instance.totalBytes,
  'progressPercent': instance.progressPercent,
};

PolarOfflineRecordingTrigger _$PolarOfflineRecordingTriggerFromJson(
  Map<String, dynamic> json,
) => PolarOfflineRecordingTrigger(
  triggerMode: PolarOfflineRecordingTriggerMode.fromJson(json['triggerMode']),
  triggerFeatures: _triggerFeaturesFromJson(json['triggerFeatures'] as List),
);

Map<String, dynamic> _$PolarOfflineRecordingTriggerToJson(
  PolarOfflineRecordingTrigger instance,
) => <String, dynamic>{
  'triggerMode': _triggerModeToJson(instance.triggerMode),
  'triggerFeatures': _triggerFeaturesToJson(instance.triggerFeatures),
};
