import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/providers/live_data_provider.dart';
import '../../../data/providers/alert_provider.dart';
import '../../../data/models/sensor_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.cardDark
        : AppColors.cardLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<LiveDataProvider, AlertProvider>(
          builder: (context, live, alerts, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context, live),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (live.error != null) _buildErrorBanner(live.error!),
                        if (live.isStale && !live.isLoading)
                          _buildStaleBanner(live.lastUpdateText),
                        const SizedBox(height: 16),
                        _buildSystemStatus(context, live.data),
                        const SizedBox(height: 24),
                        _sectionLabel(context, 'Climate'),
                        const SizedBox(height: 12),
                        _buildClimateGrid(context, live.data),
                        const SizedBox(height: 24),
                        _sectionLabel(context, 'Feed & Water'),
                        const SizedBox(height: 12),
                        _buildFeedWaterGrid(context, live.data),
                        const SizedBox(height: 24),
                        _sectionLabel(context, 'Egg Production'),
                        const SizedBox(height: 12),
                        _buildEggCard(context, live.data),
                        const SizedBox(height: 24),
                        if (alerts.activeCount > 0) ...[
                          _sectionLabel(context, 'Active Alerts'),
                          const SizedBox(height: 12),
                          _buildAlertSummary(context, alerts),
                          const SizedBox(height: 12),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, LiveDataProvider live) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: _cardColor(context),
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poultry House',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          Text(
            live.isLoading ? 'Loading...' : 'Updated ${live.lastUpdateText}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        if (live.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusCritical.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusCritical.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.statusCritical, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                  color: AppColors.statusCritical,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaleBanner(String lastUpdate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusWarning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              color: AppColors.statusWarning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data may be outdated — last update: $lastUpdate',
              style: const TextStyle(
                  color: AppColors.statusWarning,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(BuildContext context, SensorData? data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nodeA = data?.nodeAOnline ?? false;
    final nodeB = data?.nodeBOnline ?? false;
    final isOnline = nodeA && nodeB;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? AppColors.statusGood.withOpacity(0.4)
              : AppColors.statusWarning.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                  ? AppColors.statusGood
                  : AppColors.statusWarning,
              boxShadow: [
                BoxShadow(
                  color: (isOnline
                          ? AppColors.statusGood
                          : AppColors.statusWarning)
                      .withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOnline
                  ? 'All systems online'
                  : !nodeA
                      ? 'Node A offline — no sensor data'
                      : 'Node B offline — limited data',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
          ),
          if (data?.firmwareVer != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'v${data!.firmwareVer}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildClimateGrid(BuildContext context, SensorData? d) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _SensorCard(
          icon: Icons.thermostat_rounded,
          label: 'Temperature',
          value: AppUtils.formatValue(d?.tempAvg, '°C'),
          subtitle: d?.tempAvg == null
              ? null
              : 'Min ${AppUtils.formatValue(d?.tempMin, '°C')}  Max ${AppUtils.formatValue(d?.tempMax, '°C')}',
          valueColor: AppUtils.tempColor(d?.tempAvg),
        ),
        _SensorCard(
          icon: Icons.water_drop_rounded,
          label: 'Humidity',
          value: AppUtils.formatValue(d?.rhAvg, '%', decimals: 0),
          valueColor: AppUtils.humidityColor(d?.rhAvg),
        ),
        _SensorCard(
          icon: Icons.air_rounded,
          label: 'Ammonia (NH₃)',
          value: AppUtils.formatValue(d?.nh3Max, ' ppm'),
          valueColor: AppUtils.nh3Color(d?.nh3Max),
        ),
        _SensorCard(
          icon: Icons.cloud_outlined,
          label: 'CO₂',
          value: AppUtils.formatValue(d?.co2Avg, ' ppm', decimals: 0),
          valueColor: (d?.co2Avg ?? 0) >= 3000
              ? AppColors.statusWarning
              : AppColors.statusGood,
        ),
        _SensorCard(
          icon: Icons.wb_sunny_rounded,
          label: 'Light',
          value: AppUtils.formatValue(d?.lightAvg, ' lux', decimals: 0),
          subtitle: d?.lights,
        ),
        _SensorCard(
          icon: Icons.wind_power_rounded,
          label: 'Fan Speed',
          value: d?.fanSpeed ?? '--',
          subtitle: d?.heater == true ? '🔥 Heater ON' : null,
          subtitleColor: AppColors.statusWarning,
        ),
      ],
    );
  }

  Widget _buildFeedWaterGrid(BuildContext context, SensorData? d) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LevelCard(
                label: 'H1 Water',
                percent: d?.h1WaterPct,
                subtitle: d?.h1PumpState,
                icon: Icons.water_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LevelCard(
                label: 'H2 Water',
                percent: d?.h2WaterPct,
                subtitle: d?.h2PumpState,
                icon: Icons.water_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LevelCard(
                label: 'H1 Feed',
                percent: d?.h1FeedPct,
                subtitle: d?.h1FeedKg != null
                    ? '${d!.h1FeedKg!.toStringAsFixed(1)} kg'
                    : null,
                icon: Icons.set_meal_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LevelCard(
                label: 'H2 Feed',
                percent: d?.h2FeedPct,
                subtitle: d?.h2FeedKg != null
                    ? '${d!.h2FeedKg!.toStringAsFixed(1)} kg'
                    : null,
                icon: Icons.set_meal_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEggCard(BuildContext context, SensorData? d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.egg_rounded,
                color: AppColors.accent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Eggs",
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  AppUtils.formatInt(d?.totalToday),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Laying Rate',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                d?.layingRate != null
                    ? '${d!.layingRate!.toStringAsFixed(1)}%'
                    : '--',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: (d?.layingRate ?? 0) >= 80
                      ? AppColors.statusGood
                      : AppColors.statusWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary(BuildContext context, AlertProvider alerts) {
    final top = alerts.activeAlerts.take(3).toList();
    return Column(
      children: top.map((alert) {
        final color = AppUtils.severityColor(alert.severity);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.parameterLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.displayText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sensor Card ───────────────────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Color? subtitleColor;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor ?? textColor,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor ?? AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

// ─── Level Card ────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final String label;
  final double? percent;
  final String? subtitle;
  final IconData icon;

  const _LevelCard({
    required this.label,
    required this.percent,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final color = AppUtils.levelColor(percent);
    final pct = percent ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            percent == null ? '--' : '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}