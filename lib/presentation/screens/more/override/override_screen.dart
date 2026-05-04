import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/live_data_provider.dart';
import '../../../../data/providers/command_provider.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

class OverrideScreen extends StatelessWidget {
  const OverrideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.manualOverride, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer3<LiveDataProvider, CommandProvider, AuthProvider>(
        builder: (context, live, cmd, auth, _) {
          final d = live.data;
          final isViewer = auth.isViewer;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              if (isViewer) _ViewOnlyBanner(l10n: l10n),
              if (isViewer) const SizedBox(height: 12),

              _CommandStatusCard(cmd: cmd, isDark: isDark, l10n: l10n),
              const SizedBox(height: 20),

              _SectionLabel(text: 'Climate Controls', isDark: isDark),
              const SizedBox(height: 10),

              _FanOverrideCard(
                currentState: d?.fanSpeed ?? '--',
                isDark: isDark,
                disabled: isViewer,
                l10n: l10n,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Set fan to \$val?', fanOverride: val),
              ),
              const SizedBox(height: 10),

              _ToggleOverrideCard(
                title: 'Heater Override',
                icon: Icons.whatshot_rounded,
                iconColor: AppColors.statusWarning,
                currentLabel: d?.heater == true ? 'ON' : 'OFF',
                options: const ['ON', 'OFF', 'Auto'],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Set heater to \$val?',
                    heaterOverride: val == 'Auto' ? '' : val),
              ),
              const SizedBox(height: 10),

              _ToggleOverrideCard(
                title: 'Lights Override',
                icon: Icons.wb_incandescent_rounded,
                iconColor: AppColors.accent,
                currentLabel: d?.lights ?? '--',
                options: const ['OFF', 'DIM', 'ON', 'Auto'],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Set lights to \$val?',
                    lightsOverride: val == 'Auto' ? '' : val),
              ),
              const SizedBox(height: 20),

              _SectionLabel(text: 'Mechanical Controls', isDark: isDark),
              const SizedBox(height: 10),

              _TriggerCard(
                title: 'Trigger Chain Feeder',
                icon: Icons.settings_input_component_rounded,
                iconColor: Colors.white,
                iconBg: AppColors.primary,
                options: const ['H1 Left', 'H1 Right', 'H2 Left', 'H2 Right', 'All'],
                firebaseValues: const ['h1_left', 'h1_right', 'h2_left', 'h2_right', 'all'],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Trigger feeder: \$val?', triggerFeeder: val),
              ),
              const SizedBox(height: 10),

              _TriggerCard(
                title: 'Trigger Manure Belt',
                icon: Icons.recycling_rounded,
                iconColor: Colors.white,
                iconBg: const Color(0xFF6D4C41),
                options: const ['H1-T1', 'H1-T2', 'H1-T3', 'H1-T4', 'H2-T1', 'H2-T2', 'H2-T3', 'H2-T4', 'All'],
                firebaseValues: const ['h1_t1', 'h1_t2', 'h1_t3', 'h1_t4', 'h2_t1', 'h2_t2', 'h2_t3', 'h2_t4', 'all'],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Run manure belt: \$val?', triggerManure: val),
              ),
              const SizedBox(height: 10),

              _TriggerCard(
                title: 'Trigger Water Pump',
                icon: Icons.water_drop_rounded,
                iconColor: Colors.white,
                iconBg: const Color(0xFF1565C0),
                options: const ['H1', 'H2', 'Both'],
                firebaseValues: const ['h1', 'h2', 'both'],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Trigger water pump: \$val?', triggerPump: val),
              ),
              const SizedBox(height: 24),

              if (!isViewer) _ClearAllButton(cmd: cmd, isDark: isDark, l10n: l10n),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendWithConfirm(
    BuildContext context,
    CommandProvider cmd,
    AppLocalizations l10n, {
    required String label,
    String? fanOverride,
    String? heaterOverride,
    String? lightsOverride,
    String? triggerFeeder,
    String? triggerManure,
    String? triggerPump,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.confirmCommand),
        content: Text(label),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.confirm)),
        ],
      ),
    );
    if (confirmed == true) {
      await cmd.sendCommand(
        fanOverride: fanOverride,
        heaterOverride: heaterOverride,
        lightsOverride: lightsOverride,
        triggerFeeder: triggerFeeder,
        triggerManure: triggerManure,
        triggerPump: triggerPump,
      );
    }
  }
}

