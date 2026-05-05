import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/daily_report.dart';
import '../../../data/providers/threshold_provider.dart';
import '../../../data/models/threshold_model.dart';
import '../../../core/constants/firebase_paths.dart';
import '../../../l10n/generated/app_localizations.dart';

// ── Sensor history record (from Firestore sensor_history collection) ────────
class _SensorRecord {
  final DateTime timestamp;
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
  final double eggsTotal;
  final double layingRate;

  const _SensorRecord({
    required this.timestamp,
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

  factory _SensorRecord.fromFirestore(Map<String, dynamic> data) {
    DateTime ts;
    final raw = data['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else {
      ts = DateTime.now();
    }
    return _SensorRecord(
      timestamp: ts,
      tempAvg: _d(data['temp_avg']),
      tempMin: _d(data['temp_min']),
      tempMax: _d(data['temp_max']),
      rhAvg: _d(data['rh_avg']),
      nh3Max: _d(data['nh3_max']),
      co2Avg: _d(data['co2_avg']),
      lightAvg: _d(data['light_avg']),
      h1FeedKg: _d(data['h1_feed_kg']),
      h2FeedKg: _d(data['h2_feed_kg']),
      h1WaterPct: _d(data['h1_water_pct']),
      h2WaterPct: _d(data['h2_water_pct']),
      eggsTotal: _d(data['eggs_total']),
      layingRate: _d(data['laying_rate']),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

// ── Time range options ───────────────────────────────────────────────────────
enum _Range { h24, d7, d30 }

extension _RangeExt on _Range {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _Range.h24: return l10n.last24h;
      case _Range.d7:  return l10n.last7d;
      case _Range.d30: return l10n.last30d;
    }
  }

  Duration get duration {
    switch (this) {
      case _Range.h24: return const Duration(hours: 24);
      case _Range.d7:  return const Duration(days: 7);
      case _Range.d30: return const Duration(days: 30);
    }
  }

  int get firestoreLimit {
    // sensor_history = one doc per 10 min
    // 24h = 144 docs, 7d = 1008, 30d = 4320
    switch (this) {
      case _Range.h24: return 144;
      case _Range.d7:  return 1008;
      case _Range.d30: return 4320;
    }
  }
}

// ── Main screen ──────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // sensor_history data
  List<_SensorRecord> _records = [];
  bool _loadingRecords = true;
  String? _recordsError;

  // daily_reports data (kept for eggs/feed/alerts tabs)
  List<DailyReport> _reports = [];
  bool _loadingReports = true;

  _Range _range = _Range.h24;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadRecords(), _loadReports()]);
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loadingRecords = true;
      _recordsError = null;
    });
    try {
      final since = DateTime.now().subtract(_range.duration);
      final snap = await FirebaseFirestore.instance
          .collection(FirebasePaths.sensorHistory)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('timestamp', descending: false)
          .limit(_range.firestoreLimit)
          .get();
      setState(() {
        _records = snap.docs
            .map((d) => _SensorRecord.fromFirestore(
                d.data()))
            .toList();
        _loadingRecords = false;
      });
    } catch (e) {
      setState(() {
        _recordsError = e.toString();
        _loadingRecords = false;
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final limit = _range == _Range.h24 ? 1 : (_range == _Range.d7 ? 7 : 30);
      final snap = await FirebaseFirestore.instance
          .collection(FirebasePaths.dailyReports)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      setState(() {
        _reports = snap.docs
            .map((d) => DailyReport.fromFirestore(d))
            .toList()
            .reversed
            .toList();
        _loadingReports = false;
      });
    } catch (e) {
      setState(() => _loadingReports = false);
    }
  }

  void _onRangeChanged(_Range r) {
    setState(() => _range = r);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);
    final thresholds = context.watch<ThresholdProvider>().thresholds;

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
                  Text(l10n.history,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      )),
                  Text(
                    _records.isEmpty
                        ? 'No data'
                        : '${_records.length} readings · ${_range.label(l10n)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                // Range selector chips
                _RangeSelector(
                  selected: _range,
                  isDark: isDark,
                  onSelect: _onRangeChanged,
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: textColor),
                  onPressed: _loadAll,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.temperatureChart),
                  const Tab(text: 'Humidity'),
                  Tab(text: l10n.nh3Co2Chart),
                  Tab(text: l10n.eggsChart),
                  Tab(text: l10n.feedChart),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTempTab(isDark, thresholds, l10n),
              _buildHumidityTab(isDark, thresholds, l10n),
              _buildGasTab(isDark, thresholds, l10n),
              _buildEggsTab(isDark, l10n),
              _buildFeedTab(isDark, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ── Temperature tab ────────────────────────────────────────────────────────
  Widget _buildTempTab(bool isDark, ThresholdModel t, AppLocalizations l10n) {
    return _RefreshableTab(
      onRefresh: _loadAll,
      children: [
        _buildSensorChartCard(
          title: l10n.temperatureChart,
          subtitle: 'Avg, min and max °C over time',
          isDark: isDark,
          child: _loadingRecords
              ? _loadingWidget()
              : _recordsError != null
                  ? _errorWidget(context, _recordsError!)
                  : _records.isEmpty
                      ? _emptyWidget(context)
                      : _MultiLineChart(
                          records: _records,
                          lines: [
                            _ChartLine(
                              label: 'Avg',
                              color: AppColors.statusWarning,
                              getValue: (r) => r.tempAvg,
                            ),
                            _ChartLine(
                              label: 'Min',
                              color: AppColors.severityInfo,
                              getValue: (r) => r.tempMin,
                            ),
                            _ChartLine(
                              label: 'Max',
                              color: AppColors.statusCritical,
                              getValue: (r) => r.tempMax,
                            ),
                          ],
                          thresholdLines: [
                            _ThresholdLine(
                                value: t.tempFanLow,
                                color: AppColors.statusWarning,
                                label: 'Fan on'),
                            _ThresholdLine(
                                value: t.tempHeatOn,
                                color: AppColors.severityInfo,
                                label: 'Heat on'),
                          ],
                          unit: '°C',
                          isDark: isDark,
                          range: _range,
                        ),
        ),
        const SizedBox(height: 16),
        _buildLegendCard(isDark, [
          const _LegendItem('Avg', AppColors.statusWarning),
          const _LegendItem('Min', AppColors.severityInfo),
          const _LegendItem('Max', AppColors.statusCritical),
          const _LegendItem('Fan on', AppColors.statusWarning,
              dashed: true),
          const _LegendItem('Heat on', AppColors.severityInfo,
              dashed: true),
        ]),
      ],
    );
  }

  // ── Humidity tab ───────────────────────────────────────────────────────────
  Widget _buildHumidityTab(bool isDark, ThresholdModel t, AppLocalizations l10n) {
    return _RefreshableTab(
      onRefresh: _loadAll,
      children: [
        _buildSensorChartCard(
          title: 'Humidity',
          subtitle: 'Average %RH over time',
          isDark: isDark,
          child: _loadingRecords
              ? _loadingWidget()
              : _recordsError != null
                  ? _errorWidget(context, _recordsError!)
                  : _records.isEmpty
                      ? _emptyWidget(context)
                      : _SingleLineChart(
                          records: _records,
                          getValue: (r) => r.rhAvg,
                          color: AppColors.severityInfo,
                          unit: '%',
                          minY: 0,
                          maxY: 100,
                          thresholdLines: [
                            _ThresholdLine(
                                value: t.rhHigh,
                                color: AppColors.statusWarning,
                                label: 'RH warn'),
                          ],
                          isDark: isDark,
                          range: _range,
                        ),
        ),
        const SizedBox(height: 16),
        _buildLegendCard(isDark, [
          const _LegendItem('Humidity', AppColors.severityInfo),
          _LegendItem('${'RH warn'} (${t.rhHigh.toInt()}%)',
              AppColors.statusWarning,
              dashed: true),
        ]),
      ],
    );
  }

  // ── Gas tab ────────────────────────────────────────────────────────────────
  Widget _buildGasTab(bool isDark, ThresholdModel t, AppLocalizations l10n) {
    return _RefreshableTab(
      onRefresh: _loadAll,
      children: [
        _buildSensorChartCard(
          title: 'Ammonia (NH₃)',
          subtitle: 'Peak NH₃ reading (ppm)',
          isDark: isDark,
          child: _loadingRecords
              ? _loadingWidget()
              : _recordsError != null
                  ? _errorWidget(context, _recordsError!)
                  : _records.isEmpty
                      ? _emptyWidget(context)
                      : _SingleLineChart(
                          records: _records,
                          getValue: (r) => r.nh3Max,
                          color: AppColors.severityHigh,
                          unit: ' ppm',
                          thresholdLines: [
                            _ThresholdLine(
                                value: t.nh3Warn,
                                color: AppColors.statusWarning,
                                label: 'Warn'),
                            _ThresholdLine(
                                value: t.nh3High,
                                color: AppColors.severityHigh,
                                label: 'High'),
                            _ThresholdLine(
                                value: t.nh3Critical,
                                color: AppColors.statusCritical,
                                label: 'Critical'),
                          ],
                          isDark: isDark,
                          range: _range,
                        ),
        ),
        const SizedBox(height: 16),
        _buildSensorChartCard(
          title: 'Carbon Dioxide (CO₂)',
          subtitle: 'Average CO₂ reading (ppm)',
          isDark: isDark,
          child: _loadingRecords
              ? _loadingWidget()
              : _recordsError != null
                  ? _errorWidget(context, _recordsError!)
                  : _records.isEmpty
                      ? _emptyWidget(context)
                      : _SingleLineChart(
                          records: _records,
                          getValue: (r) => r.co2Avg,
                          color: AppColors.primary,
                          unit: ' ppm',
                          thresholdLines: [
                            _ThresholdLine(
                                value: t.co2High,
                                color: AppColors.statusCritical,
                                label: 'High'),
                          ],
                          isDark: isDark,
                          range: _range,
                        ),
        ),
        const SizedBox(height: 16),
        _buildLegendCard(isDark, [
          const _LegendItem('Ammonia (NH₃)', AppColors.severityHigh),
          _LegendItem('NH₃ ${'Warn'} (${t.nh3Warn.toInt()} ppm)',
              AppColors.statusWarning, dashed: true),
          _LegendItem('NH₃ ${'High'} (${t.nh3High.toInt()} ppm)',
              AppColors.severityHigh, dashed: true),
          _LegendItem('NH₃ ${'Critical'} (${t.nh3Critical.toInt()} ppm)',
              AppColors.statusCritical, dashed: true),
          const _LegendItem('Carbon Dioxide (CO₂)', AppColors.primary),
          _LegendItem('CO₂ ${'High'} (${t.co2High.toInt()} ppm)',
              AppColors.statusCritical, dashed: true),
        ]),
      ],
    );
  }

  // ── Eggs tab ───────────────────────────────────────────────────────────────
  Widget _buildEggsTab(bool isDark, AppLocalizations l10n) {
    return _RefreshableTab(
      onRefresh: _loadAll,
      children: [
        _buildSensorChartCard(
          title: 'Daily Eggs',
          subtitle: 'Total eggs collected per day',
          isDark: isDark,
          child: _loadingReports
              ? _loadingWidget()
              : _reports.isEmpty
                  ? _emptyWidget(context)
                  : _DailyBarChart(
                      reports: _reports,
                      getValue: (r) => r.totalEggs.toDouble(),
                      color: AppColors.accent,
                      isDark: isDark,
                    ),
        ),
        const SizedBox(height: 16),
        _buildSensorChartCard(
          title: 'Laying Rate',
          subtitle: 'Percentage of hens laying per day',
          isDark: isDark,
          child: _loadingReports
              ? _loadingWidget()
              : _reports.isEmpty
                  ? _emptyWidget(context)
                  : _DailyLineChart(
                      reports: _reports,
                      getValue: (r) => r.layingRatePct,
                      color: AppColors.statusGood,
                      unit: '%',
                      minY: 0,
                      maxY: 100,
                      isDark: isDark,
                    ),
        ),
        const SizedBox(height: 16),
        if (_reports.isNotEmpty) _SummaryTable(reports: _reports, isDark: isDark),
      ],
    );
  }

  // ── Feed tab ───────────────────────────────────────────────────────────────
  Widget _buildFeedTab(bool isDark, AppLocalizations l10n) {
    return _RefreshableTab(
      onRefresh: _loadAll,
      children: [
        _buildSensorChartCard(
          title: 'Feed Consumed',
          subtitle: 'Total feed per day (kg)',
          isDark: isDark,
          child: _loadingReports
              ? _loadingWidget()
              : _reports.isEmpty
                  ? _emptyWidget(context)
                  : _DailyBarChart(
                      reports: _reports,
                      getValue: (r) => r.feedConsumedKg,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
        ),
        const SizedBox(height: 16),
        _buildSensorChartCard(
          title: 'Feed Conversion Ratio (FCR)',
          subtitle: 'Feed kg per egg kg — lower is better',
          isDark: isDark,
          child: _loadingReports
              ? _loadingWidget()
              : _reports.isEmpty
                  ? _emptyWidget(context)
                  : _DailyLineChart(
                      reports: _reports,
                      getValue: (r) => r.fcr,
                      color: AppColors.severityInfo,
                      unit: '',
                      isDark: isDark,
                    ),
        ),
        const SizedBox(height: 16),
        if (_reports.isNotEmpty)
          _AlertStatsCard(reports: _reports, isDark: isDark),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildSensorChartCard({
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget child,
  }) {
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
          SizedBox(height: 190, child: child),
        ],
      ),
    );
  }

  Widget _buildLegendCard(bool isDark, List<_LegendItem> items) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.dashed)
                SizedBox(
                  width: 18,
                  child: CustomPaint(
                    painter: _DashPainter(item.color),
                    size: const Size(18, 2),
                  ),
                )
              else
                Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(2),
                    )),
              const SizedBox(width: 6),
              Text(item.label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _loadingWidget() => const Center(
      child: CircularProgressIndicator(
          color: AppColors.primary, strokeWidth: 2));

  Widget _emptyWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 36, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text('No data for this period',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _errorWidget(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 32, color: AppColors.statusCritical),
          const SizedBox(height: 8),
          Text(l10n.failedToLoad,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusCritical)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _loadRecords,
            child: Text(l10n.retry,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
} // end _HistoryScreenState

// ── Range Selector ───────────────────────────────────────────────────────────
class _RangeSelector extends StatelessWidget {
  final _Range selected;
  final bool isDark;
  final void Function(_Range) onSelect;

  const _RangeSelector({
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _Range.values.map((r) {
          final isSelected = r == selected;
          return GestureDetector(
            onTap: () => onSelect(r),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                r.label(l10n),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Refreshable Tab ──────────────────────────────────────────────────────────
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

// ── Chart data models ────────────────────────────────────────────────────────
class _ChartLine {
  final String label;
  final Color color;
  final double Function(_SensorRecord) getValue;
  const _ChartLine(
      {required this.label,
      required this.color,
      required this.getValue});
}

class _ThresholdLine {
  final double value;
  final Color color;
  final String label;
  const _ThresholdLine(
      {required this.value, required this.color, required this.label});
}

class _LegendItem {
  final String label;
  final Color color;
  final bool dashed;
  const _LegendItem(this.label, this.color, {this.dashed = false});
}

// ── Multi-line chart (temp avg/min/max) ──────────────────────────────────────
class _MultiLineChart extends StatefulWidget {
  final List<_SensorRecord> records;
  final List<_ChartLine> lines;
  final List<_ThresholdLine> thresholdLines;
  final String unit;
  final bool isDark;
  final _Range range;

  const _MultiLineChart({
    required this.records,
    required this.lines,
    required this.thresholdLines,
    required this.unit,
    required this.isDark,
    required this.range,
  });

  @override
  State<_MultiLineChart> createState() => _MultiLineChartState();
}

class _MultiLineChartState extends State<_MultiLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    if (records.isEmpty) return const SizedBox.shrink();

    // Downsample if too many points
    final sampled = _downsample(records, 80);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: widget.isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: widget.thresholdLines.map((tl) {
            return HorizontalLine(
              y: tl.value,
              color: tl.color.withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  fontSize: 9,
                  color: tl.color,
                  fontWeight: FontWeight.w600,
                ),
                labelResolver: (_) => tl.label,
              ),
            );
          }).toList(),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}${widget.unit}',
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (sampled.length / 4).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sampled.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _formatTs(sampled[idx].timestamp, widget.range),
                  style: const TextStyle(
                      fontSize: 8, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: widget.lines.asMap().entries.map((entry) {
          final line = entry.value;
          final spots = sampled.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), line.getValue(e.value));
          }).toList();
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: line.color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          );
        }).toList(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final idx = s.x.toInt();
                final lineIdx = s.barIndex;
                final label = widget.lines[lineIdx].label;
                final ts = idx < sampled.length
                    ? _formatTsFull(sampled[idx].timestamp)
                    : '';
                return LineTooltipItem(
                  '$label: ${s.y.toStringAsFixed(1)}${widget.unit}\n$ts',
                  TextStyle(
                    color: widget.lines[lineIdx].color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ── Single-line chart (humidity, NH3, CO2) ───────────────────────────────────
class _SingleLineChart extends StatelessWidget {
  final List<_SensorRecord> records;
  final double Function(_SensorRecord) getValue;
  final Color color;
  final String unit;
  final double? minY;
  final double? maxY;
  final List<_ThresholdLine> thresholdLines;
  final bool isDark;
  final _Range range;

  const _SingleLineChart({
    required this.records,
    required this.getValue,
    required this.color,
    required this.unit,
    this.minY,
    this.maxY,
    required this.thresholdLines,
    required this.isDark,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final sampled = _downsample(records, 80);
    final spots = sampled.asMap().entries.map((e) {
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
        extraLinesData: ExtraLinesData(
          horizontalLines: thresholdLines.map((tl) {
            return HorizontalLine(
              y: tl.value,
              color: tl.color.withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  fontSize: 9,
                  color: tl.color,
                  fontWeight: FontWeight.w600,
                ),
                labelResolver: (_) => tl.label,
              ),
            );
          }).toList(),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}$unit',
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (sampled.length / 4).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sampled.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _formatTs(sampled[idx].timestamp, range),
                  style: const TextStyle(
                      fontSize: 8, color: AppColors.textSecondary),
                );
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
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
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
              final ts = idx < sampled.length
                  ? _formatTsFull(sampled[idx].timestamp)
                  : '';
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)}$unit\n$ts',
                TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Daily bar chart (eggs, feed) — from daily_reports ───────────────────────
class _DailyBarChart extends StatelessWidget {
  final List<DailyReport> reports;
  final double Function(DailyReport) getValue;
  final Color color;
  final bool isDark;

  const _DailyBarChart({
    required this.reports,
    required this.getValue,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const SizedBox.shrink();
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
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= reports.length) {
                  return const SizedBox.shrink();
                }
                if (reports.length > 10 &&
                    idx % ((reports.length ~/ 5) + 1) != 0) {
                  return const SizedBox.shrink();
                }
                final parts = reports[idx].date.split('-');
                final label = parts.length >= 3
                    ? '${parts[1]}/${parts[2]}'
                    : reports[idx].date;
                return Text(label,
                    style: const TextStyle(
                        fontSize: 8, color: AppColors.textSecondary));
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: reports.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: getValue(e.value),
                color: color,
                width: reports.length > 20 ? 5 : 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final r = reports[group.x];
              return BarTooltipItem(
                '${r.date}\n${rod.toY.toStringAsFixed(1)}',
                TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Daily line chart (laying rate, FCR) ──────────────────────────────────────
class _DailyLineChart extends StatelessWidget {
  final List<DailyReport> reports;
  final double Function(DailyReport) getValue;
  final Color color;
  final String unit;
  final double? minY;
  final double? maxY;
  final bool isDark;

  const _DailyLineChart({
    required this.reports,
    required this.getValue,
    required this.color,
    required this.unit,
    this.minY,
    this.maxY,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const SizedBox.shrink();
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
              reservedSize: 38,
              getTitlesWidget: (value, _) => Text(
                '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= reports.length) {
                  return const SizedBox.shrink();
                }
                if (reports.length > 10 &&
                    idx % ((reports.length ~/ 5) + 1) != 0) {
                  return const SizedBox.shrink();
                }
                final parts = reports[idx].date.split('-');
                final label = parts.length >= 3
                    ? '${parts[1]}/${parts[2]}'
                    : reports[idx].date;
                return Text(label,
                    style: const TextStyle(
                        fontSize: 8, color: AppColors.textSecondary));
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
            dotData: FlDotData(show: reports.length <= 10),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Summary Table ────────────────────────────────────────────────────────────
class _SummaryTable extends StatelessWidget {
  final List<DailyReport> reports;
  final bool isDark;

  const _SummaryTable(
      {required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          Text('Recent Days Summary',
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
                                fontSize: 12, color: textColor))),
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

// ── Alert Stats Card ─────────────────────────────────────────────────────────
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
    final maxA =
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
                      value: '$maxA',
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

// ── Dash painter for legend ───────────────────────────────────────────────────
class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + 4, size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
List<_SensorRecord> _downsample(
    List<_SensorRecord> records, int maxPoints) {
  if (records.length <= maxPoints) return records;
  final step = records.length / maxPoints;
  return List.generate(
      maxPoints, (i) => records[(i * step).floor()]);
}

String _formatTs(DateTime ts, _Range range) {
  if (range == _Range.h24) {
    return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }
  return '${ts.month}/${ts.day}';
}

String _formatTsFull(DateTime ts) {
  return '${ts.year}-${ts.month.toString().padLeft(2, '0')}-'
      '${ts.day.toString().padLeft(2, '0')} '
      '${ts.hour.toString().padLeft(2, '0')}:'
      '${ts.minute.toString().padLeft(2, '0')}';
}