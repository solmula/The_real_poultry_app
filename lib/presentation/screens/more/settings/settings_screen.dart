import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/threshold_provider.dart';
import '../../../../data/providers/live_data_provider.dart';
import '../../../../data/providers/language_provider.dart';
import '../../../../data/providers/notification_pref_provider.dart';
import '../../../../data/providers/theme_provider.dart';
import '../../../../data/models/threshold_model.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../user_management/user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _tempFanLow;
  late TextEditingController _tempFanHigh;
  late TextEditingController _tempFanOff;
  late TextEditingController _tempHeatOn;
  late TextEditingController _tempHeatOff;
  late TextEditingController _nh3Warn;
  late TextEditingController _nh3High;
  late TextEditingController _nh3Critical;
  late TextEditingController _co2High;
  late TextEditingController _rhHigh;
  late TextEditingController _waterPumpOn;
  late TextEditingController _waterPumpOff;

  TimeOfDay _lightOn = const TimeOfDay(hour: 5, minute: 0);
  TimeOfDay _lightOff = const TimeOfDay(hour: 21, minute: 0);
  bool _controllersInitialized = false;

  void _initControllers(ThresholdModel t) {
    if (_controllersInitialized) return;
    _tempFanLow   = TextEditingController(text: t.tempFanLow.toString());
    _tempFanHigh  = TextEditingController(text: t.tempFanHigh.toString());
    _tempFanOff   = TextEditingController(text: t.tempFanOff.toString());
    _tempHeatOn   = TextEditingController(text: t.tempHeatOn.toString());
    _tempHeatOff  = TextEditingController(text: t.tempHeatOff.toString());
    _nh3Warn      = TextEditingController(text: t.nh3Warn.toString());
    _nh3High      = TextEditingController(text: t.nh3High.toString());
    _nh3Critical  = TextEditingController(text: t.nh3Critical.toString());
    _co2High      = TextEditingController(text: t.co2High.toString());
    _rhHigh       = TextEditingController(text: t.rhHigh.toString());
    _waterPumpOn  = TextEditingController(text: t.waterPumpOn.toString());
    _waterPumpOff = TextEditingController(text: t.waterPumpOff.toString());
    _lightOn  = TimeOfDay(hour: t.lightOnHour,  minute: t.lightOnMinute);
    _lightOff = TimeOfDay(hour: t.lightOffHour, minute: t.lightOffMinute);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    if (_controllersInitialized) {
      _tempFanLow.dispose();  _tempFanHigh.dispose(); _tempFanOff.dispose();
      _tempHeatOn.dispose();  _tempHeatOff.dispose(); _nh3Warn.dispose();
      _nh3High.dispose();     _nh3Critical.dispose(); _co2High.dispose();
      _rhHigh.dispose();      _waterPumpOn.dispose(); _waterPumpOff.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.settings,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer4<AuthProvider, ThresholdProvider, LiveDataProvider, NotificationPrefProvider>(
        builder: (context, auth, thresh, live, prefs, _) {
          _initControllers(thresh.thresholds);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [

                // ── Profile ───────────────────────────────────────────
                _ProfileCard(auth: auth, isDark: isDark),
                const SizedBox(height: 24),

                // ── Language ──────────────────────────────────────────
                _SectionLabel(text: l10n.language, isDark: isDark),
                const SizedBox(height: 10),
                _LanguageCard(isDark: isDark),
                const SizedBox(height: 24),

                // ── Appearance ───────────────────────────────────────
                _SectionLabel(text: 'Appearance', isDark: isDark),
                const SizedBox(height: 10),
                _AppearanceCard(isDark: isDark),
                const SizedBox(height: 24),

                // ── Notification Preferences ────────────────────────
                _SectionLabel(text: 'Notification Preferences', isDark: isDark),
                const SizedBox(height: 10),
                _NotificationPreferencesCard(
                  isDark: isDark,
                  prefs: prefs,
                ),
                const SizedBox(height: 24),

                // ── Admin-only section ────────────────────────────────
                if (auth.isAdmin) ...[

                  // User Management
                  _SectionLabel(text: 'Administration', isDark: isDark),
                  const SizedBox(height: 10),
                  _NavigationTile(
                    icon: Icons.manage_accounts_rounded,
                    iconColor: AppColors.primary,
                    title: 'User Management',
                    subtitle: 'Invite, assign roles, disable users',
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Thresholds
                  _SectionLabel(text: l10n.thresholds, isDark: isDark),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'Temperature (°C)',
                    icon: Icons.thermostat_rounded,
                    iconColor: AppColors.statusWarning,
                    isDark: isDark,
                    fields: [
                      _FieldDef('Fan ON low',  _tempFanLow,  '°C', min: 0, max: 60, hintText: 'recommended: 18 – 24 °C'),
                      _FieldDef('Fan ON high', _tempFanHigh, '°C', min: 0, max: 60, hintText: 'recommended: 24 – 28 °C'),
                      _FieldDef('Fan OFF',     _tempFanOff,  '°C', min: 0, max: 60, hintText: 'recommended: 20 – 26 °C'),
                      _FieldDef('Heat ON',     _tempHeatOn,  '°C', min: 0, max: 60, hintText: 'recommended: 10 – 18 °C'),
                      _FieldDef('Heat OFF',    _tempHeatOff, '°C', min: 0, max: 60, hintText: 'recommended: 15 – 22 °C'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'Ammonia NH₃ (ppm)',
                    icon: Icons.air_rounded,
                    iconColor: AppColors.statusCritical,
                    isDark: isDark,
                    fields: [
                      _FieldDef('Warning',  _nh3Warn,     'ppm', min: 0, max: 100, hintText: 'recommended: 5 – 10 ppm'),
                      _FieldDef('High',     _nh3High,     'ppm', min: 0, max: 100, hintText: 'recommended: 10 – 30 ppm'),
                      _FieldDef('Critical', _nh3Critical, 'ppm', min: 0, max: 100, hintText: 'recommended: 30 – 50 ppm'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'CO₂ & Humidity',
                    icon: Icons.cloud_outlined,
                    iconColor: AppColors.severityInfo,
                    isDark: isDark,
                    fields: [
                      _FieldDef('CO₂ high', _co2High, 'ppm', min: 0, max: 10000, hintText: 'recommended: 1000 – 1500 ppm'),
                      _FieldDef('RH high',  _rhHigh,  '%', min: 1, max: 100, hintText: 'recommended: 60 – 80 %'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'Water Pump (%)',
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF1565C0),
                    isDark: isDark,
                    fields: [
                      _FieldDef('Pump ON below',  _waterPumpOn,  '%', min: 0, max: 100, hintText: 'recommended: 30 – 40 %'),
                      _FieldDef('Pump OFF above', _waterPumpOff, '%', min: 0, max: 100, hintText: 'recommended: 60 – 80 %'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _saveThresholds(thresh),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : l10n.save),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Light Schedule
                  _SectionLabel(text: l10n.lightSchedule, isDark: isDark),
                  const SizedBox(height: 10),
                  _LightScheduleCard(
                    lightOn: _lightOn,
                    lightOff: _lightOff,
                    isDark: isDark,
                    onChangedOn: (t) => setState(() => _lightOn = t),
                    onChangedOff: (t) => setState(() => _lightOff = t),
                    onSave: () => _saveLightSchedule(thresh),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Account ───────────────────────────────────────────
                _SectionLabel(text: l10n.profile, isDark: isDark),
                const SizedBox(height: 10),
                _LogoutButton(auth: auth, l10n: l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveThresholds(ThresholdProvider thresh) async {
    if (!_formKey.currentState!.validate()) return;
    
    // Verify NH3 ordering: warn < high < critical
    final nh3w = double.tryParse(_nh3Warn.text);
    final nh3h = double.tryParse(_nh3High.text);
    final nh3c = double.tryParse(_nh3Critical.text);
    if (nh3w != null && nh3h != null && nh3w >= nh3h) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('NH3 Warning must be less than NH3 High'),
              backgroundColor: AppColors.statusCritical),
        );
      }
      return;
    }
    if (nh3h != null && nh3c != null && nh3h >= nh3c) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('NH3 High must be less than NH3 Critical'),
              backgroundColor: AppColors.statusCritical),
        );
      }
      return;
    }
    
    setState(() => _saving = true);
    try {
      final updated = ThresholdModel(
        tempFanLow:     double.parse(_tempFanLow.text),
        tempFanHigh:    double.parse(_tempFanHigh.text),
        tempFanOff:     double.parse(_tempFanOff.text),
        tempHeatOn:     double.parse(_tempHeatOn.text),
        tempHeatOff:    double.parse(_tempHeatOff.text),
        nh3Warn:        double.parse(_nh3Warn.text),
        nh3High:        double.parse(_nh3High.text),
        nh3Critical:    double.parse(_nh3Critical.text),
        co2High:        double.parse(_co2High.text),
        rhHigh:         double.parse(_rhHigh.text),
        waterPumpOn:    double.parse(_waterPumpOn.text),
        waterPumpOff:   double.parse(_waterPumpOff.text),
        lightOnHour:    _lightOn.hour,
        lightOnMinute:  _lightOn.minute,
        lightOffHour:   _lightOff.hour,
        lightOffMinute: _lightOff.minute,
      );
      await thresh.saveThresholds(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).saved),
              backgroundColor: AppColors.statusGood),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save thresholds'),
              backgroundColor: AppColors.statusCritical),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveLightSchedule(ThresholdProvider thresh) async {
    try {
      final updated = ThresholdModel(
        tempFanLow:     thresh.thresholds.tempFanLow,
        tempFanHigh:    thresh.thresholds.tempFanHigh,
        tempFanOff:     thresh.thresholds.tempFanOff,
        tempHeatOn:     thresh.thresholds.tempHeatOn,
        tempHeatOff:    thresh.thresholds.tempHeatOff,
        nh3Warn:        thresh.thresholds.nh3Warn,
        nh3High:        thresh.thresholds.nh3High,
        nh3Critical:    thresh.thresholds.nh3Critical,
        co2High:        thresh.thresholds.co2High,
        rhHigh:         thresh.thresholds.rhHigh,
        waterPumpOn:    thresh.thresholds.waterPumpOn,
        waterPumpOff:   thresh.thresholds.waterPumpOff,
        lightOnHour:    _lightOn.hour,
        lightOnMinute:  _lightOn.minute,
        lightOffHour:   _lightOff.hour,
        lightOffMinute: _lightOff.minute,
      );
      await thresh.saveThresholds(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).saved),
              backgroundColor: AppColors.statusGood),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save light schedule'),
              backgroundColor: AppColors.statusCritical),
        );
      }
    }
  }
}

