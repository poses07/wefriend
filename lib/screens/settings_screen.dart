import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'privacy_security_screen.dart';
import 'blocked_users_screen.dart';
import 'auth_screens.dart';
import 'admin_dashboard_screen.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Riverpod State'lerini oku
    final isDarkMode =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final isNotificationsEnabled = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uygulama Tercihleri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    _buildSettingItem(
                      context: context,
                      icon: Icons.notifications_active_rounded,
                      title: 'Bildirimler',
                      iconColor: cs.primary,
                      trailing: Switch(
                        value: isNotificationsEnabled,
                        onChanged: (v) {
                          ref
                              .read(notificationsProvider.notifier)
                              .setNotifications(v);
                        },
                        activeColor: cs.primary,
                      ),
                      onTap: () {
                        ref.read(notificationsProvider.notifier).toggle();
                      },
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      indent: 70,
                    ),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.dark_mode_rounded,
                      title: 'Karanlık Tema',
                      iconColor: Colors.deepPurple.shade400,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (v) {
                          ref.read(themeProvider.notifier).toggleTheme(v);
                        },
                        activeColor: cs.primary,
                      ),
                      onTap: () {
                        ref
                            .read(themeProvider.notifier)
                            .toggleTheme(!isDarkMode);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Hesap ve Güvenlik',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    _buildSettingItem(
                      context: context,
                      icon: Icons.security_rounded,
                      title: 'Gizlilik ve Güvenlik',
                      iconColor: Colors.blue.shade400,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacySecurityScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      indent: 70,
                    ),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.block_rounded,
                      title: 'Engellenen Kullanıcılar',
                      iconColor: Colors.redAccent.shade400,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        );
                      },
                    ),

                    // Admin Paneli (Sadece is_admin = 1 olanlara göster)
                    ref
                        .watch(userProfileProvider)
                        .when(
                          data: (profile) {
                            final isAdmin =
                                profile?['is_admin'] == 1 ||
                                profile?['is_admin'] == '1';
                            if (isAdmin) {
                              return Column(
                                children: [
                                  Divider(
                                    height: 1,
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                                    indent: 70,
                                  ),
                                  _buildSettingItem(
                                    context: context,
                                    icon: Icons.admin_panel_settings_rounded,
                                    title: 'Yönetim Paneli (Admin)',
                                    iconColor: Colors.deepPurple,
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const AdminDashboardScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Çıkış Butonu
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.redAccent.shade200, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final api = ref.read(apiServiceProvider);
                    await api.logout();
                    ref.invalidate(userProfileProvider);

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
