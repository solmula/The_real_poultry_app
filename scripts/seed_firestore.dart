import 'dart:io';
import 'dart:math';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin;
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

const String _defaultProjectId = 'poultry-automation-93ae1';
const int _initialBirdCount = int.fromEnvironment('FLOCK_INITIAL_BIRDS', defaultValue: 0);

Future<void> main(List<String> arguments) async {
  final config = _SeedConfig.parse(arguments);
  final projectId = config.projectId ?? Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;

  if (projectId.isEmpty) {
    stderr.writeln('Missing Firebase project id. Set FIREBASE_PROJECT_ID environment variable or update the _defaultProjectId constant.');
    exitCode = 1;
    return;
  }

  final credential = await _resolveCredential(const _SeedConfig());
  if (credential == null) {
    stderr.writeln('\n✖ Failed to initialize Firebase Admin SDK');
    stderr.writeln('\nEnsure one of the following:');
    stderr.writeln('  1. GOOGLE_APPLICATION_CREDENTIALS env var points to a valid service account JSON file');
    stderr.writeln('  2. Run: gcloud auth application-default login');
    stderr.writeln('  3. Set up a .env file and source it before running this script');
    stderr.writeln('\nSee .env.example for detailed setup instructions.\n');
    exitCode = 1;
    return;
  }

  final app = admin.FirebaseApp.initializeApp(
    options: admin.AppOptions(
      credential: credential,
      projectId: projectId,
    ),
  );

  final firestore = app.firestore();
  final generator = _SeedGenerator();

  try {
    await _seedDailyReports(firestore, generator);
    await _seedSensorHistory(firestore, generator);
    stdout.writeln('Seeded Firestore collections daily_reports and sensor_history for project $projectId.');
  } catch (error) {
    stderr.writeln('Failed to seed Firestore: $error');
    stderr.writeln('Check credentials and permissions. See .env.example for setup details.');
    exitCode = 1;
  }
}

Future<admin.Credential?> _resolveCredential(_SeedConfig config) async {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SECURITY: Credentials from environment only — never from hardcoded paths
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Checks GOOGLE_APPLICATION_CREDENTIALS env var first, then falls back to
  // application default credentials (gcloud auth application-default login)

  final serviceAccountPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  if (serviceAccountPath != null && serviceAccountPath.trim().isNotEmpty) {
    final file = File(serviceAccountPath.trim());
    if (await file.exists()) {
      try {
        return admin.Credential.fromServiceAccount(file);
      } catch (e) {
        stderr.writeln('Error reading service account from $serviceAccountPath: $e');
        return null;
      }
    } else {
      stderr.writeln('Service account file not found at: $serviceAccountPath');
      return null;
    }
  }

  // Fallback to application default credentials
  try {
    return admin.Credential.fromApplicationDefaultCredentials();
  } catch (e) {
    stderr.writeln('Application default credentials not available: $e');
    return null;
  }
}

Future<void> _seedDailyReports(Firestore firestore, _SeedGenerator generator) async {
  final batch = firestore.batch();
  final today = DateTime.now();

  for (var dayIndex = 6; dayIndex >= 0; dayIndex--) {
    final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: dayIndex));
    final seed = generator.dailyReportForDay(dayIndex);
    final dateKey = _formatDate(date);

    batch.set(
      firestore.collection('daily_reports').doc(dateKey),
      {
        'date': dateKey,
        'total_eggs': seed.totalEggs,
        'laying_rate_pct': seed.layingRatePct,
        'feed_consumed_kg': seed.feedConsumedKg,
        'fcr': seed.fcr,
        'avg_temp': seed.avgTemp,
        'max_nh3': seed.maxNh3,
        'light_hours': seed.lightHours,
        'alerts_count': seed.alertsCount,
      },
    );
  }

  await batch.commit();
}

