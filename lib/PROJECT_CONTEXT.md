Here is the updated `PROJECT_CONTEXT.md`:

```markdown
# POULTRY AUTOMATION APP — PROJECT CONTEXT
> Paste this file at the start of any new Claude session to resume development instantly.

---

## PROJECT IDENTITY
- **App name:** Poultry Automation
- **Package:** `com.example.poultry_automation`
- **Project folder:** `C:\Users\solmu\OneDrive\Desktop\poultry_automation`
- **GitHub:** `https://github.com/solmula/The_real_poultry_app.git`
- **Firebase project:** `poultry-automation-93ae1`
- **RTDB URL:** `https://poultry-automation-93ae1-default-rtdb.europe-west1.firebaseapp.com`
- **Flutter version:** 3.41.1 stable
- **Device:** RMX3834 (Android), minSdk 26
- **Purpose:** Final Year Thesis — smart poultry house monitoring and control

---

## TECH STACK
| Layer | Choice |
|---|---|
| Framework | Flutter (Material3, light + dark theme) |
| State management | Provider (`ChangeNotifier`) |
| Realtime data | Firebase Realtime Database (RTDB) |
| Historical data | Cloud Firestore |
| Auth | Firebase Auth (email/password) |
| Charts | fl_chart ^0.68.0 |
| Notifications | firebase_messaging + flutter_local_notifications |

---

## FIREBASE RTDB STRUCTURE
```
/live
  /climate
    temp_avg, temp_min, temp_max, temp_z1, temp_z2, temp_z3
    rh_avg, nh3_max, co2_avg, light_avg
    fan_speed, heater (bool), lights
  /h1
    water_pct, pump_state, feed_kg, feed_pct
  /h2
    water_pct, pump_state, feed_kg, feed_pct
  /eggs
    h1_left_t1..t4, h1_right_t1..t4
    h2_left_t1..t4, h2_right_t1..t4
    total_today, laying_rate
    h1_total_today, h2_total_today, h2_laying_rate
  /manure
    h1_t1_state..h1_t4_state
    h2_t1_state..h2_t4_state
  /system
    node_a_online (bool), node_b_online (bool)
    firmware_ver, uptime_hours, heap_free_kb
    node_b_firmware, node_b_uptime_hours, node_b_last_heartbeat
  timestamp

/alerts/active
  {alert_id}
    type, value, threshold, severity, timestamp, acked, acked_by, acked_at

/commands
  fan_override, heater_override, lights_override
  trigger_feeder, trigger_manure, trigger_pump
  issued_at, expires_at, issued_by, pending (bool)

/config/thresholds
  temp_fan_low, temp_fan_high, temp_fan_off
  temp_heat_on, temp_heat_off
  nh3_warn, nh3_high, nh3_critical
  co2_high, rh_high
  water_pump_on, water_pump_off
  light_on_hour, light_on_minute, light_off_hour, light_off_minute
```

## FIRESTORE COLLECTIONS
```
sensor_history/{auto-id}
  timestamp (Timestamp), temp_avg, temp_min, temp_max,
  rh_avg, nh3_max, co2_avg, light_avg,
  h1_feed_kg, h2_feed_kg, h1_water_pct, h2_water_pct,
  eggs_total, laying_rate
  (written by ESP32 every 10 minutes)

daily_reports/{auto-id}
  date (string "YYYY-MM-DD"), total_eggs, laying_rate_pct,
  feed_consumed_kg, fcr, avg_temp, max_nh3, light_hours, alerts_count

alerts_history/{auto-id}
  type, value, threshold, severity, timestamp, acked, acked_by, acked_at

users/{uid}
  email, role (admin|operator|viewer), created_at, last_login,
  fcm_token (string — saved on login, refreshed on token change)
```

---

