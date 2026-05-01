import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final layingRate =
        isH1 ? data?.layingRate : data?.h2LayingRate;

    // Tier data — 4 tiers, left + right belt
    final tiers = List.generate(4, (i) {
      final tierNum = i + 1;
      final left = isH1
          ? data?.h1TierLeft(tierNum)
          : data?.h2TierLeft(tierNum);
      final right = isH1
          ? data?.h1TierRight(tierNum)
          : data?.h2TierRight(tierNum);
      return _TierData(
        tier: tierNum,
        left: left,
        right: right,
      );
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary card
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
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final rateColor = (layingRate ?? 0) >= 80
        ? AppColors.statusGood
        : AppColors.statusWarning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Egg icon
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
          // Total eggs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Eggs — $houseLabel',
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
          // Laying rate
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          // Tier label
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
          // Left belt
          Expanded(
            child: _BeltStat(
              label: 'Left Belt',
              value: tier.left,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          // Right belt
          Expanded(
            child: _BeltStat(
              label: 'Right Belt',
              value: tier.right,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          // Total
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

  const _BeltStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

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

  const _TierData({
    required this.tier,
    required this.left,
    required this.right,
  });
}