Future<void> _seedSensorHistory(Firestore firestore, _SeedGenerator generator) async {
  final batch = firestore.batch();
  final start = DateTime.now().subtract(const Duration(hours: 24));

  for (var sampleIndex = 0; sampleIndex < 48; sampleIndex++) {
    final timestamp = start.add(Duration(minutes: 30 * sampleIndex));
    final sample = generator.sensorSampleAt(sampleIndex, timestamp);
    final docId = timestamp.millisecondsSinceEpoch.toString();

    batch.set(
      firestore.collection('sensor_history').doc(docId),
      {
        'timestamp': Timestamp.fromDate(timestamp),
        'temp_avg': sample.tempAvg,
        'temp_min': sample.tempMin,
        'temp_max': sample.tempMax,
        'rh_avg': sample.rhAvg,
        'nh3_max': sample.nh3Max,
        'co2_avg': sample.co2Avg,
        'light_avg': sample.lightAvg,
        'h1_feed_kg': sample.h1FeedKg,
        'h2_feed_kg': sample.h2FeedKg,
        'h1_water_pct': sample.h1WaterPct,
        'h2_water_pct': sample.h2WaterPct,
        'eggs_total': sample.eggsTotal,
        'laying_rate': sample.layingRate,
      },
    );
  }

  await batch.commit();
}

String _formatDate(DateTime date) {
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _SeedConfig {
  final String? projectId;

  const _SeedConfig({this.projectId});

  factory _SeedConfig.parse(List<String> args) {
    String? projectId;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg.startsWith('--project-id=')) {
        projectId = arg.split('=').sublist(1).join('=');
      } else if (arg == '--project-id' && index + 1 < args.length) {
        projectId = args[++index];
      }
    }

    return _SeedConfig(projectId: projectId);
  }
}

class _DailyReportSeed {
  final int totalEggs;
  final double layingRatePct;
  final double feedConsumedKg;
  final double fcr;
  final double avgTemp;
  final double maxNh3;
  final double lightHours;
  final int alertsCount;

  const _DailyReportSeed({
    required this.totalEggs,
    required this.layingRatePct,
    required this.feedConsumedKg,
    required this.fcr,
    required this.avgTemp,
    required this.maxNh3,
    required this.lightHours,
    required this.alertsCount,
  });
}

class _SensorSampleSeed {
  final double tempAvg;
  final double tempMin;
  final double tempMax;
  final double rhAvg;
  final double nh3Max;
  final double co2Avg;
  final double lightAvg;
  final double h1FeedKg;
  final double h2FeedKg;
  final double h1WaterPct;
  final double h2WaterPct;
  final int eggsTotal;
  final double layingRate;

  const _SensorSampleSeed({
    required this.tempAvg,
    required this.tempMin,
    required this.tempMax,
    required this.rhAvg,
    required this.nh3Max,
    required this.co2Avg,
    required this.lightAvg,
    required this.h1FeedKg,
    required this.h2FeedKg,
    required this.h1WaterPct,
    required this.h2WaterPct,
    required this.eggsTotal,
    required this.layingRate,
  });
}

class _SeedGenerator {
  final Random _random = Random(93051);

  _DailyReportSeed dailyReportForDay(int dayIndex) {
    final trend = dayIndex / 6.0;
    final baselineEggs = 1160 + (trend * 60).round();
    final totalEggs = baselineEggs + _jitter(0, 18);
    final layingRatePct = _clampDouble(79.5 + (trend * 4.8) + _jitterDouble(-0.9, 1.1), 74.0, 90.0);
    final feedConsumedKg = _clampDouble(totalEggs * 0.059 + _jitterDouble(-2.4, 2.8), 64.0, 82.0);
    final fcr = feedConsumedKg / (totalEggs * 0.06);
    final avgTemp = _clampDouble(25.1 + _jitterDouble(-0.9, 1.1), 23.0, 28.0);
    final maxNh3 = _clampDouble(11.0 + _jitterDouble(-2.0, 6.0), 6.0, 24.0);
    final lightHours = _clampDouble(13.7 + _jitterDouble(-0.3, 0.5), 13.0, 14.8);
    final alertsCount = _jitter(0, 3);

    return _DailyReportSeed(
      totalEggs: totalEggs,
      layingRatePct: double.parse(layingRatePct.toStringAsFixed(1)),
      feedConsumedKg: double.parse(feedConsumedKg.toStringAsFixed(1)),
      fcr: double.parse(fcr.toStringAsFixed(2)),
      avgTemp: double.parse(avgTemp.toStringAsFixed(1)),
      maxNh3: double.parse(maxNh3.toStringAsFixed(1)),
      lightHours: double.parse(lightHours.toStringAsFixed(1)),
      alertsCount: alertsCount,
    );
  }

