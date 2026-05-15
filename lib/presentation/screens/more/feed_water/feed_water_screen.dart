import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/flock_defaults.dart';
import '../../../../data/providers/live_data_provider.dart';
import '../../../../data/providers/flock_config_provider.dart';
import '../../../../data/models/sensor_data.dart';
import '../../../../data/models/flock_config.dart';
import '../../../../l10n/generated/app_localizations.dart';

class FeedWaterScreen extends StatelessWidget {
  const FeedWaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.feedWater, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer2<LiveDataProvider, FlockConfigProvider>(
        builder: (context, live, flockConfigProvider, _) {
          final d = live.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              if (live.isStale)
                _StaleBanner(lastUpdate: live.lastUpdateText, l10n: l10n),
              if (live.isStale) const SizedBox(height: 12),

              _SectionLabel(text: 'Water Tanks', isDark: isDark),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _WaterCard(
                      label: l10n.h1Water,
                      pct: d?.h1WaterPct,
                      pumpState: d?.h1PumpState,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WaterCard(
                      label: l10n.h2Water,
                      pct: d?.h2WaterPct,
                      pumpState: d?.h2PumpState,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: 'Feed Hoppers', isDark: isDark),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FeedCard(
                      label: l10n.h1Feed,
                      kg: d?.h1FeedKg,
                      pct: d?.h1FeedPct,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeedCard(
                      label: l10n.h2Feed,
                      kg: d?.h2FeedKg,
                      pct: d?.h2FeedPct,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: 'Feed Estimate', isDark: isDark),
              const SizedBox(height: 10),
              _EstimateCard(
                data: d,
                flockConfig: flockConfigProvider.config,
                isDark: isDark,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  final String lastUpdate;
  final AppLocalizations l10n;
  const _StaleBanner({required this.lastUpdate, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusWarning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: AppColors.statusWarning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.dataMayBeOutdated(lastUpdate),
              style: const TextStyle(fontSize: 12, color: AppColors.statusWarning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final String label;
  final double? pct;
  final String? pumpState;
  final bool isDark;
  final AppLocalizations l10n;

  const _WaterCard({
    required this.label,
    required this.pct,
    required this.pumpState,
    required this.isDark,
    required this.l10n,
  });

  Color get _levelColor {
    if (pct == null) return AppColors.statusOffline;
    if (pct! < 20) return AppColors.statusCritical;
    if (pct! < 50) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  Color get _pumpColor {
    switch (pumpState) {
      case 'ON': return AppColors.statusGood;
      case 'FAULT': return AppColors.statusCritical;
      default: return AppColors.statusOffline;
    }
  }

  String _pumpLabel(AppLocalizations l10n) {
    switch (pumpState) {
      case 'ON': return 'Pump ON';
      case 'FAULT': return 'Pump FAULT';
      default: return 'Pump OFF';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final fillPct = (pct ?? 0).clamp(0.0, 100.0) / 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 14),
          Center(
            child: _CircularGauge(
              value: fillPct,
              color: _levelColor,
              label: pct != null ? '${pct!.toStringAsFixed(0)}%' : '--',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _pumpColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(_pumpLabel(l10n), style: TextStyle(fontSize: 11, color: _pumpColor, fontWeight: FontWeight.w600)),
            ],
          ),
          if (pumpState == 'FAULT')
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Check pump', style: TextStyle(fontSize: 10, color: AppColors.statusCritical)),
            ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String label;
  final double? kg;
  final double? pct;
  final bool isDark;
  final AppLocalizations l10n;

  const _FeedCard({
    required this.label,
    required this.kg,
    required this.pct,
    required this.isDark,
    required this.l10n,
  });

  Color get _levelColor {
    if (pct == null) return AppColors.statusOffline;
    if (pct! < 10) return AppColors.statusCritical;
    if (pct! < 30) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final fillPct = (pct ?? 0).clamp(0.0, 100.0) / 100.0;

    String statusText;
    if (_levelColor == AppColors.statusCritical) {
      statusText = 'Critically low';
    } else if (_levelColor == AppColors.statusWarning) {
      statusText = 'Low — schedule refill';
    } else {
      statusText = l10n.ok;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 14),
          Center(
            child: _CircularGauge(
              value: fillPct,
              color: _levelColor,
              label: pct != null ? '${pct!.toStringAsFixed(0)}%' : '--',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              kg != null ? '${kg!.toStringAsFixed(1)} kg' : '-- kg',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
          Center(
            child: Text(
              statusText,
              style: TextStyle(fontSize: 10, color: _levelColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularGauge extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  final bool isDark;

  const _CircularGauge({required this.value, required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final SensorData? data;
  final FlockConfig? flockConfig;
  final bool isDark;
  final AppLocalizations l10n;

  const _EstimateCard({
    required this.data,
    required this.flockConfig,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    final h1Kg = data?.h1FeedKg ?? 0;
    final h2Kg = data?.h2FeedKg ?? 0;
    final totalKg = h1Kg + h2Kg;
    final activeBirds = flockConfig?.effectiveBirdCount;
    final estimatedDailyKg = flockConfig?.estimatedDailyFeedKg();
    final daysRemaining = totalKg > 0 && estimatedDailyKg != null && estimatedDailyKg > 0
        ? totalKg / estimatedDailyKg
        : null;
    final feedRateText = flockConfig?.feedKgPerBirdPerDay ?? FlockDefaults.feedKgPerBirdPerDay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimated feed remaining',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  daysRemaining == null ? '--' : '${daysRemaining.toStringAsFixed(1)} days',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
                ),
                Text(
                  activeBirds == null
                      ? 'No active flock configured'
                      : activeBirds <= 0
                          ? 'Empty flock - no feed consumption'
                          : 'Based on ${totalKg.toStringAsFixed(1)} kg, $activeBirds birds, and ~${feedRateText.toStringAsFixed(3)} kg/bird/day',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}