import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_report.dart';
import '../../../core/constants/firebase_paths.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DailyReport> _reports = [];
  bool _loading = true;
  String? _error;
  int _rangeDays = 14; // 7, 14, 30

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirebasePaths.dailyReports)
          .orderBy('date', descending: true)
          .limit(_rangeDays)
          .get();
      final reports =
          snap.docs.map((d) => DailyReport.fromFirestore(d)).toList();
      setState(() {
        _reports = reports.reversed.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: cardColor,
              surfaceTintColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      )),
                  Text(
                    _reports.isEmpty
                        ? 'No data'
                        : 'Last ${_reports.length} days',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                // Range selector
                _RangeButton(
                  selected: _rangeDays,
                  isDark: isDark,
                  onSelect: (days) {
                    setState(() => _rangeDays = days);
                    _loadReports();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: textColor),
                  onPressed: _loadReports,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Eggs'),
                  Tab(text: 'Climate'),
                  Tab(text: 'Feed'),
                  Tab(text: 'Alerts'),
                ],
              ),
            ),
          ],
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary))
              : _error != null
                  ? _buildError()
                  : _reports.isEmpty
                      ? _buildEmpty(isDark)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEggsTab(isDark),
                            _buildClimateTab(isDark),
                            _buildFeedTab(isDark),
                            _buildAlertsTab(isDark),
                          ],
                        ),
        ),
      ),
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────────────

  Widget _buildEggsTab(bool isDark) {
    return _RefreshableTab(
      onRefresh: _loadReports,
      children: [
        _ChartCard(
          title: 'Daily Eggs',
          subtitle: 'Total eggs collected per day',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.totalEggs.toDouble(),
            color: AppColors.accent,
            isDark: isDark,
            unit: '',
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Laying Rate',
          subtitle: 'Percentage of hens laying per day',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.layingRatePct,
            color: AppColors.statusGood,
            isDark: isDark,
            unit: '%',
            minY: 0,
            maxY: 100,
          ),
        ),
        const SizedBox(height: 16),
        _SummaryTable(reports: _reports, isDark: isDark),
      ],
    );
  }

  Widget _buildClimateTab(bool isDark) {
    return _RefreshableTab(
      onRefresh: _loadReports,
      children: [
        _ChartCard(
          title: 'Average Temperature',
          subtitle: 'Daily avg temp °C',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.avgTemp,
            color: AppColors.statusWarning,
            isDark: isDark,
            unit: '°C',
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Max Ammonia (NH₃)',
          subtitle: 'Peak NH₃ level per day (ppm)',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.maxNh3,
            color: AppColors.severityHigh,
            isDark: isDark,
            unit: ' ppm',
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Light Hours',
          subtitle: 'Hours of light per day',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.lightHours,
            color: AppColors.primaryLight,
            isDark: isDark,
            unit: 'h',
            minY: 0,
            maxY: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedTab(bool isDark) {
    return _RefreshableTab(
      onRefresh: _loadReports,
      children: [
        _ChartCard(
          title: 'Feed Consumed',
          subtitle: 'Total feed consumed per day (kg)',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.feedConsumedKg,
            color: AppColors.primary,
            isDark: isDark,
            unit: ' kg',
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Feed Conversion Ratio (FCR)',
          subtitle: 'Feed kg per egg kg — lower is better',
          isDark: isDark,
          chart: _LineChart(
            reports: _reports,
            getValue: (r) => r.fcr,
            color: AppColors.severityInfo,
            isDark: isDark,
            unit: '',
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab(bool isDark) {
    return _RefreshableTab(
      onRefresh: _loadReports,
      children: [
        _ChartCard(
          title: 'Daily Alert Count',
          subtitle: 'Number of alerts triggered per day',
          isDark: isDark,
          chart: _BarChart(reports: _reports, isDark: isDark),
        ),
        const SizedBox(height: 16),
        _AlertStatsCard(reports: _reports, isDark: isDark),
      ],
    );
  }

  // ─── Empty / Error ────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 56,
              color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          const Text(
            'Daily reports will appear here\nonce data starts coming in.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.statusCritical),
            const SizedBox(height: 16),
            const Text('Failed to load history',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusCritical)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Range Button ──────────────────────────────────────────────────────────
class _RangeButton extends StatelessWidget {
  final int selected;
  final bool isDark;
  final void Function(int) onSelect;

  const _RangeButton(
      {required this.selected,
      required this.isDark,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      initialValue: selected,
      onSelected: onSelect,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${selected}d',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
      itemBuilder: (_) => [7, 14, 30]
          .map((d) => PopupMenuItem(
                value: d,
                child: Text('Last $d days',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: d == selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: d == selected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary),
                    )),
              ))
          .toList(),
    );
  }
}

// ─── Refreshable tab wrapper ───────────────────────────────────────────────
class _RefreshableTab extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;

  const _RefreshableTab(
      {required this.children, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: children,
      ),
    );
  }
}

// ─── Chart card wrapper ────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final bool isDark;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: chart),
        ],
      ),
    );
  }
}

// ─── Line Chart ────────────────────────────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<DailyReport> reports;
  final double Function(DailyReport) getValue;
  final Color color;
  final bool isDark;
  final String unit;
  final double? minY;
  final double? maxY;

  const _LineChart({
    required this.reports,
    required this.getValue,
    required this.color,
    required this.isDark,
    required this.unit,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final spots = reports.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value));
    }).toList();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}$unit',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (reports.length / 5).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= reports.length) {
                  return const SizedBox.shrink();
                }
                final date = reports[idx].date;
                final parts = date.split('-');
                final label = parts.length >= 3
                    ? '${parts[1]}/${parts[2]}'
                    : date;
                return Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary));
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: reports.length <= 10,
              getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final date =
                  idx < reports.length ? reports[idx].date : '';
              return LineTooltipItem(
                '$date\n${s.y.toStringAsFixed(1)}$unit',
                TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Bar Chart (alerts) ────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<DailyReport> reports;
  final bool isDark;

  const _BarChart({required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= reports.length) {
                  return const SizedBox.shrink();
                }
                if (idx % (reports.length ~/ 5 + 1) != 0) {
                  return const SizedBox.shrink();
                }
                final date = reports[idx].date;
                final parts = date.split('-');
                final label = parts.length >= 3
                    ? '${parts[1]}/${parts[2]}'
                    : date;
                return Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary));
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: reports.asMap().entries.map((e) {
          final count = e.value.alertsCount.toDouble();
          final color = count == 0
              ? AppColors.statusGood
              : count <= 3
                  ? AppColors.statusWarning
                  : AppColors.statusCritical;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: count,
                color: color,
                width: reports.length > 20 ? 6 : 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Alert Stats Card ──────────────────────────────────────────────────────
class _AlertStatsCard extends StatelessWidget {
  final List<DailyReport> reports;
  final bool isDark;

  const _AlertStatsCard(
      {required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    if (reports.isEmpty) return const SizedBox.shrink();

    final total =
        reports.fold<int>(0, (sum, r) => sum + r.alertsCount);
    final avg = total / reports.length;
    final maxAlerts =
        reports.map((r) => r.alertsCount).reduce((a, b) => a > b ? a : b);
    final quietDays =
        reports.where((r) => r.alertsCount == 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alert Summary',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _StatChip(
                      label: 'Total',
                      value: '$total',
                      color: AppColors.statusWarning)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatChip(
                      label: 'Avg/day',
                      value: avg.toStringAsFixed(1),
                      color: AppColors.severityInfo)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatChip(
                      label: 'Max/day',
                      value: '$maxAlerts',
                      color: AppColors.statusCritical)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatChip(
                      label: 'Clear days',
                      value: '$quietDays',
                      color: AppColors.statusGood)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Summary Table ─────────────────────────────────────────────────────────
class _SummaryTable extends StatelessWidget {
  final List<DailyReport> reports;
  final bool isDark;

  const _SummaryTable(
      {required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final last7 =
        reports.length > 7 ? reports.sublist(reports.length - 7) : reports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 Days',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(flex: 3, child: _TableHeader('Date')),
              Expanded(flex: 2, child: _TableHeader('Eggs')),
              Expanded(flex: 2, child: _TableHeader('Rate %')),
              Expanded(flex: 2, child: _TableHeader('Feed kg')),
            ],
          ),
          const Divider(height: 16),
          ...last7.reversed.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text(r.date,
                            style: TextStyle(
                                fontSize: 12, color: textColor))),
                    Expanded(
                        flex: 2,
                        child: Text('${r.totalEggs}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            '${r.layingRatePct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 12,
                                color: r.layingRatePct >= 80
                                    ? AppColors.statusGood
                                    : AppColors.statusWarning))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            r.feedConsumedKg.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12,
                                color: textColor))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }
}