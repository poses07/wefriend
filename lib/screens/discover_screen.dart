import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:async'; // Timer için
import '../widgets/premium_paywall_sheet.dart';
import '../widgets/premium_avatar.dart';
import '../widgets/filter_sheet.dart';
import 'venue_detail_screen.dart';
import '../services/venue_service.dart';
import 'user_detail_screen.dart';
import '../providers.dart';
import 'chat_detail_screen.dart';
import '../utils/custom_snackbar.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final VenueService _venueService = VenueService();
  late Future<List<Map<String, dynamic>>> _venuesFuture;
  late TabController _tabController;
  bool _isVenuesTabActive = false;

  @override
  void initState() {
    super.initState();
    _venuesFuture = _venueService.getActiveVenues();
    _tabController = TabController(length: 2, vsync: this);

    // Tab değişimlerini dinle ve FAB için ekranı güncelle
    _tabController.animation?.addListener(() {
      final isVenuesTab = _tabController.animation!.value > 0.5;
      if (_isVenuesTabActive != isVenuesTab) {
        setState(() {
          _isVenuesTabActive = isVenuesTab;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getIconForType(String? type, String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('cafe') ||
        lowerName.contains('kahve') ||
        lowerName.contains('starbucks')) {
      return Icons.local_cafe_rounded;
    } else if (lowerName.contains('bar') || lowerName.contains('pub')) {
      return Icons.sports_bar_rounded;
    } else if (lowerName.contains('park') || lowerName.contains('bahçe')) {
      return Icons.park_rounded;
    } else if (lowerName.contains('avm') || lowerName.contains('mall')) {
      return Icons.shopping_bag_rounded;
    } else if (lowerName.contains('kütüphane')) {
      return Icons.menu_book_rounded;
    } else if (lowerName.contains('restoran') || lowerName.contains('yemek')) {
      return Icons.restaurant_rounded;
    }
    return Icons.place_rounded;
  }

  Color _getColorForType(String? type, String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('cafe') ||
        lowerName.contains('kahve') ||
        lowerName.contains('starbucks')) {
      return Colors.brown;
    } else if (lowerName.contains('bar') || lowerName.contains('pub')) {
      return Colors.orange;
    } else if (lowerName.contains('park') || lowerName.contains('bahçe')) {
      return Colors.green;
    } else if (lowerName.contains('avm') || lowerName.contains('mall')) {
      return Colors.blue;
    } else if (lowerName.contains('kütüphane')) {
      return Colors.teal;
    } else if (lowerName.contains('restoran') || lowerName.contains('yemek')) {
      return Colors.redAccent;
    }

    // Rastgele renk ataması (ismine göre tutarlı)
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blueGrey,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[name.length % colors.length];
  }

  void _showFilterBottomSheet(BuildContext context) {
    final profile = ref.read(userProfileProvider).value;
    final isPremium =
        profile != null &&
        (profile['rank_level'] == 'popular' ||
            profile['rank_level'] == 'legendary');

    if (!isPremium) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PremiumPaywallSheet(),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const FilterSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVenuesTabActive =
        _tabController.index == 1; // 1. indeks 'Mekanlar' sekmesi

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          isVenuesTabActive
              ? FloatingActionButton.extended(
                onPressed: () => _showCheckInBottomSheet(context),
                icon: const Icon(Icons.pin_drop_rounded, color: Colors.white),
                label: const Text(
                  'Check-in Yap',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: cs.primary,
                elevation: 4,
              )
              : null, // Kullanıcılar sekmesinde FAB gösterilmez
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern TabBar ve Filtreleme Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: cs.primary,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Kullanıcılar'),
                            Tab(text: 'Mekanlar'),
                          ],
                        ),
                      ),
                    ),
                    if (!isVenuesTabActive) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _showFilterBottomSheet(context),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Filtrele',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // TabBar İçerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Sekme: Kullanıcılar Grid'i
                    _buildUsersGrid(cs),
                    // 2. Sekme: Mekanlar Listesi
                    _buildVenuesList(cs),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersGrid(ColorScheme cs) {
    final feedAsync = ref.watch(homeFeedProvider);

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
      data: (users) {
        if (users == null || users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 80,
                  color: cs.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Buralar çok sessiz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Filtreleri değiştirerek\nfarklı kişileri bulmayı dene.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final rankStr = user['rank_level'] ?? 'none';
            UserRank rank = UserRank.none;
            if (rankStr == 'legendary') rank = UserRank.legendary;
            if (rankStr == 'popular') rank = UserRank.popular;

            Color? glowColor;
            if (rank == UserRank.legendary) {
              glowColor = Colors.purple.shade400;
            }
            if (rank == UserRank.popular) {
              glowColor = Colors.orange.shade500;
            }

            final avatarUrl = user['avatar_url']?.toString();
            final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDetailScreen(user: user),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      glowColor != null
                          ? Border.all(
                            color: glowColor.withValues(alpha: 0.5),
                            width: 2,
                          )
                          : null,
                  image:
                      hasAvatar
                          ? DecorationImage(
                            image: CachedNetworkImageProvider(avatarUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color:
                          glowColor != null
                              ? glowColor.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                      blurRadius: glowColor != null ? 16 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (!hasAvatar)
                      Center(
                        child: Icon(
                          Icons.person,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user['alias'] ?? 'İsimsiz',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PremiumNameBadge(rank: rank),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user['city'] ?? 'Bilinmiyor'} • ${user['age'] ?? '?'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildGlassButton(
                                  icon: Icons.chat_bubble_rounded,
                                  color: Colors.blue,
                                  onTap: () async {
                                    // 1. Önce API'ye istek atıp chat_id alalım
                                    final api = ref.read(apiServiceProvider);
                                    final result = await api.startChat(
                                      user['id'],
                                    );

                                    if (!context.mounted) return;

                                    if (result['success'] == true) {
                                      final int newChatId = result['chat_id'];

                                      // 2. Alınan gerçek chat_id ile ChatDetailScreen'e gidelim
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ChatDetailScreen(
                                                chatId: newChatId,
                                                otherUserId: user['id'],
                                                userName:
                                                    user['alias'] ?? 'Anonim',
                                                avatarUrl: avatarUrl ?? '',
                                              ),
                                        ),
                                      );
                                    } else {
                                      CustomSnackBar.show(
                                        context: context,
                                        message:
                                            result['message'] ??
                                            'Sohbet başlatılamadı',
                                        type: NotificationType.error,
                                      );
                                    }
                                  },
                                ),
                                _buildGlassButton(
                                  icon:
                                      ref
                                              .watch(likedUsersProvider)
                                              .contains(user['id'])
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                  color:
                                      ref
                                              .watch(likedUsersProvider)
                                              .contains(user['id'])
                                          ? Colors.red
                                          : Colors.redAccent,
                                  onTap: () {
                                    if (!ref
                                        .read(likedUsersProvider)
                                        .contains(user['id'])) {
                                      ref
                                          .read(likedUsersProvider.notifier)
                                          .toggleLike(user['id']);
                                      // Backend'e beğeni isteği atılabilir (ref.read(apiServiceProvider).likeUser(user['id']))
                                      CustomSnackBar.show(
                                        context: context,
                                        message:
                                            '${user['alias'] ?? 'Kullanıcı'} beğenildi!',
                                        type: NotificationType.success,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVenuesList(ColorScheme cs) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _venuesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Mekanlar bulunamadı',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          );
        }

        final places = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            final fsqId = place['fsq_id'] as String?;

            final displayPlace = {
              ...place,
              'count': place['wefriend_checkin_count'],
              'icon': _getIconForType(
                place['type'] as String?,
                place['name'] as String,
              ),
              'color': _getColorForType(
                place['type'] as String?,
                place['name'] as String,
              ),
            };

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => VenueDetailScreen(venue: displayPlace),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Mekan İkonu veya Fotoğrafı
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (displayPlace['color'] as Color).withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child:
                          fsqId != null && fsqId != 'custom'
                              ? FutureBuilder<List<String>>(
                                future: _venueService.getVenuePhotos(fsqId),
                                builder: (context, photoSnapshot) {
                                  if (photoSnapshot.hasData &&
                                      photoSnapshot.data!.isNotEmpty) {
                                    return Image.network(
                                      photoSnapshot.data!.first,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            displayPlace['icon'] as IconData,
                                            size: 28,
                                            color:
                                                displayPlace['color'] as Color,
                                          ),
                                    );
                                  }
                                  return Icon(
                                    displayPlace['icon'] as IconData,
                                    size: 28,
                                    color: displayPlace['color'] as Color,
                                  );
                                },
                              )
                              : Icon(
                                displayPlace['icon'] as IconData,
                                size: 28,
                                color: displayPlace['color'] as Color,
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayPlace['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 14,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Aktif Kullanıcılar',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${displayPlace['count']}',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Kişi',
                            style: TextStyle(
                              color: cs.primary.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  void _showCheckInBottomSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final TextEditingController venueController = TextEditingController();
    String? selectedFsqId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tutamaç (Handle)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'Şu an neredesin?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Otomatik tamamlama için Autocomplete Widget'ı
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Autocomplete<Map<String, dynamic>>(
                          optionsBuilder: (
                            TextEditingValue textEditingValue,
                          ) async {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<
                                Map<String, dynamic>
                              >.empty();
                            }

                            // Önce veritabanındaki aktif mekanlarda ara
                            List<Map<String, dynamic>> localResults = [];
                            try {
                              final venues =
                                  await _venueService.getActiveVenues();
                              localResults =
                                  venues.where((v) {
                                    final name =
                                        (v['name'] as String).toLowerCase();
                                    return name.contains(
                                      textEditingValue.text.toLowerCase(),
                                    );
                                  }).toList();
                            } catch (_) {}

                            // Sonra Foursquare'den çek (Eğer yerelde az sonuç varsa)
                            if (localResults.length < 3) {
                              try {
                                final fsqResults = await _venueService
                                    .searchFoursquareVenues(
                                      textEditingValue.text,
                                    );

                                // Yerel sonuçlarla Foursquare sonuçlarını birleştir (isim çakışmalarını önle)
                                final localNames =
                                    localResults.map((e) => e['name']).toSet();
                                final newFsqResults = fsqResults.where(
                                  (f) => !localNames.contains(f['name']),
                                );

                                localResults.addAll(newFsqResults);
                              } catch (_) {}
                            }

                            return localResults;
                          },
                          displayStringForOption:
                              (option) => option['name'] as String,
                          onSelected: (Map<String, dynamic> selection) {
                            venueController.text = selection['name'] as String;
                            if (selection.containsKey('fsq_id')) {
                              selectedFsqId = selection['fsq_id'] as String;
                            }
                          },
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onEditingComplete,
                          ) {
                            controller.addListener(() {
                              if (venueController.text != controller.text) {
                                venueController.text = controller.text;
                              }
                            });

                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onEditingComplete: onEditingComplete,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: 'Mekan adı girin (Örn: Çöplük Bar)',
                                hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.place_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              // Klavye otomatik düzeltmelerini kapatmak ve serbest metin girmeye zorlamak için
                              enableSuggestions: false,
                              autocorrect: false,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 8.0,
                                borderRadius: BorderRadius.circular(16),
                                color: cs.surfaceContainerHighest,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth: 320,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (
                                      BuildContext context,
                                      int index,
                                    ) {
                                      final option = options.elementAt(index);
                                      final bool isFromFoursquare = option
                                          .containsKey('fsq_id');

                                      return InkWell(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isFromFoursquare
                                                          ? Colors.blue
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                          : cs.primary
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isFromFoursquare
                                                      ? Icons
                                                          .location_city_rounded
                                                      : Icons.history_rounded,
                                                  size: 16,
                                                  color:
                                                      isFromFoursquare
                                                          ? Colors.blue
                                                          : cs.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      option['name'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (isFromFoursquare &&
                                                        option['address'] !=
                                                            null)
                                                      Text(
                                                        option['address'],
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              cs.onSurfaceVariant,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (isFromFoursquare &&
                                                  option['distance'] != null)
                                                Text(
                                                  '${(option['distance'] as int)}m',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final name = venueController.text.trim();
                            if (name.isEmpty) return;

                            Navigator.pop(context); // Dialogu kapat

                            if (!context.mounted) return;

                            final result = await _venueService.checkIn(
                              name,
                              fsqId: selectedFsqId,
                            );
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor:
                                    result['success']
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            );
                            if (result['success']) {
                              setState(() {
                                _venuesFuture = _venueService.getActiveVenues();
                              });
                            }
                          },
                          child: const Text(
                            'Check-in Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
