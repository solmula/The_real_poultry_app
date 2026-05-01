import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppUtils {
  AppUtils._();

  static String formatValue(double? value, String unit, {int decimals = 1}) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(decimals)}$unit';
  }

  static String formatInt(int? value) {
    if (value == null) return '--';
    return value.toString();
  }

  static Color tempColor(double? temp) {
    if (temp == null) return AppColors.textSecondary;
    if (temp >= 30) return AppColors.statusCritical;
    if (temp >= 27) return AppColors.statusWarning;
    if (temp <= 16) return AppColors.statusCritical;
    if (temp <= 19) return AppColors.severityInfo;
    return AppColors.statusGood;
  }

  static Color nh3Color(double? nh3) {
    if (nh3 == null) return AppColors.textSecondary;
    if (nh3 >= 35) return AppColors.statusCritical;
    if (nh3 >= 20) return AppColors.severityHigh;
    if (nh3 >= 10) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  static Color humidityColor(double? rh) {
    if (rh == null) return AppColors.textSecondary;
    if (rh >= 75) return AppColors.statusCritical;
    if (rh >= 72) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  static Color levelColor(double? pct) {
    if (pct == null) return AppColors.textSecondary;
    if (pct <= 10) return AppColors.statusCritical;
    if (pct <= 20) return AppColors.statusWarning;
    return AppColors.statusGood;
  }

  static Color severityColor(String severity) {
    switch (severity) {
      case 'CRITICAL': return AppColors.severityCritical;
      case 'HIGH': return AppColors.severityHigh;
      case 'WARNING': return AppColors.severityWarning;
      default: return AppColors.severityInfo;
    }
  }
}