  _SensorSampleSeed sensorSampleAt(int sampleIndex, DateTime timestamp) {
    final dayPhase = (sampleIndex / 48.0) * pi * 2;
    final isDaytime = timestamp.hour >= 6 && timestamp.hour <= 18;
    final dailyLift = isDaytime ? 1.0 : -0.7;

    final tempAvg = _clampDouble(25.0 + sin(dayPhase) * 1.2 + dailyLift + _jitterDouble(-0.5, 0.5), 22.8, 28.2);
    final tempMin = tempAvg - (0.7 + _jitterDouble(0.0, 0.5));
    final tempMax = tempAvg + (0.8 + _jitterDouble(0.0, 0.8));
    final rhAvg = _clampDouble(66.0 + cos(dayPhase) * 4.2 + _jitterDouble(-1.5, 1.5), 58.0, 78.0);
    final nh3Max = _clampDouble(9.0 + max(0, sin(dayPhase - pi / 4)) * 5.5 + _jitterDouble(-1.0, 2.0), 5.0, 22.0);
    final co2Avg = _clampDouble(2200 + (isDaytime ? 350 : 120) + cos(dayPhase) * 160 + _jitterDouble(-120, 160), 1700, 3400);
    final lightAvg = isDaytime
        ? _clampDouble(3800 + sin(dayPhase) * 900 + _jitterDouble(-300, 300), 2500, 6200)
        : _clampDouble(35 + _jitterDouble(-10, 20), 0, 80);

    final baseFeed = 34.0 + (sampleIndex / 48.0) * 6.0;
    final h1FeedKg = _clampDouble(baseFeed + sin(dayPhase + 0.4) * 0.8 + _jitterDouble(-0.25, 0.25), 32.0, 42.0);
    final h2FeedKg = _clampDouble(baseFeed + sin(dayPhase + 1.0) * 0.9 + _jitterDouble(-0.25, 0.25), 31.5, 41.5);
    final h1WaterPct = _clampDouble(71.0 - (sampleIndex * 0.18) + _jitterDouble(-1.2, 1.2), 42.0, 74.0);
    final h2WaterPct = _clampDouble(69.0 - (sampleIndex * 0.17) + _jitterDouble(-1.2, 1.2), 40.0, 72.0);

    final eggsTotal = 1120 + (sampleIndex * 2) + _jitter(0, 3) + (isDaytime ? 12 : 0);
    final layingRate = _clampDouble(77.8 + (isDaytime ? 4.2 : 1.1) + sin(dayPhase - 0.6) * 1.8 + _jitterDouble(-0.8, 0.8), 72.0, 89.0);

    return _SensorSampleSeed(
      tempAvg: double.parse(tempAvg.toStringAsFixed(1)),
      tempMin: double.parse(tempMin.toStringAsFixed(1)),
      tempMax: double.parse(tempMax.toStringAsFixed(1)),
      rhAvg: double.parse(rhAvg.toStringAsFixed(1)),
      nh3Max: double.parse(nh3Max.toStringAsFixed(1)),
      co2Avg: double.parse(co2Avg.toStringAsFixed(0)),
      lightAvg: double.parse(lightAvg.toStringAsFixed(0)),
      h1FeedKg: double.parse(h1FeedKg.toStringAsFixed(1)),
      h2FeedKg: double.parse(h2FeedKg.toStringAsFixed(1)),
      h1WaterPct: double.parse(h1WaterPct.toStringAsFixed(1)),
      h2WaterPct: double.parse(h2WaterPct.toStringAsFixed(1)),
      eggsTotal: eggsTotal,
      layingRate: double.parse(layingRate.toStringAsFixed(1)),
    );
  }

  int _jitter(int minValue, int maxValue) => minValue + _random.nextInt(maxValue - minValue + 1);

  double _jitterDouble(double minValue, double maxValue) => minValue + _random.nextDouble() * (maxValue - minValue);

  double _clampDouble(double value, double minValue, double maxValue) => value.clamp(minValue, maxValue).toDouble();
}
