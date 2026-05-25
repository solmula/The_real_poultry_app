import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/live_data_provider.dart';
import '../../../../data/models/sensor_data.dart';

class SystemStatusScreen extends StatelessWidget {
  const SystemStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text('System Status', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer<LiveDataProvider>(
        builder: (context, live, _) {
          final d = live.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              if (live.isStale) _StaleBanner(lastUpdate: live.lastUpdateText),
              if (live.isStale) const SizedBox(height: 12),

              _LiveSummaryCard(data: d, isDark: isDark),
              const SizedBox(height: 24),

              _SectionLabel(text: 'ESP32 Nodes', isDark: isDark),
              const SizedBox(height: 10),
              _NodeCard(
                label: 'Main Controller',
                subtitle: 'Climate sensing & control logic',
                online: d?.nodeAOnline ?? false,
                firmware: d?.firmwareVer,
                uptimeHours: d?.uptimeHours,
                heapFreeKb: d?.heapFreeKb,
                lastSeen: d?.timestamp,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _NodeCard(
                label: 'Equipment Controller',
                subtitle: 'Controls egg belts, feed belts & water pumps',
                online: d?.nodeBOnline ?? false,
                firmware: d?.nodeBFirmware,
                uptimeHours: d?.nodeBUptimeHours,
                heapFreeKb: null,
                lastSeen: d?.nodeBLastHeartbeat,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: 'Active Commands', isDark: isDark),
              const SizedBox(height: 10),
              _ActiveCommandCard(data: d, isDark: isDark),
              const SizedBox(height: 24),

              _SectionLabel(text: 'System Info', isDark: isDark),
              const SizedBox(height: 10),
              _SystemInfoCard(data: d, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  final String lastUpdate;
  const _StaleBanner({required this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusWarning.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.access_time_rounded, color: AppColors.statusWarning, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Data may be outdated — last update $lastUpdate',
            style: const TextStyle(fontSize: 12, color: AppColors.statusWarning, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
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

class _NodeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool online;
  final String? firmware;
  final double? uptimeHours;
  final double? heapFreeKb;
  final int? lastSeen;
  final bool isDark;

  const _NodeCard({
    required this.label,
    required this.subtitle,
    required this.online,
    required this.firmware,
    required this.uptimeHours,
    required this.heapFreeKb,
    required this.lastSeen,
    required this.isDark,
  });

  String _lastSeenText() {
    if (lastSeen == null) return 'Never';
    final t = DateTime.fromMillisecondsSinceEpoch(lastSeen! * 1000);
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String _uptimeText() {
    if (uptimeHours == null) return '--';
    final h = uptimeHours!.toInt();
    final d = h ~/ 24;
    final rem = h % 24;
    if (d > 0) return '${d}d ${rem}h';
    return '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final statusColor = online ? AppColors.statusGood : AppColors.statusCritical;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)],
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(
                online ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
              ),
            ),
            const Spacer(),
            if (firmware != null)
              Text('v$firmware', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(children: [
            _InfoChip(label: 'Last seen', value: _lastSeenText()),
            const SizedBox(width: 16),
            _InfoChip(label: 'Uptime', value: _uptimeText()),
            if (heapFreeKb != null) ...[
              const SizedBox(width: 16),
              _InfoChip(label: 'Free heap', value: '${heapFreeKb!.toStringAsFixed(0)} KB'),
            ],
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ],
    );
  }
}

class _LiveSummaryCard extends StatelessWidget {
  final SensorData? data;
  final bool isDark;
  const _LiveSummaryCard({required this.data, required this.isDark});

  Color _lightsColor() {
    final lights = data?.lights;
    if (lights == 'ON') return AppColors.statusGood;
    if (lights == 'DIM') return AppColors.statusWarning;
    return AppColors.textSecondary;
  }

  String _lightsLabel() {
    return data?.lights ?? '--';
  }

  Color _heaterColor() {
    return (data?.heater == true) ? AppColors.statusCritical : AppColors.textSecondary;
  }

  String _heaterLabel() {
    return (data?.heater == true) ? 'ON' : 'OFF';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    
    final tiles = [
      {
        'label': 'NH3',
        'value': data?.nh3Max != null ? '${data!.nh3Max!.toStringAsFixed(1)} ppm' : '--',
        'icon': Icons.air_outlined,
      },
      {
        'label': 'Temperature',
        'value': data?.tempAvg != null ? '${data!.tempAvg!.toStringAsFixed(1)} °C' : '--',
        'icon': Icons.thermostat_rounded,
      },
      {
        'label': 'Humidity',
        'value': data?.rhAvg != null ? '${data!.rhAvg!.toStringAsFixed(1)} %RH' : '--',
        'icon': Icons.water_drop_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final tile in tiles)
                _StatusTile(
                  label: tile['label'] as String,
                  value: tile['value'] as String,
                  icon: tile['icon'] as IconData,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              _StatusTile(
                label: 'Lights',
                value: _lightsLabel(),
                icon: Icons.wb_incandescent_rounded,
                color: _lightsColor(),
                isDark: isDark,
              ),
              _StatusTile(
                label: 'Heater',
                value: _heaterLabel(),
                icon: Icons.whatshot_rounded,
                color: _heaterColor(),
                isDark: isDark,
              ),
              _StatusTile(
                label: 'Eggs Today',
                value: '${data?.totalToday ?? 0}',
                icon: Icons.egg_rounded,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatusTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ActiveCommandCard extends StatelessWidget {
  final SensorData? data;
  final bool isDark;
  const _ActiveCommandCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    final lights = data?.lights ?? '--';
    final fanSpeed = data?.fanSpeed ?? '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lights', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(lights, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fan Speed', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(fanSpeed, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemInfoCard extends StatelessWidget {
  final SensorData? data;
  final bool isDark;
  const _SystemInfoCard({required this.data, required this.isDark});

  String _uptimeText(double? hours) {
    if (hours == null) return '--';
    final h = hours.toInt();
    final d = h ~/ 24;
    final rem = h % 24;
    if (d > 0) return '${d}d ${rem}h';
    return '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    final rows = [
      ['Main Controller Firmware', data?.firmwareVer != null ? 'v${data!.firmwareVer}' : '--'],
      ['Equipment Controller Firmware', data?.nodeBFirmware != null ? 'v${data!.nodeBFirmware}' : '--'],
      ['Main Controller Online For', _uptimeText(data?.uptimeHours)],
      ['Equipment Controller Online For', _uptimeText(data?.nodeBUptimeHours)],
      ['Main Controller Memory', data?.heapFreeKb != null ? '${data!.heapFreeKb!.toStringAsFixed(1)} KB' : '--'],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.value[0], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(e.value[1], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
              if (!isLast) const Divider(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}