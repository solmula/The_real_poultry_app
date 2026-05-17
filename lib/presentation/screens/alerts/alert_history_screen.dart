import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/firebase_paths.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  List<_HistoryAlert> _alerts = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL'; // ALL, CRITICAL, HIGH, WARNING, INFO

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Query query = FirebaseFirestore.instance
          .collection(FirebasePaths.alertsHistory)
          .orderBy('timestamp', descending: true)
          .limit(100);

      final snap = await query.get();
      final alerts = snap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return _HistoryAlert(
          id: doc.id,
          type: d['type']?.toString() ?? 'UNKNOWN',
          severity: d['severity']?.toString() ?? 'INFO',
          value: _toDouble(d['value']),
          threshold: _toDouble(d['threshold']),
          timestamp: d['timestamp'] is Timestamp
              ? (d['timestamp'] as Timestamp).millisecondsSinceEpoch ~/ 1000
              : (d['timestamp'] as int? ?? 0),
          ackedBy: d['acked_by']?.toString(),
        );
      }).toList();

      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return null;
  }

  List<_HistoryAlert> get _filtered {
    if (_filter == 'ALL') return _alerts;
    return _alerts.where((a) => a.severity == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text('Alert History',
            style:
                TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────
          Container(
            color: cardColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                    label: 'All',
                    value: 'ALL',
                    selected: _filter == 'ALL',
                    color: AppColors.primary,
                    onTap: () => setState(() => _filter = 'ALL')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Critical',
                    value: 'CRITICAL',
                    selected: _filter == 'CRITICAL',
                    color: AppColors.severityCritical,
                    onTap: () => setState(() => _filter = 'CRITICAL')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'High',
                    value: 'HIGH',
                    selected: _filter == 'HIGH',
                    color: AppColors.severityHigh,
                    onTap: () => setState(() => _filter = 'HIGH')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Warning',
                    value: 'WARNING',
                    selected: _filter == 'WARNING',
                    color: AppColors.severityWarning,
                    onTap: () => setState(() => _filter = 'WARNING')),
              ],
            ),
          ),
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _error != null
                    ? _buildError(isDark)
                    : _filtered.isEmpty
                        ? _buildEmpty(isDark)
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 40),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) =>
                                  _AlertHistoryCard(
                                alert: _filtered[i],
                                isDark: isDark,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 56,
              color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            _filter == 'ALL'
                ? 'No alert history yet'
                : 'No $_filter alerts in history',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acknowledged alerts will appear here.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert History Card ────────────────────────────────────────────────────
class _AlertHistoryCard extends StatelessWidget {
  final _HistoryAlert alert;
  final bool isDark;

  const _AlertHistoryCard({required this.alert, required this.isDark});

  String _timeText(int ts) {
    if (ts == 0) return '--';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _displayText(String type) {
    switch (type) {
      case 'TEMP_HIGH': return 'Temperature above safe limit';
      case 'TEMP_CRITICAL': return 'Critical temperature — heat stress risk';
      case 'TEMP_LOW': return 'Temperature below recommended minimum';
      case 'HUMIDITY_HIGH': return 'High humidity detected';
      case 'HUMIDITY_CRITICAL': return 'Critical humidity level';
      case 'NH3_ELEVATED': return 'Ammonia elevated';
      case 'NH3_HIGH': return 'Ammonia above legal limit';
      case 'NH3_CRITICAL': return 'Critical ammonia level';
      case 'CO2_HIGH': return 'CO2 elevated';
      case 'WATER_CRITICAL': return 'Water critically low';
      case 'PUMP_FAULT': return 'Water pump fault';
      case 'HOPPER_LOW': return 'Feed hopper low';
      case 'HOPPER_CRITICAL': return 'Feed hopper critically low';
      case 'NO_EGGS_2H': return 'No eggs detected for 2 hours';
      case 'SLAVE2_OFFLINE': return 'Equipment Controller went offline';
      default: return type.replaceAll('_', ' ');
    }
  }

  String _parameterLabel(String type) {
    if (type.startsWith('TEMP')) return 'Temperature';
    if (type.startsWith('HUMIDITY')) return 'Humidity';
    if (type.startsWith('NH3')) return 'NH₃';
    if (type.startsWith('CO2')) return 'CO2';
    if (type.startsWith('WATER') || type == 'PUMP_FAULT') return 'Water';
    if (type.startsWith('HOPPER') || type.contains('FEEDER') || type.contains('CHAIN')) return 'Feed';
    if (type == 'NO_EGGS_2H') return 'Egg Collection';
    if (type.contains('SLAVE') || type.contains('OFFLINE')) return 'Equipment Controller';
    return 'System';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final color = AppUtils.severityColor(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity dot
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        alert.severity,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _parameterLabel(alert.type),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeText(alert.timestamp),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _displayText(alert.type),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (alert.value != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniChip(
                          label: 'Value',
                          value:
                              alert.value!.toStringAsFixed(1),
                          color: color),
                      if (alert.threshold != null) ...[
                        const SizedBox(width: 6),
                        _MiniChip(
                            label: 'Threshold',
                            value: alert.threshold!
                                .toStringAsFixed(1),
                            color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ],
                if (alert.ackedBy != null) ...[
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 11, color: AppColors.statusGood),
                      SizedBox(width: 4),
                      Text(
                        'Acknowledged',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.statusGood,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Chip ─────────────────────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(fontSize: 10, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────
class _HistoryAlert {
  final String id;
  final String type;
  final String severity;
  final double? value;
  final double? threshold;
  final int timestamp;
  final String? ackedBy;

  const _HistoryAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.value,
    this.threshold,
    this.ackedBy,
  });
}