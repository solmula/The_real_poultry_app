import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/live_data_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'feed_water/feed_water_screen.dart';
import 'override/override_screen.dart';
import 'system_status/system_status_screen.dart';
import 'settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer2<AuthProvider, LiveDataProvider>(
          builder: (context, auth, live, _) {
            final nodeAOnline = live.data?.nodeAOnline ?? true;
            final nodeBOnline = live.data?.nodeBOnline ?? true;
            final anyNodeOffline = !nodeAOnline || !nodeBOnline;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: cardColor,
                  surfaceTintColor: Colors.transparent,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.more,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      Text(auth.user?.email ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _RoleBadge(auth: auth, isDark: isDark),
                      const SizedBox(height: 20),

                      if (anyNodeOffline) ...[
                        _OfflineBanner(
                            nodeAOnline: nodeAOnline,
                            nodeBOnline: nodeBOnline,
                            l10n: l10n),
                        const SizedBox(height: 16),
                      ],

                      _SectionHeader(
                          label: l10n.operations, isDark: isDark),
                      const SizedBox(height: 10),

                      _MenuTile(
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.white,
                        iconBg: const Color(0xFF1565C0),
                        title: l10n.feedWater,
                        subtitle: l10n.feedWater,
                        isDark: isDark,
                        badge: _feedWaterBadge(live, l10n),
                        onTap: () => _push(context, const FeedWaterScreen()),
                      ),
                      const SizedBox(height: 10),

                      _MenuTile(
                        icon: Icons.tune_rounded,
                        iconColor: Colors.white,
                        iconBg: AppColors.primary,
                        title: l10n.manualOverride,
                        subtitle: l10n.manualOverride,
                        isDark: isDark,
                        locked: auth.isViewer,
                        onTap: auth.isViewer
                            ? null
                            : () => _push(context, const OverrideScreen()),
                      ),
                      const SizedBox(height: 20),

                      _SectionHeader(label: l10n.system, isDark: isDark),
                      const SizedBox(height: 10),

                      _MenuTile(
                        icon: Icons.developer_board_rounded,
                        iconColor: Colors.white,
                        iconBg: anyNodeOffline
                            ? AppColors.statusCritical
                            : AppColors.statusGood,
                        title: l10n.systemStatus,
                        subtitle: l10n.systemStatus,
                        isDark: isDark,
                        badge: anyNodeOffline ? l10n.offline : null,
                        badgeColor: AppColors.statusCritical,
                        onTap: () =>
                            _push(context, const SystemStatusScreen()),
                      ),
                      const SizedBox(height: 10),

                      _MenuTile(
                        icon: Icons.settings_rounded,
                        iconColor: Colors.white,
                        iconBg: const Color(0xFF546E7A),
                        title: l10n.settings,
                        subtitle: auth.isAdmin
                            ? l10n.thresholds
                            : l10n.profile,
                        isDark: isDark,
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                      const SizedBox(height: 28),

                      _AppInfoCard(isDark: isDark),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _feedWaterBadge(LiveDataProvider live, AppLocalizations l10n) {
    final d = live.data;
    if (d == null) return null;
    final h1Water = d.h1WaterPct ?? 100.0;
    final h2Water = d.h2WaterPct ?? 100.0;
    final h1Feed = d.h1FeedPct ?? 100.0;
    final h2Feed = d.h2FeedPct ?? 100.0;
    if (h1Water < 20 || h2Water < 20 || h1Feed < 10 || h2Feed < 10) {
      return 'CRITICAL';
    }
    if (h1Water < 50 || h2Water < 50 || h1Feed < 30 || h2Feed < 30) {
      return 'LOW';
    }
    return null;
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Role Badge ────────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final AuthProvider auth;
  final bool isDark;
  const _RoleBadge({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    Color roleColor;
    String roleLabel;
    IconData roleIcon;

    if (auth.isAdmin) {
      roleColor = AppColors.primary;
      roleLabel = 'Admin';
      roleIcon = Icons.admin_panel_settings_rounded;
    } else if (auth.isViewer) {
      roleColor = AppColors.statusOffline;
      roleLabel = 'Viewer';
      roleIcon = Icons.visibility_rounded;
    } else {
      roleColor = AppColors.severityInfo;
      roleLabel = 'Operator';
      roleIcon = Icons.person_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(roleIcon, color: roleColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.user?.email ?? 'Unknown',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(roleLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleColor)),
                ),
              ],
            ),
          ),
          if (auth.isViewer)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusOffline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(l10n.viewOnly,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.statusOffline,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ── Offline Banner ────────────────────────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  final bool nodeAOnline;
  final bool nodeBOnline;
  final AppLocalizations l10n;
  const _OfflineBanner(
      {required this.nodeAOnline,
      required this.nodeBOnline,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final offlineNodes = [
      if (!nodeAOnline) 'Main Controller',
      if (!nodeBOnline) 'Equipment Controller',
    ].join(' and ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusCritical.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.statusCritical.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded,
              color: AppColors.statusCritical, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$offlineNodes ${l10n.offline.toLowerCase()} — ${l10n.systemStatus.toLowerCase()}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusCritical),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2));
  }
}

// ── Menu Tile ─────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;
  final bool locked;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.badge,
    this.badgeColor,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final isDisabled = onTap == null;

    Color effectiveBadgeColor = badgeColor ?? AppColors.statusWarning;
    if (badge == 'CRITICAL') effectiveBadgeColor = AppColors.statusCritical;
    if (badge == 'LOW') effectiveBadgeColor = AppColors.statusWarning;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor)),
                          if (locked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock_rounded,
                                size: 13,
                                color: AppColors.textSecondary),
                          ],
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: effectiveBadgeColor.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(badge!,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: effectiveBadgeColor,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDisabled
                      ? AppColors.textSecondary.withOpacity(0.3)
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── App Info Card ─────────────────────────────────────────────────────────────
class _AppInfoCard extends StatelessWidget {
  final bool isDark;
  const _AppInfoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.egg_alt_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(l10n.appName,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('v1.0.0 — Final Year Thesis',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}