// ── Language Card ─────────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  final bool isDark;
  const _LanguageCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final lang = context.watch<LanguageProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🌐', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).language,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(
                  lang.isAmharic ? 'አማርኛ' : 'English',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _LangChip(
                label: 'EN',
                selected: !lang.isAmharic,
                onTap: () => lang.setLocale(const Locale('en')),
              ),
              const SizedBox(width: 8),
              _LangChip(
                label: 'አማ',
                selected: lang.isAmharic,
                onTap: () => lang.setLocale(const Locale('am')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final AuthProvider auth;
  final bool isDark;
  const _ProfileCard({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final roleColor = auth.isAdmin
        ? AppColors.primary
        : auth.isViewer
            ? AppColors.statusOffline
            : AppColors.severityInfo;
    final roleLabel =
        auth.isAdmin ? 'Admin' : auth.isViewer ? 'Viewer' : 'Operator';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.person_rounded, color: roleColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.user?.email ?? '--',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(roleLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.2),
    );
  }
}

class _FieldDef {
  final String label;
  final TextEditingController controller;
  final String unit;
  final double? min;
  final double? max;
  final String hintText;

  const _FieldDef(this.label, this.controller, this.unit,
      {this.min, this.max, this.hintText = ''});
}

// ── Notification Preferences Card ────────────────────────────────────────────
class _NotificationPreferencesCard extends StatelessWidget {
  final bool isDark;
  final NotificationPrefProvider prefs;

  const _NotificationPreferencesCard({
    required this.isDark,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _SeverityToggleRow(
            label: 'Critical',
            subtitle: 'Always enabled for safety alerts',
            value: true,
            locked: true,
            onChanged: (_) async {},
            isDark: isDark,
            color: AppColors.statusCritical,
          ),
          const SizedBox(height: 8),
          _SeverityToggleRow(
            label: 'High',
            subtitle: 'High-priority alerts and warnings',
            value: prefs.high,
            onChanged: prefs.setHigh,
            isDark: isDark,
            color: AppColors.statusWarning,
          ),
          const SizedBox(height: 8),
          _SeverityToggleRow(
            label: 'Warning',
            subtitle: 'Medium priority system warnings',
            value: prefs.warning,
            onChanged: prefs.setWarning,
            isDark: isDark,
            color: AppColors.severityInfo,
          ),
          const SizedBox(height: 8),
          _SeverityToggleRow(
            label: 'Info',
            subtitle: 'Informational notifications',
            value: prefs.info,
            onChanged: prefs.setInfo,
            isDark: isDark,
            color: AppColors.primary,
          ),
          if (prefs.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (prefs.error != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                prefs.error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.statusCritical,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Critical alerts cannot be disabled.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final bool locked;
  final Future<void> Function(bool) onChanged;
  final bool isDark;
  final Color color;

  const _SeverityToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.color,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.notifications_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: locked ? null : (next) => onChanged(next),
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

// ── Threshold Card ────────────────────────────────────────────────────────────
class _ThresholdCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final List<_FieldDef> fields;
  const _ThresholdCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.isDark,
      required this.fields});

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
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ]),
          const SizedBox(height: 14),
          ...fields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(f.label,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: f.controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                        decoration: InputDecoration(
                          suffixText: f.unit,
                          suffixStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          hintText: f.hintText,
                          hintStyle: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                        validator: (v) {
                          final parsed = double.tryParse(v ?? '');
                          if (parsed == null) return 'Invalid';
                          if (f.min != null && parsed < f.min!) {
                            return 'Min: ${f.min}';
                          }
                          if (f.max != null && parsed > f.max!) {
                            return 'Max: ${f.max}';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Light Schedule Card ───────────────────────────────────────────────────────
class _LightScheduleCard extends StatelessWidget {
  final TimeOfDay lightOn;
  final TimeOfDay lightOff;
  final bool isDark;
  final void Function(TimeOfDay) onChangedOn;
  final void Function(TimeOfDay) onChangedOff;
  final VoidCallback onSave;
  const _LightScheduleCard(
      {required this.lightOn,
      required this.lightOff,
      required this.isDark,
      required this.onChangedOn,
      required this.onChangedOff,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wb_sunny_rounded,
                color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text(l10n.lightSchedule,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _TimePicker(
                label: 'Lights ON',
                time: lightOn,
                isDark: isDark,
                onPick: (_) async {
                  final picked = await showTimePicker(
                      context: context, initialTime: lightOn);
                  if (picked != null) onChangedOn(picked);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimePicker(
                label: 'Lights OFF',
                time: lightOff,
                isDark: isDark,
                onPick: (_) async {
                  final picked = await showTimePicker(
                      context: context, initialTime: lightOff);
                  if (picked != null) onChangedOff(picked);
                },
              ),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: Text(l10n.save),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Picker ───────────────────────────────────────────────────────────────
class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool isDark;
  final void Function(TimeOfDay) onPick;
  const _TimePicker(
      {required this.label,
      required this.time,
      required this.isDark,
      required this.onPick});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPick(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(_fmt(time),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ── Navigation Tile ───────────────────────────────────────────────────────────
class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final AuthProvider auth;
  final AppLocalizations l10n;
  const _LogoutButton({required this.auth, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.logout),
              content: Text(l10n.logoutConfirm),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCritical),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.logout),
                ),
              ],
            ),
          );
          if (confirmed == true) await auth.signOut();
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.statusCritical),
        label: Text(l10n.logout,
            style: const TextStyle(
                color: AppColors.statusCritical,
                fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.statusCritical.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  final bool isDark;

  const _AppearanceCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final theme = context.watch<ThemeProvider>();

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Choose how the app follows system appearance',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest_rounded),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {theme.themeMode},
            onSelectionChanged: (selection) {
              final selected = selection.first;
              theme.setThemeMode(selected);
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.06),
              foregroundColor: AppColors.primary,
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              side: BorderSide(color: AppColors.primary.withOpacity(0.18)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}