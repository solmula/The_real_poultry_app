import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/live_data_provider.dart';
import '../../../../data/providers/command_provider.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/threshold_provider.dart';
import '../../../../data/models/threshold_model.dart';
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
        title: Text(l10n.manualOverride,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer3<LiveDataProvider, CommandProvider, AuthProvider>(
        builder: (context, live, cmd, auth, _) {
          final d = live.data;
          final isViewer = auth.isViewer;
          final thresholdProvider = context.watch<ThresholdProvider>();

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
                    label: 'Set fan to $val?', fanOverride: val),
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
                    label: 'Set heater to $val?',
                    heaterOverride: val == 'Auto' ? 'AUTO' : val.toUpperCase()),
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
                    label: 'Set lights to $val?',
                    lightsOverride: val == 'Auto' ? 'AUTO' : val.toUpperCase()),
              ),
              const SizedBox(height: 12),

              _AdminThresholdEditorCard(
                isDark: isDark,
                thresholdProvider: thresholdProvider,
                canEdit: auth.isAdmin,
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
                firebaseValues: const [
                  'h1_left', 'h1_right', 'h2_left', 'h2_right', 'all'
                ],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Trigger feeder: $val?', triggerFeeder: val),
              ),
              const SizedBox(height: 10),

              _TriggerCard(
                title: 'Trigger Manure Belt',
                icon: Icons.recycling_rounded,
                iconColor: Colors.white,
                iconBg: const Color(0xFF6D4C41),
                options: const [
                  'H1-T1', 'H1-T2', 'H1-T3', 'H1-T4',
                  'H2-T1', 'H2-T2', 'H2-T3', 'H2-T4', 'All'
                ],
                firebaseValues: const [
                  'h1_t1', 'h1_t2', 'h1_t3', 'h1_t4',
                  'h2_t1', 'h2_t2', 'h2_t3', 'h2_t4', 'all'
                ],
                isDark: isDark,
                disabled: isViewer,
                onSelect: (val) => _sendWithConfirm(context, cmd, l10n,
                    label: 'Run manure belt: $val?', triggerManure: val),
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
                    label: 'Trigger water pump: $val?', triggerPump: val),
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

// ─── View Only Banner ────────────────────────────────────────────────────────
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
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.statusOffline, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'View only — you do not have permission to send commands',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.statusOffline,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Command Status Card ─────────────────────────────────────────────────────
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color))
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

// ─── Section Label ───────────────────────────────────────────────────────────
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

