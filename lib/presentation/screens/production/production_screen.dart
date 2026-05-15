import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_report.dart';
import '../../../data/providers/production_provider.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Consumer<ProductionProvider>(
      builder: (context, production, _) {
        return Scaffold(
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: cardColor,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    'Production',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: 'Today'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _TodayTab(production: production, isDark: isDark),
                  _HistoryTab(production: production, isDark: isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Today Tab ──────────────────────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  final ProductionProvider production;
  final bool isDark;

  const _TodayTab({required this.production, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    final totalEggs = production.todayTotalEggs;
    final layingRate = production.todayLayingRate;
    final feedConsumed = production.todayFeedConsumedKg;
    final fcr = production.todayFcr;
    final averageEggs = production.sevenDayAverageEggs;
    final trendPercent = production.eggTrendPercent;
    final trendIsPositive = (trendPercent ?? 0) >= 0;
    final trendColor =
        trendIsPositive ? AppColors.statusGood : AppColors.statusCritical;

    if (production.isLoadingToday) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ── Summary card ──────────────────────────────────────────────
        _SectionTitle(
          title: 'Today Overview',
          subtitle: 'Live production plus the latest daily report',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.egg_rounded,
                      color: AppColors.accent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalEggs != null ? '$totalEggs eggs' : '--',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Today\'s production count',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Laying Rate',
                      value: layingRate != null
                          ? '${layingRate.toStringAsFixed(1)}%'
                          : '--',
                      icon: Icons.show_chart_rounded,
                      iconColor: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Feed Consumed',
                      value: feedConsumed != null
                          ? '${feedConsumed.toStringAsFixed(1)} kg'
                          : '--',
                      icon: Icons.grain_rounded,
                      iconColor: AppColors.accent,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'FCR',
                      value: fcr != null ? fcr.toStringAsFixed(2) : '--',
                      icon: Icons.balance_rounded,
                      iconColor: AppColors.statusWarning,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: '7-day Avg Eggs',
                      value: averageEggs != null
                          ? averageEggs.toStringAsFixed(0)
                          : '--',
                      icon: Icons.calendar_view_week_rounded,
                      iconColor: AppColors.severityInfo,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      trendIsPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: trendColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trendPercent != null
                            ? '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}% vs 7-day average'
                            : 'Trend unavailable',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── 16-Belt Grid ─────────────────────────────────────────────
        _SectionTitle(
          title: '16-Belt Grid',
          subtitle: 'Each card shows the current egg count for a belt',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        production.beltSlots.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No belt data available',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: production.beltSlots.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.18,
                ),
                itemBuilder: (context, index) {
                  final slot = production.beltSlots[index];
                  return _BeltCard(slot: slot, isDark: isDark);
                },
              ),
      ],
    );
  }
}

// ─── History Tab ─────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final ProductionProvider production;
  final bool isDark;

  const _HistoryTab({required this.production, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    if (production.isLoadingHistory) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Exclude today's report from history display/chart to avoid duplication
    final todayDate = DateTime.now().toIso8601String().split('T')[0];
    final reports = production.historyReports
      .where((r) => r.date != todayDate)
      .toList()
      .reversed
      .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _SectionTitle(
          title: '7-Day History',
          subtitle: 'Daily production reports from Firestore',
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // ── Bar chart ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: reports.isEmpty
              ? const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'No history data available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _chartMaxY(reports),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _chartInterval(reports),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: _chartInterval(reports),
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= reports.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _formatShortDate(reports[index].date),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: reports.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.totalEggs.toDouble(),
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.primary,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 24),

        // ── Daily report rows ─────────────────────────────────────────
        _SectionTitle(
          title: 'Daily Reports',
          subtitle: 'Latest records sorted by date',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        ...reports.map(
          (report) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReportCard(report: report, isDark: isDark),
          ),
        ),
        if (production.error != null) ...[
          const SizedBox(height: 8),
          Text(
            production.error!,
            style: const TextStyle(
              color: AppColors.statusCritical,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor)),
        const SizedBox(height: 4),
        const Text(
          '',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Belt Card ───────────────────────────────────────────────────────────────
class _BeltCard extends StatelessWidget {
  final ProductionBeltSlot slot;
  final bool isDark;

  const _BeltCard({required this.slot, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slot.label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            slot.value != null ? '${slot.value}' : '--',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor),
          ),
        ],
      ),
    );
  }
}

// ─── Report Card ─────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final DailyReport report;
  final bool isDark;

  const _ReportCard({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.date,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 4),
                Text(
                  '${report.totalEggs} eggs • FCR ${report.fcr.toStringAsFixed(2)} • ${report.layingRatePct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('EEE').format(DateTime.parse(report.date)),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${report.feedConsumedKg.toStringAsFixed(1)} kg',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
double _chartMaxY(List<DailyReport> reports) {
  final maxEggs = reports
      .map((e) => e.totalEggs)
      .fold<int>(0, (max, value) => value > max ? value : max);
  return (maxEggs * 1.2).clamp(10, double.infinity).toDouble();
}

double _chartInterval(List<DailyReport> reports) {
  final maxEggs = reports
      .map((e) => e.totalEggs)
      .fold<int>(0, (max, value) => value > max ? value : max);
  if (maxEggs <= 5) return 1;
  if (maxEggs <= 50) return 10;
  if (maxEggs <= 250) return 25;
  return 50;
}

String _formatShortDate(String date) {
  try {
    return DateFormat('MM/dd').format(DateTime.parse(date));
  } catch (_) {
    return date;
  }
}