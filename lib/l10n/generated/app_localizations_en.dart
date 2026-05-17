// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Poultry Automation';

  @override
  String get smartFarmManagement => 'Smart Farm Management';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get noInternetConnection =>
      'No internet connection. Please try again.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please wait and try again.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get production => 'Production';

  @override
  String get history => 'History';

  @override
  String get alerts => 'Alerts';

  @override
  String get more => 'More';

  @override
  String get poultryHouse => 'Poultry House';

  @override
  String get loading => 'Loading...';

  @override
  String get connecting => 'Connecting...';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get updated => 'Updated';

  @override
  String get allSystemsOnline => 'All systems online';

  @override
  String get nodeAOffline => 'Main controller offline — no sensor data';

  @override
  String get nodeBOffline =>
      'Equipment controller offline — belt & egg data unavailable';

  @override
  String dataMayBeOutdated(String time) {
    return 'Data may be outdated — last update: $time';
  }

  @override
  String get noInternetShowingLastData =>
      'No internet connection — showing last known data';

  @override
  String get climate => 'Climate';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get ammonia => 'Ammonia (NH₃)';

  @override
  String get co2 => 'CO₂';

  @override
  String get light => 'Light';

  @override
  String get fanSpeed => 'Fan Speed';

  @override
  String get heaterOn => 'Heater ON';

  @override
  String get feedAndWater => 'Feed & Water';

  @override
  String get h1Water => 'H1 Water';

  @override
  String get h2Water => 'H2 Water';

  @override
  String get h1Feed => 'H1 Feed';

  @override
  String get h2Feed => 'H2 Feed';

  @override
  String get eggProduction => 'Egg Production';

  @override
  String get todaysEggs => 'Today\'s Eggs';

  @override
  String get layingRate => 'Laying Rate';

  @override
  String get good => 'Good';

  @override
  String get low => 'Low';

  @override
  String get tierBreakdown => 'Tier Breakdown';

  @override
  String get leftBelt => 'Left Belt';

  @override
  String get rightBelt => 'Right Belt';

  @override
  String get total => 'Total';

  @override
  String get activeAlerts => 'Active Alerts';

  @override
  String get noActiveAlerts => 'No active alerts';

  @override
  String get active => 'active';

  @override
  String get allClear => 'All Clear';

  @override
  String get allSystemsOperatingNormally =>
      'No active alerts at this time.\nAll systems are operating normally.';

  @override
  String get viewAlertHistory => 'View Alert History';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get alertHistory => 'Alert History';

  @override
  String get noAlertHistoryYet => 'No alert history yet';

  @override
  String get acknowledgedAlertsWillAppearHere =>
      'Acknowledged alerts will appear here.';

  @override
  String get feedWater => 'Feed & Water';

  @override
  String get manualOverride => 'Manual Override';

  @override
  String get systemStatus => 'System Status';

  @override
  String get settings => 'Settings';

  @override
  String get operations => 'Operations';

  @override
  String get system => 'System';

  @override
  String get viewOnly => 'View only';

  @override
  String get nodeAHealth => 'Main Controller';

  @override
  String get nodeBHealth => 'Equipment Controller';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get firmware => 'Firmware';

  @override
  String get uptime => 'Uptime';

  @override
  String get freeHeap => 'Free Heap';

  @override
  String get lastHeartbeat => 'Last Heartbeat';

  @override
  String get manureBelts => 'Manure Belts';

  @override
  String get ok => 'OK';

  @override
  String get full => 'FULL';

  @override
  String get thresholds => 'Thresholds';

  @override
  String get lightSchedule => 'Light Schedule';

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get adminOnly => 'Admin only';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get exportPdf => 'Export PDF Report';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get noDataForThisPeriod => 'No data for this period';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get last24h => '24h';

  @override
  String get last7d => '7d';

  @override
  String get last30d => '30d';

  @override
  String get temperatureChart => 'Temperature';

  @override
  String get humidityChart => 'Humidity';

  @override
  String get nh3Co2Chart => 'NH₃ / CO₂';

  @override
  String get eggsChart => 'Eggs';

  @override
  String get feedChart => 'Feed';

  @override
  String get commandSent => 'Command sent';

  @override
  String get commandExecuted => 'Command executed';

  @override
  String get commandExpired => 'Command expired — ESP32 may be offline';

  @override
  String get cannotSendOffline =>
      'Cannot send command — no internet connection';

  @override
  String get clearAllOverrides => 'Clear All Overrides';

  @override
  String get confirmCommand => 'Confirm Command';

  @override
  String get confirm => 'Confirm';

  @override
  String get sendCommand => 'Send';

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get justNow => 'just now';

  @override
  String get never => 'Never';
}
