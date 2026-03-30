import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'chats_screen.dart';
import 'profile_screen.dart';
import '../providers.dart';
// import '../services/push_notification_service.dart'; // Eğer Firebase'i kullanacaksak

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});
  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int index = 0;
  Timer? _globalPollingTimer;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoverScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    _startGlobalPolling();
  }

  void _startGlobalPolling() {
    // Tüm uygulama genelinde her 5 saniyede bir sohbetleri/bildirimleri kontrol et
    _globalPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;

      // Sadece sohbet sekmesinde değilsek veya genel bir badge göstermek istiyorsak
      // API'ye sessiz bir istek atıp Riverpod state'ini güncelleyebiliriz
      ref.invalidate(chatsProvider);

      // Bildirimleri de yenileyebiliriz
      ref.invalidate(notificationsProvider);
    });
  }

  @override
  void dispose() {
    _globalPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool('permissions_requested') ?? false;

    if (!hasRequested) {
      // 1. Konum İzni İste
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      } catch (e) {
        debugPrint('Konum izni alınırken hata: $e');
      }

      // 2. Bildirim İzni İste
      try {
        // final pushService = PushNotificationService();
        // await pushService.initialize();
      } catch (e) {
        debugPrint('Bildirim izni alınırken hata: $e');
      }

      // Sadece bir kez sorması için flag'i true yap
      await prefs.setBool('permissions_requested', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true, // Arka planın NavigationBar altına uzanmasını sağlar
      body: SizedBox.expand(child: _screens[index]),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(cs, 0, Icons.home_outlined, Icons.home_rounded),
              _buildNavItem(
                cs,
                1,
                Icons.explore_outlined,
                Icons.explore_rounded,
              ),
              _buildNavItem(
                cs,
                2,
                Icons.chat_bubble_outline,
                Icons.chat_bubble_rounded,
              ),
              _buildNavItem(cs, 3, Icons.person_outline, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    ColorScheme cs,
    int itemIndex,
    IconData unselectedIcon,
    IconData selectedIcon,
  ) {
    final isSelected = index == itemIndex;

    return GestureDetector(
      onTap: () => setState(() => index = itemIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? cs.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color:
              isSelected
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.7),
          size: 26,
        ),
      ),
    );
  }
}