// ─── Fan Override Card ───────────────────────────────────────────────────────
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
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wind_power_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(l10n.fanSpeed,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const Spacer(),
            Text('Now: $currentState',
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

// ─── Toggle Override Card ────────────────────────────────────────────────────
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const Spacer(),
            Text('Now: $currentLabel',
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
                    color: isActive
                        ? iconColor
                        : iconColor.withOpacity(0.08),
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

// ─── Trigger Card ────────────────────────────────────────────────────────────
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
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(10)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: iconBg.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: iconBg.withOpacity(0.3))),
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

// ─── Clear All Button ────────────────────────────────────────────────────────
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
              title: const Text('Clear All Overrides'),
              content: const Text(
                  'This will reset all override commands and return control to the ESP32 automatic system.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCritical),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          );
          if (confirmed == true) await cmd.clearCommands();
        },
        icon: const Icon(Icons.clear_all_rounded,
            color: AppColors.statusCritical),
        label: const Text('Clear All Overrides',
            style: TextStyle(
                color: AppColors.statusCritical,
                fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side:
              BorderSide(color: AppColors.statusCritical.withOpacity(0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Admin Threshold Editor Card ─────────────────────────────────────────────
class _AdminThresholdEditorCard extends StatefulWidget {
  final bool isDark;
  final ThresholdProvider thresholdProvider;
  final bool canEdit;

  const _AdminThresholdEditorCard({
    required this.isDark,
    required this.thresholdProvider,
    required this.canEdit,
  });

  @override
  State<_AdminThresholdEditorCard> createState() =>
      _AdminThresholdEditorCardState();
}

class _AdminThresholdEditorCardState
    extends State<_AdminThresholdEditorCard> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor =
        widget.isDark ? AppColors.textLight : AppColors.textPrimary;
    final current = widget.thresholdProvider.thresholds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  color: AppColors.statusWarning, size: 20),
              const SizedBox(width: 10),
              Text(
                'Automation Thresholds',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.canEdit
                ? 'Only admins and super admins can update automation thresholds.'
                : 'Threshold values are view-only for your role.',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _ThresholdSection(
            title: 'Temperature',
            children: [
              _ThresholdValueRow(
                  label: 'Heater ON',
                  value: '${current.tempHeatOn.toStringAsFixed(1)} °C'),
              _ThresholdValueRow(
                  label: 'Heater OFF',
                  value: '${current.tempHeatOff.toStringAsFixed(1)} °C'),
              _ThresholdValueRow(
                  label: 'Fan Low ON',
                  value: '${current.tempFanLow.toStringAsFixed(1)} °C'),
              _ThresholdValueRow(
                  label: 'Fan High ON',
                  value: '${current.tempFanHigh.toStringAsFixed(1)} °C'),
              _ThresholdValueRow(
                  label: 'Fan OFF',
                  value: '${current.tempFanOff.toStringAsFixed(1)} °C'),
            ],
          ),
          _ThresholdSection(
            title: 'Humidity',
            children: [
              _ThresholdValueRow(
                  label: 'High threshold',
                  value: '${current.rhHigh.toStringAsFixed(1)} %'),
            ],
          ),
          _ThresholdSection(
            title: 'NH3',
            children: [
              _ThresholdValueRow(
                  label: 'Warning',
                  value: '${current.nh3Warn.toStringAsFixed(1)} ppm'),
              _ThresholdValueRow(
                  label: 'Critical',
                  value: '${current.nh3Critical.toStringAsFixed(1)} ppm'),
            ],
          ),
          _ThresholdSection(
            title: 'CO2',
            children: [
              _ThresholdValueRow(
                  label: 'High threshold',
                  value: '${current.co2High.toStringAsFixed(0)} ppm'),
            ],
          ),
          _ThresholdSection(
            title: 'Light',
            children: [
              _ThresholdValueRow(
                  label: 'ON threshold',
                  value: '${current.lightOnLux.toStringAsFixed(0)} lux'),
              _ThresholdValueRow(
                  label: 'DIM threshold',
                  value: '${current.lightDimLux.toStringAsFixed(0)} lux'),
            ],
          ),
          _ThresholdSection(
            title: 'Water',
            children: [
              _ThresholdValueRow(
                  label: 'Pump ON',
                  value: '${current.waterPumpOn.toStringAsFixed(0)} %'),
              _ThresholdValueRow(
                  label: 'Pump OFF',
                  value: '${current.waterPumpOff.toStringAsFixed(0)} %'),
            ],
          ),
          _ThresholdSection(
            title: 'Feed',
            children: [
              _ThresholdValueRow(
                  label: 'Low warning',
                  value: '${current.feedWarn.toStringAsFixed(0)} %'),
              _ThresholdValueRow(
                  label: 'Critical',
                  value: '${current.feedCritical.toStringAsFixed(0)} %'),
            ],
          ),
          if (widget.canEdit) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _saving ? null : () => _openEditorDialog(context),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Thresholds'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openEditorDialog(BuildContext context) async {
    final current = widget.thresholdProvider.thresholds;

    final tempHeatOn =
        TextEditingController(text: current.tempHeatOn.toString());
    final tempHeatOff =
        TextEditingController(text: current.tempHeatOff.toString());
    final tempFanLow =
        TextEditingController(text: current.tempFanLow.toString());
    final tempFanHigh =
        TextEditingController(text: current.tempFanHigh.toString());
    final tempFanOff =
        TextEditingController(text: current.tempFanOff.toString());
    final rhHigh =
        TextEditingController(text: current.rhHigh.toString());
    final nh3Warn =
        TextEditingController(text: current.nh3Warn.toString());
    final nh3Critical =
        TextEditingController(text: current.nh3Critical.toString());
    final co2High =
        TextEditingController(text: current.co2High.toString());
    final lightOnLux =
        TextEditingController(text: current.lightOnLux.toString());
    final lightDimLux =
        TextEditingController(text: current.lightDimLux.toString());
    final waterPumpOn =
        TextEditingController(text: current.waterPumpOn.toString());
    final waterPumpOff =
        TextEditingController(text: current.waterPumpOff.toString());
    final feedWarn =
        TextEditingController(text: current.feedWarn.toString());
    final feedCritical =
        TextEditingController(text: current.feedCritical.toString());

    void disposeAll() {
      tempHeatOn.dispose();
      tempHeatOff.dispose();
      tempFanLow.dispose();
      tempFanHigh.dispose();
      tempFanOff.dispose();
      rhHigh.dispose();
      nh3Warn.dispose();
      nh3Critical.dispose();
      co2High.dispose();
      lightOnLux.dispose();
      lightDimLux.dispose();
      waterPumpOn.dispose();
      waterPumpOff.dispose();
      feedWarn.dispose();
      feedCritical.dispose();
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        // ── Validate and parse helper used inside the dialog ──────────
        String? _dialogValidate() {
          double? parse(String label, String text, double min, double max) {
            final t = text.trim();
            if (t.isEmpty) return null;
            return double.tryParse(t);
          }

          String? error;

          double? parseField(
              String label, String text, double min, double max) {
            if (error != null) return null;
            final t = text.trim();
            if (t.isEmpty) {
              error = '$label cannot be empty';
              return null;
            }
            final n = double.tryParse(t);
            if (n == null) {
              error = '$label must be a valid number';
              return null;
            }
            if (n < 0) {
              error = '$label cannot be a negative number';
              return null;
            }
            if (n < min || n > max) {
              error =
                  '$label must be between $min and $max';
              return null;
            }
            return n;
          }

          final heatOn =
              parseField('Heater ON Temp', tempHeatOn.text, 16, 20);
          final heatOff =
              parseField('Heater OFF Temp', tempHeatOff.text, 18, 22);
          final fanLow =
              parseField('Fan Low Temp', tempFanLow.text, 22, 28);
          final fanHigh =
              parseField('Fan High Temp', tempFanHigh.text, 26, 32);
          final fanOff =
              parseField('Fan OFF Temp', tempFanOff.text, 30, 38);
          parseField('Humidity High', rhHigh.text, 50, 75);
          final nh3w =
              parseField('NH3 Warning', nh3Warn.text, 5, 20);
          final nh3c =
              parseField('NH3 Critical', nh3Critical.text, 15, 35);
          parseField('CO2 High', co2High.text, 1000, 5000);
          final lOn =
              parseField('Light ON Lux', lightOnLux.text, 1, 15);
          final lDim =
              parseField('Light DIM Lux', lightDimLux.text, 10, 35);
          final wOn =
              parseField('Water Pump ON', waterPumpOn.text, 10, 50);
          final wOff =
              parseField('Water Pump OFF', waterPumpOff.text, 50, 90);
          final fWarn =
              parseField('Feed Warning', feedWarn.text, 5, 30);
          final fCrit =
              parseField('Feed Critical', feedCritical.text, 1, 15);

          if (error != null) return error;

          // Ordering checks
          if (heatOn != null && heatOff != null && heatOn >= heatOff) {
            return 'Heater ON Temp (${heatOn}°C) must be less than Heater OFF Temp (${heatOff}°C)';
          }
          if (heatOff != null && fanLow != null && heatOff >= fanLow) {
            return 'Heater OFF Temp (${heatOff}°C) must be less than Fan Low Temp (${fanLow}°C)';
          }
          if (fanLow != null && fanHigh != null && fanLow >= fanHigh) {
            return 'Fan Low Temp (${fanLow}°C) must be less than Fan High Temp (${fanHigh}°C)';
          }
          if (fanHigh != null && fanOff != null && fanHigh >= fanOff) {
            return 'Fan High Temp (${fanHigh}°C) must be less than Fan OFF Temp (${fanOff}°C)';
          }
          if (nh3w != null && nh3c != null && nh3w >= nh3c) {
            return 'NH3 Warning (${nh3w} ppm) must be less than NH3 Critical (${nh3c} ppm)';
          }
          if (lOn != null && lDim != null && lOn >= lDim) {
            return 'Light ON Lux (${lOn}) must be less than Light DIM Lux (${lDim})';
          }
          if (wOn != null && wOff != null && wOn >= wOff) {
            return 'Water Pump ON (${wOn}%) must be less than Water Pump OFF (${wOff}%)';
          }
          if (fCrit != null && fWarn != null && fCrit >= fWarn) {
            return 'Feed Critical (${fCrit}%) must be less than Feed Warning (${fWarn}%)';
          }

          return null;
        }

        return AlertDialog(
          title: const Text('Edit Thresholds'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Temperature ──────────────────────────────────────
                const _DialogSectionTitle(title: 'Temperature'),
                _ThresholdInputField(
                  label: 'Heater ON Temp (°C)',
                  hintText: '16.0 – 20.0 °C',
                  controller: tempHeatOn,
                ),
                _ThresholdInputField(
                  label: 'Heater OFF Temp (°C)',
                  hintText: '18.0 – 22.0 °C',
                  controller: tempHeatOff,
                ),
                _ThresholdInputField(
                  label: 'Fan Low Temp (°C)',
                  hintText: '22.0 – 28.0 °C',
                  controller: tempFanLow,
                ),
                _ThresholdInputField(
                  label: 'Fan High Temp (°C)',
                  hintText: '26.0 – 32.0 °C',
                  controller: tempFanHigh,
                ),
                _ThresholdInputField(
                  label: 'Fan OFF Temp (°C)',
                  hintText: '30.0 – 38.0 °C',
                  controller: tempFanOff,
                ),
                // ── Humidity ─────────────────────────────────────────
                const _DialogSectionTitle(title: 'Humidity'),
                _ThresholdInputField(
                  label: 'Humidity High (%)',
                  hintText: '50.0 – 75.0 %',
                  controller: rhHigh,
                ),
                // ── Ammonia ──────────────────────────────────────────
                const _DialogSectionTitle(title: 'Ammonia (NH3)'),
                _ThresholdInputField(
                  label: 'NH3 Warning (ppm)',
                  hintText: '5.0 – 20.0 ppm',
                  controller: nh3Warn,
                ),
                _ThresholdInputField(
                  label: 'NH3 Critical (ppm)',
                  hintText: '15.0 – 35.0 ppm',
                  controller: nh3Critical,
                ),
                // ── CO2 ──────────────────────────────────────────────
                const _DialogSectionTitle(title: 'CO2'),
                _ThresholdInputField(
                  label: 'CO2 High (ppm)',
                  hintText: '1000 – 5000 ppm',
                  controller: co2High,
                ),
                // ── Light ─────────────────────────────────────────────
                const _DialogSectionTitle(title: 'Light'),
                _ThresholdInputField(
                  label: 'Light ON threshold (lux)',
                  hintText: '1.0 – 15.0 lux',
                  controller: lightOnLux,
                ),
                _ThresholdInputField(
                  label: 'Light DIM threshold (lux)',
                  hintText: '10.0 – 35.0 lux',
                  controller: lightDimLux,
                ),
                // ── Water ─────────────────────────────────────────────
                const _DialogSectionTitle(title: 'Water'),
                _ThresholdInputField(
                  label: 'Water Pump ON (%)',
                  hintText: '10.0 – 50.0 %',
                  controller: waterPumpOn,
                ),
                _ThresholdInputField(
                  label: 'Water Pump OFF (%)',
                  hintText: '50.0 – 90.0 %',
                  controller: waterPumpOff,
                ),
                // ── Feed ──────────────────────────────────────────────
                const _DialogSectionTitle(title: 'Feed'),
                _ThresholdInputField(
                  label: 'Feed Warning (%)',
                  hintText: '5.0 – 30.0 %',
                  controller: feedWarn,
                ),
                _ThresholdInputField(
                  label: 'Feed Critical (%)',
                  hintText: '1.0 – 15.0 %',
                  controller: feedCritical,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate INSIDE the dialog before closing
                final error = _dialogValidate();
                if (error != null) {
                  // Show error inside dialog context — always visible
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.statusCritical,
                      duration: const Duration(seconds: 5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return; // Do NOT close dialog
                }
                // All valid — close dialog and proceed to save
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      disposeAll();
      return;
    }

    setState(() => _saving = true);

    try {
      final updated = ThresholdModel(
        tempHeatOn: double.parse(tempHeatOn.text.trim()),
        tempHeatOff: double.parse(tempHeatOff.text.trim()),
        tempFanLow: double.parse(tempFanLow.text.trim()),
        tempFanHigh: double.parse(tempFanHigh.text.trim()),
        tempFanOff: double.parse(tempFanOff.text.trim()),
        rhHigh: double.parse(rhHigh.text.trim()),
        nh3Warn: double.parse(nh3Warn.text.trim()),
        nh3High: current.nh3High,
        nh3Critical: double.parse(nh3Critical.text.trim()),
        co2High: double.parse(co2High.text.trim()),
        lightOnLux: double.parse(lightOnLux.text.trim()),
        lightDimLux: double.parse(lightDimLux.text.trim()),
        waterPumpOn: double.parse(waterPumpOn.text.trim()),
        waterPumpOff: double.parse(waterPumpOff.text.trim()),
        feedWarn: double.parse(feedWarn.text.trim()),
        feedCritical: double.parse(feedCritical.text.trim()),
        lightOnHour: current.lightOnHour,
        lightOnMinute: current.lightOnMinute,
        lightOffHour: current.lightOffHour,
        lightOffMinute: current.lightOffMinute,
      );

      await widget.thresholdProvider.saveThresholds(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Thresholds saved successfully'),
            backgroundColor: AppColors.statusGood,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save thresholds: $e'),
            backgroundColor: AppColors.statusCritical,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      disposeAll();
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Dialog Section Title ────────────────────────────────────────────────────
class _DialogSectionTitle extends StatelessWidget {
  final String title;
  const _DialogSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Threshold Section ───────────────────────────────────────────────────────
class _ThresholdSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ThresholdSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

// ─── Threshold Value Row ─────────────────────────────────────────────────────
class _ThresholdValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ThresholdValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Threshold Input Field ───────────────────────────────────────────────────
class _ThresholdInputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;

  const _ThresholdInputField({
    required this.label,
    required this.controller,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Block minus sign and any non-numeric characters except decimal point
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}