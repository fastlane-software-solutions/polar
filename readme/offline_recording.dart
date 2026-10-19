import 'package:flutter/foundation.dart';
import 'package:polar/polar.dart';

const identifier = 'ADF24B27';
final polar = Polar();

Future<void> recordOffline() async {
  // Record PPI to the device memory. Recording continues while disconnected.
  await polar.startOfflineRecording(identifier, PolarDataType.ppi);
}

Future<void> fetchOffline() async {
  await polar.stopOfflineRecording(identifier, PolarDataType.ppi);

  final entries = await polar.listOfflineRecordings(identifier);
  for (final entry in entries) {
    final record = await polar.getOfflineRecord(identifier, entry);
    if (record case PolarPpiOfflineRecording(:final data)) {
      debugPrint('PPI samples: ${data.samples.length}');
    }

    // Recordings are not removed automatically
    await polar.removeOfflineRecord(identifier, entry);
  }
}

Future<void> recordOnPowerOn() async {
  // Start recording PPI every time the device is switched on
  await polar.setOfflineRecordingTrigger(
    identifier,
    const PolarOfflineRecordingTrigger(
      triggerMode: PolarOfflineRecordingTriggerMode.triggerSystemStart,
      triggerFeatures: {PolarDataType.ppi: null},
    ),
  );
}
