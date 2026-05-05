import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/live_data_provider.dart';
import '../../data/providers/alert_provider.dart';
import '../../data/providers/threshold_provider.dart';
import '../../data/providers/command_provider.dart';
import '../../data/services/notification_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'dashboard/dashboard_screen.dart';
import 'production/production_screen.dart';
import 'history/history_screen.dart';
import 'alerts/alerts_screen.dart';
import 'more/more_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  // In-app banner state
  String? _bannerTitle;
  String? _bannerBody;
  String? _bannerSeverity;
  bool _bannerVisible = false;

  List<Widget> get _screens => [
    DashboardScreen(onNavigateToAlerts: () => setState(() => _currentIndex = 3)),
    const ProductionScreen(),
    const HistoryScreen(),
    const AlertsScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveDataProvider>().startListening();
      context.read<AlertProvider>().startListening();
      context.read<ThresholdProvider>().startListening();
      context.read<CommandProvider>().startListening();

      // Register foreground alert banner callback
      NotificationService.onForegroundAlert = (title, body, severity) {
        if (!mounted) return;
        setState(() {
          _bannerTitle = title;
          _bannerBody = body;
          _bannerSeverity = severity;
          _bannerVisible = true;
        });
        // Auto-dismiss after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _bannerVisible = false);
        });
      };
    });
  }

  @override
  void dispose() {
    NotificationService.onForegroundAlert = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // In-app notification banner
          if (_bannerVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _AlertBanner(
                title: _bannerTitle ?? '',
                body: _bannerBody ?? '',
                severity: _bannerSeverity ?? 'INFO',
                onTap: () {
                  setState(() => _bannerVisible = false);
                  setState(() => _currentIndex = 3);
                },
                onDismiss: () {
                  setState(() => _bannerVisible = false);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, _) {
        final l10n = AppLocalizations.of(context);
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: Colors.grey.withOpacity(0.15), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_rounded),
                label: l10n.dashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.egg_rounded),
                label: l10n.production,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.show_chart_rounded),
                label: l10n.history,
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_rounded),
                    if (alertProvider.activeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: alertProvider.badgeColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            alertProvider.activeCount > 99
                                ? '99+'
                                : '${alertProvider.activeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: l10n.alerts,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.more_horiz_rounded),
                label: l10n.more,
              ),
            ],
          ),
        );
      },
    );
  }
}

// In-app alert banner
class _AlertBanner extends StatefulWidget {
  final String title;
  final String body;
  final String severity;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AlertBanner({
    required this.title,
    required this.body,
    required this.severity,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<_AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bannerColor {
    switch (widget.severity) {
      case 'CRITICAL': return const Color(0xFFB71C1C);
      case 'HIGH':     return const Color(0xFFE65100);
      case 'WARNING':  return const Color(0xFFF57F17);
      default:         return const Color(0xFF1565C0);
    }
  }

  IconData get _bannerIcon {
    switch (widget.severity) {
      case 'CRITICAL': return Icons.crisis_alert_rounded;
      case 'HIGH':     return Icons.warning_rounded;
      case 'WARNING':  return Icons.warning_amber_rounded;
      default:         return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SlideTransition(
      position: _slide,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(
              top: topPadding + 8, left: 12, right: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _bannerColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _bannerColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_bannerIcon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.body,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}