import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'quests_screen.dart'; // Görevler ve Rozetler sayfası için eklendi
import '../providers.dart';
import 'store_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Riverpod State'lerini oku
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Profil yüklenemedi: $err'),
                  TextButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }

          final alias = user['alias'] ?? 'İsimsiz';
          final age = user['age'] != null ? ', ${user['age']}' : '';
          final city = user['city'] ?? 'Gizli Konum';
          final avatarUrl = user['avatar_url']; // Removed fallback to pravatar
          final rankLevel =
              user['rank_level'] == 'popular'
                  ? 'Popüler'
                  : (user['rank_level'] == 'legendary' ? 'Efsanevi' : 'Yeni');
          final badges = user['badges'] as List<dynamic>? ?? [];

          // Kullanıcının sahip olduğu rozetler
          final earnedBadges = badges.map((b) => b['name'] as String).toList();

          // Sistemdeki tüm rozet tipleri (Örnek tasarım için sabit)
          final allBadgeTypes = [
            {
              'name': 'İlk Adım',
              'icon': Icons.emoji_events,
              'color': Colors.amber,
            },
            {
              'name': 'Sohbet Kuşu',
              'icon': Icons.chat_bubble,
              'color': Colors.green,
            },
            {
              'name': 'Sosyal Kelebek',
              'icon': Icons.place,
              'color': Colors.red,
            },
            {
              'name': 'Gecelerin Yargıcı',
              'icon': Icons.nights_stay,
              'color': Colors.purple,
            },
          ];

          final views = user['stats']?['views'] ?? 0;
          final likes = user['stats']?['likes'] ?? 0;
          final xpPoints = user['xp_points'] ?? 0;
          final isPremium =
              user['rank_level'] == 'popular' ||
              user['rank_level'] == 'legendary';

          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Üst Kısım: Düzenle ve Ayarlar İkonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Profili Düzenle İkonu (Sol Üst)
                        IconButton(
                          icon: Icon(
                            Icons.edit_note_rounded,
                            size: 28,
                            color: cs.primary,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        // Ayarlar İkonu (Sağ Üst)
                        Row(
                          children: [
                            // Jeton / Bakiye İkonu
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const StoreScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.generating_tokens_rounded,
                                      size: 18,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user['coins'] ?? 0}',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.settings_rounded,
                                size: 28,
                              ),
                              color: cs.onSurface,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Premium Üst Kısım (Avatar ve İsim)
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Sadece premium üyelerde gradient ve gölge göster
                            gradient:
                                isPremium
                                    ? LinearGradient(
                                      colors: [
                                        Colors.amber.shade300,
                                        Colors.orange.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : null,
                            color:
                                isPremium ? null : cs.surfaceContainerHighest,
                            boxShadow:
                                isPremium
                                    ? [
                                      BoxShadow(
                                        color: Colors.orange.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              child: ClipOval(
                                child:
                                    avatarUrl != null &&
                                            avatarUrl.toString().isNotEmpty
                                        ? Image.network(
                                          avatarUrl.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: cs.onSurfaceVariant,
                                            );
                                          },
                                        )
                                        : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: cs.onSurfaceVariant,
                                        ),
                              ),
                            ),
                          ),
                        ),
                        // Rank Rozeti (Alt Orta) - Sadece popüler veya efsanevi ise renkli, yeni ise düz gri
                        Positioned(
                          bottom: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  isPremium
                                      ? LinearGradient(
                                        colors: [
                                          Colors.amber.shade400,
                                          Colors.orange.shade600,
                                        ],
                                      )
                                      : null,
                              color:
                                  isPremium ? null : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                              boxShadow:
                                  isPremium
                                      ? [
                                        BoxShadow(
                                          color: Colors.orange.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  color:
                                      isPremium
                                          ? Colors.white
                                          : cs.onSurfaceVariant,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rankLevel,
                                  style: TextStyle(
                                    color:
                                        isPremium
                                            ? Colors.white
                                            : cs.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Kamera Butonu (Sağ Alt) - EditProfileScreen'e yönlendiriyor
                        Positioned(
                          bottom: 10,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: cs.primary,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      '$alias$age',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city, // Veritabanından gelen şehir bilgisi
                          style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // İstatistikler (Minimal/Compact Tasarım)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactStat(
                            context,
                            '$xpPoints XP',
                            'Seviye',
                            Icons.emoji_events,
                            Colors.orange,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                          _buildCompactStat(
                            context,
                            '$views',
                            'Ziyaret',
                            Icons.visibility,
                            cs.primary,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                          _buildCompactStat(
                            context,
                            '$likes',
                            'Beğeni',
                            Icons.favorite,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rozetler ve Görevler Bölümü
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rozetler ve Görevler',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const QuestsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Tümünü Gör',
                              style: TextStyle(color: cs.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rozet Listesi (Dinamik Etiketler)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children:
                            allBadgeTypes.map((badgeInfo) {
                              final badgeName = badgeInfo['name'] as String;
                              final isUnlocked = earnedBadges.contains(
                                badgeName,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildCompactBadge(
                                  context,
                                  icon: badgeInfo['icon'] as IconData,
                                  title: badgeName,
                                  color: badgeInfo['color'] as Color,
                                  isUnlocked: isUnlocked,
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Görevler Önizlemesi
                    ref
                        .watch(userQuestsProvider)
                        .when(
                          data: (questsData) {
                            if (questsData == null) {
                              return const SizedBox.shrink();
                            }
                            final dailyQuests =
                                questsData['daily'] as List<dynamic>? ?? [];
                            if (dailyQuests.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Sadece ilk 2 görevi göster
                            final previewQuests = dailyQuests.take(2).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktif Görevler',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...previewQuests.map((q) {
                                  final isCompleted =
                                      q['is_completed'] == true ||
                                      q['is_completed'] == 1;
                                  final progress = q['progress'] ?? 0;
                                  final target = q['target_count'] ?? 1;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                q['title'] ?? 'Görev',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              LinearProgressIndicator(
                                                value: (progress / target)
                                                    .clamp(0.0, 1.0),
                                                backgroundColor: cs
                                                    .outlineVariant
                                                    .withValues(alpha: 0.3),
                                                color:
                                                    isCompleted
                                                        ? Colors.green
                                                        : cs.primary,
                                                minHeight: 4,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '$progress/$target',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isCompleted
                                                    ? Colors.green
                                                    : cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 32),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Kompakt İstatistik Öğesi
  Widget _buildCompactStat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Kompakt Rozet Öğesi (Sadece İkon)
  Widget _buildCompactBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required bool isUnlocked,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: title,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked ? color.withValues(alpha: 0.1) : cs.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isUnlocked
                    ? color.withValues(alpha: 0.3)
                    : cs.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color:
              isUnlocked ? color : cs.onSurfaceVariant.withValues(alpha: 0.5),
          size: 24,
        ),
      ),
    );
  }
}
