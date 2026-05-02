// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appName => 'የዶሮ አስተዳደር';

  @override
  String get smartFarmManagement => 'ዘመናዊ የእርሻ አስተዳደር';

  @override
  String get login => 'ግባ';

  @override
  String get email => 'ኢሜይል';

  @override
  String get password => 'የሚስጥር ቁጥር';

  @override
  String get forgotPassword => 'የሚስጥር ቁጥር ረሳህ?';

  @override
  String get invalidEmailOrPassword => 'ኢሜይል ወይም የሚስጥር ቁጥር ትክክል አይደለም';

  @override
  String get noInternetConnection => 'የኢንተርኔት ግንኙነት የለም። እንደገና ሞክር።';

  @override
  String get tooManyAttempts => 'ብዙ ጊዜ ሞክረሃል። ጥቂት ጠብቅና እንደገና ሞክር።';

  @override
  String get emailRequired => 'ኢሜይል ያስፈልጋል';

  @override
  String get passwordRequired => 'የሚስጥር ቁጥር ያስፈልጋል';

  @override
  String get dashboard => 'ዳሽቦርድ';

  @override
  String get production => 'ምርት';

  @override
  String get history => 'ታሪክ';

  @override
  String get alerts => 'ማንቂያዎች';

  @override
  String get more => 'ተጨማሪ';

  @override
  String get poultryHouse => 'የዶሮ ቤት';

  @override
  String get loading => 'በመጫን ላይ...';

  @override
  String get connecting => 'በመገናኘት ላይ...';

  @override
  String get refreshing => 'በማዘምን ላይ...';

  @override
  String get updated => 'ዘምኗል';

  @override
  String get allSystemsOnline => 'ሁሉም ስርዓቶች ተያይዘዋል';

  @override
  String get nodeAOffline => 'Node A ተቋርጧል — የሴንሰር ዳታ የለም';

  @override
  String get nodeBOffline => 'Node B ተቋርጧል — ውስን ዳታ';

  @override
  String dataMayBeOutdated(String time) {
    return 'ዳታ ያረጀ ሊሆን ይችላል — የመጨረሻ ዝማኔ: $time';
  }

  @override
  String get noInternetShowingLastData =>
      'የኢንተርኔት ግንኙነት የለም — የመጨረሻ ዳታ እየታየ ነው';

  @override
  String get climate => 'የአየር ሁኔታ';

  @override
  String get temperature => 'የሙቀት መጠን';

  @override
  String get humidity => 'እርጥበት';

  @override
  String get ammonia => 'አሞኒያ (NH₃)';

  @override
  String get co2 => 'CO₂';

  @override
  String get light => 'ብርሃን';

  @override
  String get fanSpeed => 'የአየር ማናፈሻ ፍጥነት';

  @override
  String get heaterOn => 'ማሞቂያ አብርቷል';

  @override
  String get feedAndWater => 'መኖ እና ውሃ';

  @override
  String get h1Water => 'ቤት 1 ውሃ';

  @override
  String get h2Water => 'ቤት 2 ውሃ';

  @override
  String get h1Feed => 'ቤት 1 መኖ';

  @override
  String get h2Feed => 'ቤት 2 መኖ';

  @override
  String get eggProduction => 'የእንቁላል ምርት';

  @override
  String get todaysEggs => 'የዛሬ እንቁላሎች';

  @override
  String get layingRate => 'የምርት መጠን';

  @override
  String get good => 'ጥሩ';

  @override
  String get low => 'ዝቅተኛ';

  @override
  String get tierBreakdown => 'የደረጃ ዝርዝር';

  @override
  String get leftBelt => 'ግራ ቀበቶ';

  @override
  String get rightBelt => 'ቀኝ ቀበቶ';

  @override
  String get total => 'ጠቅላላ';

  @override
  String get activeAlerts => 'ንቁ ማንቂያዎች';

  @override
  String get noActiveAlerts => 'ንቁ ማንቂያ የለም';

  @override
  String get active => 'ንቁ';

  @override
  String get allClear => 'ሁሉም ጥሩ ነው';

  @override
  String get allSystemsOperatingNormally =>
      'በአሁኑ ጊዜ ንቁ ማንቂያ የለም።\nሁሉም ስርዓቶች በሚገባ እየሰሩ ነው።';

  @override
  String get viewAlertHistory => 'የማንቂያ ታሪክ ይመልከቱ';

  @override
  String get acknowledge => 'ተቀብያለሁ';

  @override
  String get alertHistory => 'የማንቂያ ታሪክ';

  @override
  String get noAlertHistoryYet => 'እስካሁን የማንቂያ ታሪክ የለም';

  @override
  String get acknowledgedAlertsWillAppearHere => 'የተቀበሉ ማንቂያዎች እዚህ ይታያሉ።';

  @override
  String get feedWater => 'መኖ እና ውሃ';

  @override
  String get manualOverride => 'እጅ በእጅ ቁጥጥር';

  @override
  String get systemStatus => 'የስርዓት ሁኔታ';

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get operations => 'ስራዎች';

  @override
  String get system => 'ስርዓት';

  @override
  String get viewOnly => 'ማየት ብቻ';

  @override
  String get nodeAHealth => 'Node A';

  @override
  String get nodeBHealth => 'Node B';

  @override
  String get online => 'ተያይዟል';

  @override
  String get offline => 'ተቋርጧል';

  @override
  String get firmware => 'ፈርምዌር';

  @override
  String get uptime => 'የስራ ሰዓት';

  @override
  String get freeHeap => 'ነጻ ማህደረ ትውስታ';

  @override
  String get lastHeartbeat => 'የመጨረሻ ምልክት';

  @override
  String get manureBelts => 'የፍሳሽ ቀበቶዎች';

  @override
  String get ok => 'ጥሩ';

  @override
  String get full => 'ሞልቷል';

  @override
  String get thresholds => 'የገደብ እሴቶች';

  @override
  String get lightSchedule => 'የብርሃን ጊዜ ሰሌዳ';

  @override
  String get notificationPreferences => 'የማሳወቂያ ምርጫዎች';

  @override
  String get profile => 'መገለጫ';

  @override
  String get logout => 'ውጣ';

  @override
  String get logoutConfirm => 'መውጣት ይፈልጋሉ?';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get save => 'አስቀምጥ';

  @override
  String get saved => 'ተቀምጧል';

  @override
  String get adminOnly => 'አስተዳዳሪ ብቻ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get english => 'English';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get exportPdf => 'PDF ሪፖርት ላክ';

  @override
  String get exportFailed => 'መላክ አልተሳካም';

  @override
  String get retry => 'እንደገና ሞክር';

  @override
  String get refresh => 'አድስ';

  @override
  String get noDataForThisPeriod => 'ለዚህ ጊዜ ዳታ የለም';

  @override
  String get failedToLoad => 'መጫን አልተሳካም';

  @override
  String get noHistoryYet => 'እስካሁን ታሪክ የለም';

  @override
  String get last24h => '24ሰ';

  @override
  String get last7d => '7ቀ';

  @override
  String get last30d => '30ቀ';

  @override
  String get temperatureChart => 'የሙቀት መጠን';

  @override
  String get humidityChart => 'እርጥበት';

  @override
  String get nh3Co2Chart => 'NH₃ / CO₂';

  @override
  String get eggsChart => 'እንቁላሎች';

  @override
  String get feedChart => 'መኖ';

  @override
  String get commandSent => 'ትዕዛዝ ተልኳል';

  @override
  String get commandExecuted => 'ትዕዛዝ ተፈጽሟል';

  @override
  String get commandExpired => 'ትዕዛዝ ጊዜው አልፏል — ESP32 ተቋርጧል';

  @override
  String get cannotSendOffline => 'ትዕዛዝ መላክ አይቻልም — የኢንተርኔት ግንኙነት የለም';

  @override
  String get clearAllOverrides => 'ሁሉንም ትዕዛዞች ሰርዝ';

  @override
  String get confirmCommand => 'ትዕዛዝ አረጋግጥ';

  @override
  String get confirm => 'አረጋግጥ';

  @override
  String get sendCommand => 'ላክ';

  @override
  String hoursAgo(int hours) {
    return 'ከ$hours ሰዓት በፊት';
  }

  @override
  String minutesAgo(int minutes) {
    return 'ከ$minutes ደቂቃ በፊት';
  }

  @override
  String daysAgo(int days) {
    return 'ከ$days ቀን በፊት';
  }

  @override
  String get justNow => 'አሁን';

  @override
  String get never => 'ፈጽሞ አይደለም';
}
