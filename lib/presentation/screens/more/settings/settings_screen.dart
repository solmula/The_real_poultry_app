import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../data/providers/threshold_provider.dart';
import '../../../../data/providers/live_data_provider.dart';
import '../../../../data/models/threshold_model.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text('Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Consumer3<AuthProvider, ThresholdProvider, LiveDataProvider>(
        builder: (context, auth, thresh, live, _) {
          _initControllers(thresh.thresholds);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [

                _ProfileCard(auth: auth, isDark: isDark),
                const SizedBox(height: 24),

                if (auth.isAdmin) ...[
                  _SectionLabel(text: 'Alert Thresholds', isDark: isDark),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'Temperature (°C)',
                    icon: Icons.thermostat_rounded,
                    iconColor: AppColors.statusWarning,
                    isDark: isDark,
                    fields: [
                      _FieldDef('Fan ON low',  _tempFanLow,  '°C'),
                      _FieldDef('Fan ON high', _tempFanHigh, '°C'),
                      _FieldDef('Fan OFF',     _tempFanOff,  '°C'),
                      _FieldDef('Heat ON',     _tempHeatOn,  '°C'),
                      _FieldDef('Heat OFF',    _tempHeatOff, '°C'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'Ammonia NH₃ (ppm)',
                    icon: Icons.air_rounded,
                    iconColor: AppColors.statusCritical,
                    isDark: isDark,
                    fields: [
                      _FieldDef('Warning',  _nh3Warn,     'ppm'),
                      _FieldDef('High',     _nh3High,     'ppm'),
                      _FieldDef('Critical', _nh3Critical, 'ppm'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'CO₂ & Humidity',
                    icon: Icons.cloud_outlined,
                    iconColor: AppColors.severityInfo,
                    isDark: isDark,
                    fields: [
                      _FieldDef('CO₂ high', _co2High, 'ppm'),
                      _FieldDef('RH high',  _rhHigh,  '%'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _ThresholdCard(
                    title: 'Water Pump (%)',
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF1565C0),
                    isDark: isDark,
                    fields: [
                      _FieldDef('Pump ON below',  _waterPumpOn,  '%'),
                      _FieldDef('Pump OFF above', _waterPumpOff, '%'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _saveThresholds(thresh),
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save Thresholds'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _SectionLabel(text: 'Light Schedule', isDark: isDark),
                  const SizedBox(height: 10),
                  _LightScheduleCard(
                    lightOn: _lightOn,
                    lightOff: _lightOff,
                    isDark: isDark,
                    onChangedOn:  (t) => setState(() => _lightOn  = t),
                    onChangedOff: (t) => setState(() => _lightOff = t),
                    onSave: () => _saveLightSchedule(thresh),
                  ),
                  const SizedBox(height: 24),
                ],

                _SectionLabel(text: 'Account', isDark: isDark),
                const SizedBox(height: 10),
                _LogoutButton(auth: auth),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveThresholds(ThresholdProvider thresh) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = ThresholdModel(
        tempFanLow:   double.parse(_tempFanLow.text),
        tempFanHigh:  double.parse(_tempFanHigh.text),
        tempFanOff:   double.parse(_tempFanOff.text),
        tempHeatOn:   double.parse(_tempHeatOn.text),
        tempHeatOff:  double.parse(_tempHeatOff.text),
        nh3Warn:      double.parse(_nh3Warn.text),
        nh3High:      double.parse(_nh3High.text),
        nh3Critical:  double.parse(_nh3Critical.text),
        co2High:      double.parse(_co2High.text),
        rhHigh:       double.parse(_rhHigh.text),
        waterPumpOn:  double.parse(_waterPumpOn.text),
        waterPumpOff: double.parse(_waterPumpOff.text),
        lightOnHour:   thresh.thresholds.lightOnHour,
        lightOnMinute: thresh.thresholds.lightOnMinute,
        lightOffHour:  thresh.thresholds.lightOffHour,
        lightOffMinute: thresh.thresholds.lightOffMinute,
      );
      await thresh.saveThresholds(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thresholds saved'), backgroundColor: AppColors.statusGood),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save thresholds'), backgroundColor: AppColors.statusCritical),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveLightSchedule(ThresholdProvider thresh) async {
    try {
      final updated = ThresholdModel(
        tempFanLow:    thresh.thresholds.tempFanLow,
        tempFanHigh:   thresh.thresholds.tempFanHigh,
        tempFanOff:    thresh.thresholds.tempFanOff,
        tempHeatOn:    thresh.thresholds.tempHeatOn,
        tempHeatOff:   thresh.thresholds.tempHeatOff,
        nh3Warn:       thresh.thresholds.nh3Warn,
        nh3High:       thresh.thresholds.nh3High,
        nh3Critical:   thresh.thresholds.nh3Critical,
        co2High:       thresh.thresholds.co2High,
        rhHigh:        thresh.thresholds.rhHigh,
        waterPumpOn:   thresh.thresholds.waterPumpOn,
        waterPumpOff:  thresh.thresholds.waterPumpOff,
        lightOnHour:   _lightOn.hour,
        lightOnMinute: _lightOn.minute,
        lightOffHour:  _lightOff.hour,
        lightOffMinute: _lightOff.minute,
      );
      await thresh.saveThresholds(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Light schedule saved'), backgroundColor: AppColors.statusGood),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save light schedule'), backgroundColor: AppColors.statusCritical),
        );
      }
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final AuthProvider auth;
  final bool isDark;
  const _ProfileCard({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    final roleColor = auth.isAdmin ? AppColors.primary : auth.isViewer ? AppColors.statusOffline : AppColors.severityInfo;
    final roleLabel = auth.isAdmin ? 'Admin' : auth.isViewer ? 'Viewer' : 'Operator';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.person_rounded, color: roleColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.user?.email ?? '--',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor)),
                ),
              ],
            ),
          ),
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
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2),
    );
  }
}

class _FieldDef {
  final String label;
  final TextEditingController controller;
  final String unit;
  const _FieldDef(this.label, this.controller, this.unit);
}

class _ThresholdCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final List<_FieldDef> fields;
  const _ThresholdCard({required this.title, required this.icon, required this.iconColor, required this.isDark, required this.fields});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          ]),
          const SizedBox(height: 14),
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(f.label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: f.controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    decoration: InputDecoration(
                      suffixText: f.unit,
                      suffixStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
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

class _LightScheduleCard extends StatelessWidget {
  final TimeOfDay lightOn;
  final TimeOfDay lightOff;
  final bool isDark;
  final void Function(TimeOfDay) onChangedOn;
  final void Function(TimeOfDay) onChangedOff;
  final VoidCallback onSave;
  const _LightScheduleCard({required this.lightOn, required this.lightOff, required this.isDark, required this.onChangedOn, required this.onChangedOff, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textLight : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text('Daily Light Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _TimePicker(
                label: 'Lights ON',
                time: lightOn,
                isDark: isDark,
                onPick: (_) async {
                  final picked = await showTimePicker(context: context, initialTime: lightOn);
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
                  final picked = await showTimePicker(context: context, initialTime: lightOff);
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
              label: const Text('Save Schedule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool isDark;
  final void Function(TimeOfDay) onPick;
  const _TimePicker({required this.label, required this.time, required this.isDark, required this.onPick});

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
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(_fmt(time), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AuthProvider auth;
  const _LogoutButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCritical),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          if (confirmed == true) await auth.signOut();
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.statusCritical),
        label: const Text('Logout', style: TextStyle(color: AppColors.statusCritical, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.statusCritical.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}