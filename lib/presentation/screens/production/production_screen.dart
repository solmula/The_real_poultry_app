import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/live_data_provider.dart';
import '../../../data/models/sensor_data.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _exporting = false;

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

  Future<void> _exportPdf(SensorData? d) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // ── Helpers ─────────────────────────────────────────────────────
      String val(dynamic v, String unit, {int dec = 1}) =>
          v == null ? '--' : '${(v as num).toStringAsFixed(dec)}$unit';

      String intVal(int? v) => v == null ? '--' : '$v';

      pw.Widget sectionTitle(String text) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFF00897B),
                  width: 1.5,
                ),
              ),
            ),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF00897B),
              ),
            ),
          );

      pw.Widget dataRow(String label, String value,
              {bool highlight = false}) =>
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              color: highlight
                  ? const PdfColor.fromInt(0xFFF5F5F5)
                  : PdfColors.white,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label,
                    style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColor.fromInt(0xFF9CA3AF))),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1A1F2E))),
              ],
            ),
          );

      pw.Widget tierRow(int tier, int? left, int? right) {
        final total = (left ?? 0) + (right ?? 0);
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Container(
                width: 32,
                height: 24,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE0F2F1),
                  borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6)),
                ),
                child: pw.Center(
                  child: pw.Text('T$tier',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF00897B))),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Left: ${intVal(left)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Right: ${intVal(right)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Total: $total',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // ── H1 totals ──────────────────────────────────────────────────
      final h1Total = d?.h1TotalToday ?? d?.totalToday;
      final h2Total = d?.h2TotalToday;
      final grandTotal = d?.totalToday;
      final h1Rate = d?.layingRate;
      final h2Rate = d?.h2LayingRate;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // ── Header ───────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF00897B),
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Daily Production Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Poultry House Automation System',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.white),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: $timeStr',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Overall Summary ───────────────────────────────────────
            sectionTitle('Overall Summary'),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFF8E1),
                      borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          intVal(grandTotal),
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFFFB300),
                          ),
                        ),
                        pw.Text('Total Eggs Today',
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8F5E9),
                      borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          val(h1Rate, '%'),
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF2E7D32),
                          ),
                        ),
                        pw.Text('Laying Rate',
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE3F2FD),
                      borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          '1040',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1565C0),
                          ),
                        ),
                        pw.Text('Total Hens',
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── House 1 ───────────────────────────────────────────────
            sectionTitle('House 1 (H1)'),
            dataRow('Total Eggs', intVal(h1Total), highlight: true),
            dataRow('Laying Rate', val(h1Rate, '%')),
            dataRow('Feed Weight', val(d?.h1FeedKg, ' kg')),
            dataRow('Water Level', val(d?.h1WaterPct, '%', dec: 0)),
            dataRow('Pump State', d?.h1PumpState ?? '--'),
            pw.SizedBox(height: 8),
            pw.Text('Tier Breakdown',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1A1F2E))),
            pw.SizedBox(height: 4),
            tierRow(1, d?.h1LeftT1, d?.h1RightT1),
            tierRow(2, d?.h1LeftT2, d?.h1RightT2),
            tierRow(3, d?.h1LeftT3, d?.h1RightT3),
            tierRow(4, d?.h1LeftT4, d?.h1RightT4),

            // ── House 2 ───────────────────────────────────────────────
            sectionTitle('House 2 (H2)'),
            dataRow('Total Eggs', intVal(h2Total), highlight: true),
            dataRow('Laying Rate', val(h2Rate, '%')),
            dataRow('Feed Weight', val(d?.h2FeedKg, ' kg')),
            dataRow('Water Level', val(d?.h2WaterPct, '%', dec: 0)),
            dataRow('Pump State', d?.h2PumpState ?? '--'),
            pw.SizedBox(height: 8),
            pw.Text('Tier Breakdown',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1A1F2E))),
            pw.SizedBox(height: 4),
            tierRow(1, d?.h2LeftT1, d?.h2RightT1),
            tierRow(2, d?.h2LeftT2, d?.h2RightT2),
            tierRow(3, d?.h2LeftT3, d?.h2RightT3),
            tierRow(4, d?.h2LeftT4, d?.h2RightT4),

            // ── Climate ───────────────────────────────────────────────
            sectionTitle('Climate at Time of Report'),
            dataRow('Avg Temperature',
                val(d?.tempAvg, ' °C'), highlight: true),
            dataRow('Min Temperature', val(d?.tempMin, ' °C')),
            dataRow('Max Temperature', val(d?.tempMax, ' °C')),
            dataRow('Humidity', val(d?.rhAvg, ' %RH')),
            dataRow('Max NH₃', val(d?.nh3Max, ' ppm'),
                highlight: true),
            dataRow('Avg CO₂', val(d?.co2Avg, ' ppm', dec: 0)),
            dataRow('Light', val(d?.lightAvg, ' lux', dec: 0)),
            dataRow('Fan Speed', d?.fanSpeed ?? '--'),
            dataRow(
                'Heater', d?.heater == true ? 'ON' : 'OFF'),

            // ── Footer ────────────────────────────────────────────────
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F5F5),
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Poultry House Automation — Final Year Thesis',
                    style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF9CA3AF)),
                  ),
                  pw.Text(
                    'Generated $dateStr at $timeStr',
                    style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // ── Save and share ─────────────────────────────────────────────
      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/production_report_$dateStr.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Production Report — $dateStr',
        text: 'Daily production report from Poultry Automation System',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Scaffold(
      body: SafeArea(
        child: Consumer<LiveDataProvider>(
          builder: (context, live, _) {
            final d = live.data;
            return NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: cardColor,
                  surfaceTintColor: Colors.transparent,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Production',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          )),
                      Text(
                        live.isLoading
                            ? 'Loading...'
                            : 'Updated ${live.lastUpdateText}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // ── Share / Export PDF button ─────────────────────
                    _exporting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.share_rounded,
                                color: textColor),
                            tooltip: 'Export PDF Report',
                            onPressed: () => _exportPdf(d),
                          ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: 'House 1 (H1)'),
                      Tab(text: 'House 2 (H2)'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _HouseProductionView(
                    houseLabel: 'H1',
                    data: d,
                    isDark: isDark,
                  ),
                  _HouseProductionView(
                    houseLabel: 'H2',
                    data: d,
                    isDark: isDark,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Per-house production view ─────────────────────────────────────────────
class _HouseProductionView extends StatelessWidget {
  final String houseLabel;
  final SensorData? data;
  final bool isDark;

  const _HouseProductionView({
    required this.houseLabel,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isH1 = houseLabel == 'H1';
    final totalToday = isH1
        ? (data?.h1TotalToday ?? data?.totalToday)
        : data?.h2TotalToday;
    final layingRate = isH1 ? data?.layingRate : data?.h2LayingRate;

    final tiers = List.generate(4, (i) {
      final tierNum = i + 1;
      final left =
          isH1 ? data?.h1TierLeft(tierNum) : data?.h2TierLeft(tierNum);
      final right =
          isH1 ? data?.h1TierRight(tierNum) : data?.h2TierRight(tierNum);
      return _TierData(tier: tierNum, left: left, right: right);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _SummaryCard(
          houseLabel: houseLabel,
          totalToday: totalToday,
          layingRate: layingRate,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        Text(
          'Tier Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...tiers.map((t) => _TierCard(tier: t, isDark: isDark)),
      ],
    );
  }
}

// ─── Summary Card ──────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String houseLabel;
  final int? totalToday;
  final double? layingRate;
  final bool isDark;

  const _SummaryCard({
    required this.houseLabel,
    required this.totalToday,
    required this.layingRate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final rateColor = (layingRate ?? 0) >= 80
        ? AppColors.statusGood
        : AppColors.statusWarning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.egg_rounded,
                color: AppColors.accent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Eggs — $houseLabel",
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  totalToday != null ? '$totalToday' : '--',
                  style: const TextStyle(
                    fontSize: 36,
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
              const Text('Laying Rate',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                layingRate != null
                    ? '${layingRate!.toStringAsFixed(1)}%'
                    : '--',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: rateColor,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rateColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (layingRate ?? 0) >= 80 ? 'Good' : 'Low',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: rateColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tier Card ─────────────────────────────────────────────────────────────
class _TierCard extends StatelessWidget {
  final _TierData tier;
  final bool isDark;

  const _TierCard({required this.tier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final total = (tier.left ?? 0) + (tier.right ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'T${tier.tier}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _BeltStat(
                label: 'Left Belt', value: tier.left, isDark: isDark),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          Expanded(
            child: _BeltStat(
                label: 'Right Belt', value: tier.right, isDark: isDark),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  total > 0 ? '$total' : '--',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Belt stat widget ──────────────────────────────────────────────────────
class _BeltStat extends StatelessWidget {
  final String label;
  final int? value;
  final bool isDark;

  const _BeltStat(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value != null ? '$value' : '--',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Data holder ───────────────────────────────────────────────────────────
class _TierData {
  final int tier;
  final int? left;
  final int? right;
  const _TierData(
      {required this.tier, required this.left, required this.right});
}