## COMPLETE FILE STRUCTURE
```
lib/
├── firebase_options.dart              ✅ auto-generated
├── main.dart                          ✅ MultiProvider, navigatorKey, auth routing, SplashScreen
│
├── core/
│   ├── constants/
│   │   └── firebase_paths.dart        ✅ all RTDB + Firestore path constants
│   ├── theme/
│   │   └── app_theme.dart             ✅ AppColors + full light/dark ThemeData
│   └── utils/
│       └── app_utils.dart             ✅ formatValue, formatInt, color helpers
│
├── data/
│   ├── models/
│   │   ├── sensor_data.dart           ✅ full model + tier helpers + isStale + lastUpdateText
│   │   ├── alert_model.dart           ✅ full model + displayText + parameterLabel
│   │   ├── daily_report.dart          ✅ Firestore model
│   │   └── threshold_model.dart       ✅ full model + fromJson + toJson
│   ├── providers/
│   │   ├── auth_provider.dart         ✅ email auth + role fetch + error mapping
│   │   ├── live_data_provider.dart    ✅ RTDB stream → SensorData
│   │   ├── alert_provider.dart        ✅ RTDB stream + acknowledge → Firestore
│   │   ├── threshold_provider.dart    ✅ RTDB stream + save
│   │   └── command_provider.dart      ✅ send/clear commands + expiry timer
│   └── services/
│       └── notification_service.dart  ✅ FCM init, foreground banner callback,
│                                         background handler, tap navigation,
│                                         token saved to Firestore users/{uid}/fcm_token
│
└── presentation/
    ├── screens/
    │   ├── main_shell.dart            ✅ IndexedStack, bottom nav, alert badge,
    │   │                                 initialIndex param, in-app foreground banner overlay
    │   ├── auth/
    │   │   └── login_screen.dart      ✅ email/password login UI
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart  ✅ climate grid, feed/water, egg card, alert summary
    │   ├── production/
    │   │   └── production_screen.dart ✅ H1/H2 tabs, 4-tier left/right belt breakdown
    │   ├── history/
    │   │   └── history_screen.dart    ✅ sensor_history (10-min data), 5 tabs
    │   │                                 (Temperature/Humidity/NH3+CO2/Eggs/Feed),
    │   │                                 24h/7d/30d range selector, threshold reference
    │   │                                 dashed lines, tooltip on tap, pull-to-refresh
    │   ├── alerts/
    │   │   └── alerts_screen.dart     ✅ full alert list + acknowledge button
    │   └── more/
    │       ├── more_screen.dart       ✅ role badge, menu tiles, offline banner
    │       ├── feed_water/
    │       │   └── feed_water_screen.dart    ✅ circular gauges, pump state, feed estimate
    │       ├── override/
    │       │   └── override_screen.dart      ✅ fan/heater/lights/feeder/pump controls + confirm dialog
    │       ├── settings/
    │       │   └── settings_screen.dart      ✅ threshold editor (admin), light schedule, logout
    │       └── system_status/
    │           └── system_status_screen.dart ✅ Node A/B cards, manure belts, firmware info
    └── widgets/
        ├── common/    ← empty (reserved for shared widgets)
        ├── charts/    ← empty
        └── cards/     ← empty
```

---

## BUILD STATUS
| Screen | Status | Notes |
|---|---|---|
| Login | ✅ Complete | Email/password, error messages |
| Dashboard | ✅ Complete | Climate, feed/water, eggs, alerts summary |
| Production | ✅ Complete | H1/H2 tabs, 4 tiers, left/right belt |
| History | ✅ Complete | sensor_history 10-min data, 5 tabs, 24h/7d/30d, threshold lines |
| Alerts | ✅ Complete | Full list + acknowledge |
| More | ✅ Complete | Menu with role badge |
| Feed & Water | ✅ Complete | Circular gauges, pump state, estimate |
| Manual Override | ✅ Complete | Fan/heater/lights/feeder/pump + viewer lock |
| Settings | ✅ Complete | Threshold editor (admin only), light schedule, logout |
| System Status | ✅ Complete | Node A/B health, manure belts, firmware info |