class _ViewOnlyBanner extends StatelessWidget {
  final AppLocalizations l10n;
  const _ViewOnlyBanner({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusOffline.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusOffline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.statusOffline, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text('View only — you do not have permission to send commands',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.statusOffline,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _CommandStatusCard extends StatelessWidget {
  final CommandProvider cmd;
  final bool isDark;
  final AppLocalizations l10n;
  const _CommandStatusCard(
      {required this.cmd, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (cmd.status == CommandStatus.idle) return const SizedBox.shrink();
    Color color;
    IconData icon;
    String message;
    switch (cmd.status) {
      case CommandStatus.pending:
        color = AppColors.statusWarning;
        icon = Icons.hourglass_top_rounded;
        message = 'Command sent — waiting for ESP32...';
        break;
      case CommandStatus.executed:
        color = AppColors.statusGood;
        icon = Icons.check_circle_rounded;
        message = 'Command executed successfully';
        break;
      case CommandStatus.expired:
        color = AppColors.statusCritical;
        icon = Icons.error_rounded;
        message = cmd.errorMessage ?? l10n.commandExpired;
        break;
      default:
        color = AppColors.statusCritical;
        icon = Icons.wifi_off_rounded;
        message = cmd.errorMessage ?? l10n.cannotSendOffline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          cmd.status == CommandStatus.pending
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2));
  }
}

class _FanOverrideCard extends StatelessWidget {
  final String currentState;
  final bool isDark;
  final bool disabled;
  final void Function(String) onSelect;
  final AppLocalizations l10n;
  const _FanOverrideCard(
      {required this.currentState,
      required this.isDark,
      required this.disabled,
      required this.onSelect,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    const options = ['OFF', 'LOW', 'MED', 'HIGH', 'MAX'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wind_power_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(l10n.fanSpeed,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            Text('${'Now'}: $currentState',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 14),
          Row(
            children: options.map((opt) {
              final isActive = currentState == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: disabled ? null : () => onSelect(opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text(opt,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.primary))),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ToggleOverrideCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String currentLabel;
  final List<String> options;
  final bool isDark;
  final bool disabled;
  final void Function(String) onSelect;
  const _ToggleOverrideCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.currentLabel,
      required this.options,
      required this.isDark,
      required this.disabled,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            Text('${'Now'}: $currentLabel',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: options.map((opt) {
              final isActive = currentLabel == opt;
              return GestureDetector(
                onTap: disabled ? null : () => onSelect(opt),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isActive ? iconColor : iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(opt,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : iconColor)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TriggerCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<String> options;
  final List<String> firebaseValues;
  final bool isDark;
  final bool disabled;
  final void Function(String) onSelect;
  const _TriggerCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.iconBg,
      required this.options,
      required this.firebaseValues,
      required this.isDark,
      required this.disabled,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(options.length, (i) {
              return GestureDetector(
                onTap: disabled ? null : () => onSelect(firebaseValues[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: iconBg.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: iconBg.withOpacity(0.3))),
                  child: Text(options[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: iconBg)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  final CommandProvider cmd;
  final bool isDark;
  final AppLocalizations l10n;
  const _ClearAllButton(
      {required this.cmd, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Clear All Overrides'),
              content: Text('This will reset all override commands and return control to the ESP32 automatic system.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCritical),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Clear All'),
                ),
              ],
            ),
          );
          if (confirmed == true) await cmd.clearCommands();
        },
        icon: const Icon(Icons.clear_all_rounded, color: AppColors.statusCritical),
        label: Text('Clear All Overrides',
            style: const TextStyle(
                color: AppColors.statusCritical, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.statusCritical.withOpacity(0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}