import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Poultry Automation'**
  String get appName;

  /// No description provided for @smartFarmManagement.
  ///
  /// In en, this message translates to:
  /// **'Smart Farm Management'**
  String get smartFarmManagement;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get noInternetConnection;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get tooManyAttempts;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @poultryHouse.
  ///
  /// In en, this message translates to:
  /// **'Poultry House'**
  String get poultryHouse;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @allSystemsOnline.
  ///
  /// In en, this message translates to:
  /// **'All systems online'**
  String get allSystemsOnline;

  /// No description provided for @nodeAOffline.
  ///
  /// In en, this message translates to:
  /// **'Node A offline — no sensor data'**
  String get nodeAOffline;

  /// No description provided for @nodeBOffline.
  ///
  /// In en, this message translates to:
  /// **'Node B offline — limited data'**
  String get nodeBOffline;

  /// No description provided for @dataMayBeOutdated.
  ///
  /// In en, this message translates to:
  /// **'Data may be outdated — last update: {time}'**
  String dataMayBeOutdated(String time);

  /// No description provided for @noInternetShowingLastData.
  ///
  /// In en, this message translates to:
  /// **'No internet connection — showing last known data'**
  String get noInternetShowingLastData;

  /// No description provided for @climate.
  ///
  /// In en, this message translates to:
  /// **'Climate'**
  String get climate;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @ammonia.
  ///
  /// In en, this message translates to:
  /// **'Ammonia (NH₃)'**
  String get ammonia;

  /// No description provided for @co2.
  ///
  /// In en, this message translates to:
  /// **'CO₂'**
  String get co2;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @fanSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fan Speed'**
  String get fanSpeed;

  /// No description provided for @heaterOn.
  ///
  /// In en, this message translates to:
  /// **'Heater ON'**
  String get heaterOn;

  /// No description provided for @feedAndWater.
  ///
  /// In en, this message translates to:
  /// **'Feed & Water'**
  String get feedAndWater;

  /// No description provided for @h1Water.
  ///
  /// In en, this message translates to:
  /// **'H1 Water'**
  String get h1Water;

  /// No description provided for @h2Water.
  ///
  /// In en, this message translates to:
  /// **'H2 Water'**
  String get h2Water;

  /// No description provided for @h1Feed.
  ///
  /// In en, this message translates to:
  /// **'H1 Feed'**
  String get h1Feed;

  /// No description provided for @h2Feed.
  ///
  /// In en, this message translates to:
  /// **'H2 Feed'**
  String get h2Feed;

  /// No description provided for @eggProduction.
  ///
  /// In en, this message translates to:
  /// **'Egg Production'**
  String get eggProduction;

  /// No description provided for @todaysEggs.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Eggs'**
  String get todaysEggs;

  /// No description provided for @layingRate.
  ///
  /// In en, this message translates to:
  /// **'Laying Rate'**
  String get layingRate;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @tierBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Tier Breakdown'**
  String get tierBreakdown;

  /// No description provided for @leftBelt.
  ///
  /// In en, this message translates to:
  /// **'Left Belt'**
  String get leftBelt;

  /// No description provided for @rightBelt.
  ///
  /// In en, this message translates to:
  /// **'Right Belt'**
  String get rightBelt;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @activeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Active Alerts'**
  String get activeAlerts;

  /// No description provided for @noActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noActiveAlerts;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All Clear'**
  String get allClear;

  /// No description provided for @allSystemsOperatingNormally.
  ///
  /// In en, this message translates to:
  /// **'No active alerts at this time.\nAll systems are operating normally.'**
  String get allSystemsOperatingNormally;

  /// No description provided for @viewAlertHistory.
  ///
  /// In en, this message translates to:
  /// **'View Alert History'**
  String get viewAlertHistory;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @alertHistory.
  ///
  /// In en, this message translates to:
  /// **'Alert History'**
  String get alertHistory;

  /// No description provided for @noAlertHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No alert history yet'**
  String get noAlertHistoryYet;

  /// No description provided for @acknowledgedAlertsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged alerts will appear here.'**
  String get acknowledgedAlertsWillAppearHere;

  /// No description provided for @feedWater.
  ///
  /// In en, this message translates to:
  /// **'Feed & Water'**
  String get feedWater;

  /// No description provided for @manualOverride.
  ///
  /// In en, this message translates to:
  /// **'Manual Override'**
  String get manualOverride;

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get systemStatus;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get viewOnly;

  /// No description provided for @nodeAHealth.
  ///
  /// In en, this message translates to:
  /// **'Node A'**
  String get nodeAHealth;

  /// No description provided for @nodeBHealth.
  ///
  /// In en, this message translates to:
  /// **'Node B'**
  String get nodeBHealth;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @firmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get firmware;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// No description provided for @freeHeap.
  ///
  /// In en, this message translates to:
  /// **'Free Heap'**
  String get freeHeap;

  /// No description provided for @lastHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'Last Heartbeat'**
  String get lastHeartbeat;

  /// No description provided for @manureBelts.
  ///
  /// In en, this message translates to:
  /// **'Manure Belts'**
  String get manureBelts;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'FULL'**
  String get full;

  /// No description provided for @thresholds.
  ///
  /// In en, this message translates to:
  /// **'Thresholds'**
  String get thresholds;

  /// No description provided for @lightSchedule.
  ///
  /// In en, this message translates to:
  /// **'Light Schedule'**
  String get lightSchedule;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @adminOnly.
  ///
  /// In en, this message translates to:
  /// **'Admin only'**
  String get adminOnly;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF Report'**
  String get exportPdf;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noDataForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForThisPeriod;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @last24h.
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get last24h;

  /// No description provided for @last7d.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get last7d;

  /// No description provided for @last30d.
  ///
  /// In en, this message translates to:
  /// **'30d'**
  String get last30d;

  /// No description provided for @temperatureChart.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureChart;

  /// No description provided for @humidityChart.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityChart;

  /// No description provided for @nh3Co2Chart.
  ///
  /// In en, this message translates to:
  /// **'NH₃ / CO₂'**
  String get nh3Co2Chart;

  /// No description provided for @eggsChart.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get eggsChart;

  /// No description provided for @feedChart.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedChart;

  /// No description provided for @commandSent.
  ///
  /// In en, this message translates to:
  /// **'Command sent'**
  String get commandSent;

  /// No description provided for @commandExecuted.
  ///
  /// In en, this message translates to:
  /// **'Command executed'**
  String get commandExecuted;

  /// No description provided for @commandExpired.
  ///
  /// In en, this message translates to:
  /// **'Command expired — ESP32 may be offline'**
  String get commandExpired;

  /// No description provided for @cannotSendOffline.
  ///
  /// In en, this message translates to:
  /// **'Cannot send command — no internet connection'**
  String get cannotSendOffline;

  /// No description provided for @clearAllOverrides.
  ///
  /// In en, this message translates to:
  /// **'Clear All Overrides'**
  String get clearAllOverrides;

  /// No description provided for @confirmCommand.
  ///
  /// In en, this message translates to:
  /// **'Confirm Command'**
  String get confirmCommand;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @sendCommand.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendCommand;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
