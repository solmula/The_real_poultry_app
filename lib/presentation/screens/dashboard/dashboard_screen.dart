import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/live_data_provider.dart';
import '../../../data/providers/alert_provider.dart';
import '../../../data/models/sensor_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../more/settings/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToAlerts;
  const DashboardScreen({super.key, this.onNavigateToAlerts});

  Color _cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.cardDark
        : AppColors.cardLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer3<AuthProvider, LiveDataProvider, AlertProvider>(
          builder: (context, auth, live, alerts, _) {
            final isFirstLoad = live.isLoading && live.data == null;
            final l10n = AppLocalizations.of(context);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context, auth, live, l10n),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (live.error != null) _buildErrorBanner(live.error!),
                        if (live.isStale && !live.isLoading)
                          _buildStaleBanner(live.lastUpdateText, l10n),
                        const SizedBox(height: 16),
                        if (isFirstLoad) ...[
                          const _ShimmerBox(height: 48, borderRadius: 14),
                          const SizedBox(height: 24),
                          _shimmerSectionLabel(),
                          const SizedBox(height: 12),
                          _ShimmerClimateGrid(),
                          const SizedBox(height: 24),
                          _shimmerSectionLabel(),
                          const SizedBox(height: 12),
                          _ShimmerFeedWaterGrid(),
                          const SizedBox(height: 24),
                          _shimmerSectionLabel(),
                          const SizedBox(height: 12),
                          const _ShimmerBox(height: 90, borderRadius: 16),
                        ] else ...[
                          _buildSystemStatus(context, live.data, l10n),
                          const SizedBox(height: 24),
                          _sectionLabel(context, l10n.climate),
                          const SizedBox(height: 12),
                          _buildClimateGrid(context, live.data, l10n),
                          const SizedBox(height: 24),
                          _sectionLabel(context, l10n.feedAndWater),
                          const SizedBox(height: 12),
                          _buildFeedWaterGrid(context, live.data, l10n),
                          const SizedBox(height: 24),
                          _sectionLabel(context, l10n.eggProduction),
                          const SizedBox(height: 12),
                          _buildEggCard(context, live.data, l10n),
                          const SizedBox(height: 24),
                          if (alerts.activeCount > 0) ...[
                            _sectionLabel(context, l10n.activeAlerts),
                            const SizedBox(height: 12),
                            _buildAlertSummary(context, alerts),
                            const SizedBox(height: 12),
                          ],
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

  Widget _shimmerSectionLabel() =>
      const _ShimmerBox(height: 18, width: 100, borderRadius: 6);

    Widget _buildAppBar(BuildContext context, AuthProvider auth,
      LiveDataProvider live, AppLocalizations l10n) {
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
            l10n.poultryHouse,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          Text(
            live.isLoading && live.data == null
                ? l10n.connecting
                : live.isLoading
                    ? l10n.refreshing
                    : '${l10n.updated} ${live.lastUpdateText}',
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
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: isDark ? AppColors.textLight : AppColors.textPrimary),
          onPressed: () => onNavigateToAlerts?.call(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: _AccountAvatar(
              email: auth.user?.email,
              role: auth.role,
            ),
            onPressed: () => _showAccountSheet(context, auth),
            tooltip: 'Account',
          ),
        ),
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

  void _showAccountSheet(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final role = auth.role ?? 'operator';
    final roleColor = role == 'admin'
        ? AppColors.primary
        : role == 'viewer'
            ? AppColors.statusOffline
            : AppColors.severityInfo;
    final roleLabel = role == 'admin'
        ? 'Admin'
        : role == 'viewer'
            ? 'Viewer'
            : 'Operator';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user?.email ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _BottomSheetAction(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _BottomSheetAction(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await auth.signOut();
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
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
            child: Text(error,
                style: const TextStyle(
                    color: AppColors.statusCritical,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStaleBanner(String lastUpdate, AppLocalizations l10n) {
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
              l10n.dataMayBeOutdated(lastUpdate),
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

  Widget _buildSystemStatus(BuildContext context, SensorData? data,
      AppLocalizations l10n) {
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
              color: isOnline ? AppColors.statusGood : AppColors.statusWarning,
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
                  ? l10n.allSystemsOnline
                  : !nodeA
                      ? l10n.nodeAOffline
                      : l10n.nodeBOffline,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
          ),
          if (data?.firmwareVer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('v${data!.firmwareVer}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? AppColors.textLight : AppColors.textPrimary,
        ));
  }

  Widget _buildClimateGrid(BuildContext context, SensorData? d,
      AppLocalizations l10n) {
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
          label: l10n.temperature,
          value: AppUtils.formatValue(d?.tempAvg, '°C'),
          subtitle: d?.tempAvg == null
              ? null
              : 'Min ${AppUtils.formatValue(d?.tempMin, '°C')}  Max ${AppUtils.formatValue(d?.tempMax, '°C')}',
          valueColor: AppUtils.tempColor(d?.tempAvg),
        ),
        _SensorCard(
          icon: Icons.water_drop_rounded,
          label: l10n.humidity,
          value: AppUtils.formatValue(d?.rhAvg, '%', decimals: 0),
          valueColor: AppUtils.humidityColor(d?.rhAvg),
        ),
        _SensorCard(
          icon: Icons.air_rounded,
          label: l10n.ammonia,
          value: AppUtils.formatValue(d?.nh3Max, ' ppm'),
          valueColor: AppUtils.nh3Color(d?.nh3Max),
        ),
        _SensorCard(
          icon: Icons.cloud_outlined,
          label: l10n.co2,
          value: AppUtils.formatValue(d?.co2Avg, ' ppm', decimals: 0),
          valueColor: (d?.co2Avg ?? 0) >= 3000
              ? AppColors.statusWarning
              : AppColors.statusGood,
        ),
        _SensorCard(
          icon: Icons.wb_sunny_rounded,
          label: l10n.light,
          value: AppUtils.formatValue(d?.lightAvg, ' lux', decimals: 0),
          subtitle: d?.lights,
        ),
        _SensorCard(
          icon: Icons.wind_power_rounded,
          label: l10n.fanSpeed,
          value: d?.fanSpeed ?? '--',
          subtitle: d?.heater == true ? '🔥 ${l10n.heaterOn}' : null,
          subtitleColor: AppColors.statusWarning,
        ),
      ],
    );
  }

  Widget _buildFeedWaterGrid(BuildContext context, SensorData? d,
      AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LevelCard(
                label: l10n.h1Water,
                percent: d?.h1WaterPct,
                subtitle: d?.h1PumpState,
                icon: Icons.water_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LevelCard(
                label: l10n.h2Water,
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
                label: l10n.h1Feed,
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
                label: l10n.h2Feed,
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

  Widget _buildEggCard(BuildContext context, SensorData? d,
      AppLocalizations l10n) {
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
                Text(l10n.todaysEggs,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  AppUtils.formatInt(d?.totalToday),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l10n.layingRate,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
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
                      BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.parameterLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(alert.displayText,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
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

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  const _ShimmerBox(
      {required this.height, this.width, required this.borderRadius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final highlight = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.10);

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            stops: const [0.0, 0.5, 1.0],
            colors: [base, highlight, base],
            transform: _SlidingGradientTransform(_animation.value),
          ),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
}

class _ShimmerClimateGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.cardDark
        : AppColors.cardLight;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(
        6,
        (_) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(height: 10, width: 80, borderRadius: 4),
              _ShimmerBox(height: 28, width: 70, borderRadius: 6),
              _ShimmerBox(height: 10, width: 60, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerFeedWaterGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.cardDark
        : AppColors.cardLight;
    Widget card() => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(height: 10, width: 60, borderRadius: 4),
              SizedBox(height: 10),
              _ShimmerBox(height: 24, width: 50, borderRadius: 6),
              SizedBox(height: 8),
              _ShimmerBox(height: 6, borderRadius: 4),
            ],
          ),
        );
    return Column(children: [
      Row(children: [
        Expanded(child: card()),
        const SizedBox(width: 12),
        Expanded(child: card())
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: card()),
        const SizedBox(width: 12),
        Expanded(child: card())
      ]),
    ]);
  }
}

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
          color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? textColor)),
          if (subtitle != null)
            Text(subtitle!,
                style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor ?? AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String label;
  final double? percent;
  final String? subtitle;
  final IconData icon;

  const _LevelCard(
      {required this.label,
      required this.percent,
      required this.icon,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final color = AppUtils.levelColor(percent);
    final pct = percent ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),
          Text(
            percent == null ? '--' : '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: color),
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
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  final String? email;
  final String? role;

  const _AccountAvatar({this.email, this.role});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.primaryLight : AppColors.primary;
    final initials = _initialsFromEmail(email);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: background.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: background,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _initialsFromEmail(String? value) {
    if (value == null || value.isEmpty) return 'U';
    final prefix = value.split('@').first;
    final parts = prefix
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'));
    if (parts.isEmpty) return prefix.substring(0, 1).toUpperCase();
    if (parts.length == 1) {
      final token = parts.first;
      return token.length >= 2
          ? token.substring(0, 2).toUpperCase()
          : token.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _BottomSheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _BottomSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive
        ? AppColors.statusCritical
        : isDark
            ? AppColors.textLight
            : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.statusCritical.withOpacity(0.08)
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}