import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

/// Example app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const identifier = 'D780C525'; // H10
  // static const identifier = 'ADF24B27'; // Verity
  // static const identifier = 'E5C32C2E'; // Polar 360

  final polar = Polar();
  final logs = ['Service started'];

  PolarExerciseEntry? exerciseEntry;
  PolarOfflineRecordingEntry? offlineRecordingEntry;

  @override
  void initState() {
    super.initState();

    // polar
    //     .searchForDevice()
    //     .listen((e) => log('Found device in scan: ${e.deviceId}'));
    polar.batteryLevel.listen((e) => log('Battery: ${e.level}'));
    polar.deviceConnecting.listen((_) => log('Device connecting'));
    polar.deviceConnected.listen((_) => log('Device connected'));
    polar.deviceDisconnected.listen((_) => log('Device disconnected'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.fiber_manual_record),
              itemBuilder: (context) => RecordingAction.values
                  .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onSelected: handleRecordingAction,
            ),
            PopupMenuButton(
              icon: const Icon(Icons.save),
              itemBuilder: (context) => OfflineRecordingAction.values
                  .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onSelected: handleOfflineRecordingAction,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                log('Disconnecting from device: $identifier');
                polar.disconnectFromDevice(identifier);
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                log('Connecting to device: $identifier');
                polar.connectToDevice(identifier);
                streamWhenReady();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(10),
          shrinkWrap: true,
          children: logs.reversed.map(Text.new).toList(),
        ),
      ),
    );
  }

  void streamWhenReady() async {
    final readiness = await polar.sdkFeaturesReadiness.firstWhere(
      (e) => e.identifier == identifier,
    );

    if (readiness.ready.contains(PolarSdkFeature.hr)) {
      final availableHrTypes = await polar.getAvailableHrServiceDataTypes(
        identifier,
      );
      debugPrint('available hr types: $availableHrTypes');

      if (availableHrTypes.contains(PolarDataType.hr)) {
        polar
            .startHrStreaming(identifier)
            .listen((e) => log('Heart rate: ${e.samples.map((e) => e.hr)}'));
      }
    }

    if (readiness.ready.contains(PolarSdkFeature.onlineStreaming)) {
      final availableStreamTypes =
          await polar.getAvailableOnlineStreamDataTypes(identifier);
      debugPrint('available stream types: $availableStreamTypes');

      if (availableStreamTypes.contains(PolarDataType.ecg)) {
        polar
            .startEcgStreaming(identifier)
            .listen((e) => log('ECG data received'));
      }
      if (availableStreamTypes.contains(PolarDataType.acc)) {
        polar
            .startAccStreaming(identifier)
            .listen((e) => log('ACC data received'));
      }
    }
  }

  void log(String log) {
    debugPrint(log);
    setState(() {
      logs.add(log);
    });
  }

  Future<void> handleRecordingAction(RecordingAction action) async {
    switch (action) {
      case RecordingAction.start:
        log('Starting recording');
        await polar.startRecording(
          identifier,
          exerciseId: const Uuid().v4(),
          interval: RecordingInterval.interval_1s,
          sampleType: SampleType.rr,
        );
        log('Started recording');
        break;
      case RecordingAction.stop:
        log('Stopping recording');
        await polar.stopRecording(identifier);
        log('Stopped recording');
        break;
      case RecordingAction.status:
        log('Getting recording status');
        final status = await polar.requestRecordingStatus(identifier);
        log('Recording status: $status');
        break;
      case RecordingAction.list:
        log('Listing recordings');
        final entries = await polar.listExercises(identifier);
        log('Recordings: $entries');
        // H10 can only store one recording at a time
        exerciseEntry = entries.first;
        break;
      case RecordingAction.fetch:
        log('Fetching recording');
        final exerciseEntry = this.exerciseEntry;
        if (exerciseEntry == null) {
          log('Exercises not yet listed');
          return;
        }
        final entry = await polar.fetchExercise(identifier, exerciseEntry);
        log('Fetched recording: $entry');
        break;
      case RecordingAction.remove:
        log('Removing recording');
        final exerciseEntry = this.exerciseEntry;
        if (exerciseEntry == null) {
          log('No exercise to remove. Try calling list first.');
          return;
        }
        await polar.removeExercise(identifier, exerciseEntry);
        log('Removed recording');
        break;
    }
  }

  Future<void> handleOfflineRecordingAction(
    OfflineRecordingAction action,
  ) async {
    const type = PolarDataType.ppi;
    switch (action) {
      case OfflineRecordingAction.start:
        log('Starting offline recording');
        await polar.startOfflineRecording(identifier, type);
        log('Started offline recording');
        break;
      case OfflineRecordingAction.stop:
        log('Stopping offline recording');
        await polar.stopOfflineRecording(identifier, type);
        log('Stopped offline recording');
        break;
      case OfflineRecordingAction.status:
        log('Getting offline recording status');
        final status = await polar.getOfflineRecordingStatus(identifier);
        log('Offline recording status: $status');
        break;
      case OfflineRecordingAction.list:
        log('Listing offline recordings');
        final entries = await polar.listOfflineRecordings(identifier);
        log('Offline recordings: $entries');
        final typeEntries = entries.where((e) => e.type == type);
        offlineRecordingEntry = typeEntries.isEmpty ? null : typeEntries.first;
        break;
      case OfflineRecordingAction.fetch:
        log('Fetching offline recording');
        final entry = offlineRecordingEntry;
        if (entry == null) {
          log('Offline recordings not yet listed');
          return;
        }
        await for (final result in polar.getOfflineRecordWithProgress(
          identifier,
          entry,
        )) {
          if (result is PolarOfflineRecordingProgress) {
            log('Fetching offline recording: ${result.progressPercent}%');
          } else if (result is PolarOfflineRecordingComplete) {
            final samples = result.data.data?.samples.length;
            log('Fetched offline recording: $samples samples');
          }
        }
        break;
      case OfflineRecordingAction.remove:
        log('Removing offline recording');
        final entry = offlineRecordingEntry;
        if (entry == null) {
          log('No offline recording to remove. Try calling list first.');
          return;
        }
        await polar.removeOfflineRecord(identifier, entry);
        offlineRecordingEntry = null;
        log('Removed offline recording');
        break;
      case OfflineRecordingAction.setTrigger:
        log('Setting offline recording trigger');
        await polar.setOfflineRecordingTrigger(
          identifier,
          const PolarOfflineRecordingTrigger(
            triggerMode: PolarOfflineRecordingTriggerMode.triggerSystemStart,
            triggerFeatures: {type: null},
          ),
        );
        log('Set offline recording trigger');
        break;
      case OfflineRecordingAction.getTrigger:
        log('Getting offline recording trigger');
        final trigger = await polar.getOfflineRecordingTriggerSetup(identifier);
        log('Offline recording trigger: $trigger');
        break;
      case OfflineRecordingAction.disableTrigger:
        log('Disabling offline recording trigger');
        await polar.setOfflineRecordingTrigger(
          identifier,
          const PolarOfflineRecordingTrigger(
            triggerMode: PolarOfflineRecordingTriggerMode.triggerDisabled,
            triggerFeatures: {},
          ),
        );
        log('Disabled offline recording trigger');
        break;
    }
  }
}

enum OfflineRecordingAction {
  start,
  stop,
  status,
  list,
  fetch,
  remove,
  setTrigger,
  getTrigger,
  disableTrigger,
}

enum RecordingAction {
  start,
  stop,
  status,
  list,
  fetch,
  remove,
}