## NOTIFICATION STATUS
| Feature | Status | Notes |
|---|---|---|
| FCM init + permissions | ✅ Complete | Runs on app start |
| Background notifications | ✅ Working | System tray, tested and confirmed |
| Foreground in-app banner | ⚠️ Partial | Banner built, callback wiring being debugged |
| Tap → navigate to Alerts | ✅ Complete | Works for background tap |
| FCM token → Firestore | ✅ Complete | Saved to users/{uid}/fcm_token |
| Topic subscriptions | ✅ Complete | alerts_critical, alerts_all |

---

## ROLES & PERMISSIONS
| Role | Can view | Can send commands | Can edit thresholds |
|---|---|---|---|
| `admin` | ✅ | ✅ | ✅ |
| `operator` | ✅ | ✅ | ❌ |
| `viewer` | ✅ | ❌ | ❌ |

Roles are stored in Firestore `users/{uid}.role`. New users default to `operator`.

---

## DESIGN RULES (CRITICAL — always follow)
1. **Dark mode cards:** Never use `Theme.of(context).cardTheme.color` — always use:
   ```dart
   isDark ? AppColors.cardDark : AppColors.cardLight
   ```
2. **Material3 tinting:** All `AppBarTheme` and `CardThemeData` have `surfaceTintColor: Colors.transparent`
3. **Full code rule:** Always provide complete file code, never partial snippets
4. **Spacing:** Sections separated by `SizedBox(height: 24)`, items by `SizedBox(height: 10-12)`
5. **Text colors:** Always explicitly set — never rely on inherited theme color in dark mode

---

## KEY AppColors
```dart
primary        = 0xFF00897B  (teal)
primaryLight   = 0xFF4EBAAA
accent         = 0xFFFFB300  (amber — used for eggs)
statusGood     = 0xFF2E7D32
statusWarning  = 0xFFF57F17
statusCritical = 0xFFC62828
statusOffline  = 0xFF546E7A
cardDark       = 0xFF2D3548
backgroundDark = 0xFF0A0D14
cardLight      = 0xFFFFFFFF
backgroundLight= 0xFFEEF2F5
textLight      = 0xFFFFFFFF
textPrimary    = 0xFF1A1F2E
textSecondary  = 0xFF9CA3AF
```

---

## KNOWN ISSUES
- Foreground in-app banner not triggering — debug print added to check if
  `onForegroundAlert` callback is `null` when message arrives. Likely the
  callback is registered after the message is received (timing issue in initState).

---

## WHAT REMAINS TO BUILD
### Priority 1 — Fix foreground notification banner
- [ ] Confirm debug print output: `Callback registered: true or false`
- [ ] Fix callback timing if false

### Priority 2 — Polish & UX
- [ ] Loading shimmer/skeleton on Dashboard while data loads
- [ ] Empty state on Production screen when no egg data in Firebase

### Priority 3 — Features
- [ ] Alert history tab (view past acknowledged alerts from Firestore `alerts_history`)
- [ ] Export daily report to PDF or CSV
- [ ] Multi-language support (Amharic + English)

### Priority 4 — Hardware Integration
- [ ] Test with live ESP32 data
- [ ] Validate all Firebase paths match ESP32 firmware
- [ ] End-to-end command flow test (send → ESP32 acknowledges → `pending: false`)

---

## HOW TO RESUME IN A NEW SESSION
Paste this file and say:
> "I am building a Flutter poultry house automation app. Here is my PROJECT_CONTEXT.md. Continue as a senior Flutter developer. Always give full file code when making changes."

Then specify what to build next from the "What Remains" section above.
```

Save this as `PROJECT_CONTEXT.md` in your project root folder `C:\Users\solmu\OneDrive\Desktop\poultry_automation\PROJECT_CONTEXT.md`.

