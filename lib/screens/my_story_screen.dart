import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class MyStoryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> story;
  final bool isMyStory;
  final Map<String, dynamic>? ownerProfile;

  const MyStoryScreen({
    super.key,
    required this.story,
    required this.isMyStory,
    this.ownerProfile,
  });

  @override
  ConsumerState<MyStoryScreen> createState() => _MyStoryScreenState();
}

class _MyStoryScreenState extends ConsumerState<MyStoryScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isMyStory) {
      _recordView();
    }
  }

  Future<void> _recordView() async {
    // Hikaye bana ait değilse görüntüleme kaydet
    final api = ref.read(apiServiceProvider);
    try {
      await api.viewStory(widget.story['id']);
    } catch (e) {
      // sessizce geç
    }
  }

  Future<void> _deleteStory(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hikayeyi Sil'),
            content: const Text(
              'Bu hikayeyi silmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    // Yükleniyor göstergesi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final api = ref.read(apiServiceProvider);
    final result = await api.deleteStory(widget.story['id']);

    if (!context.mounted) return;
    Navigator.pop(context); // Yükleniyor dialogunu kapat

    if (result['success'] == true) {
      CustomSnackBar.show(
        context: context,
        message: 'Hikaye silindi',
        type: NotificationType.success,
      );
      ref.invalidate(storiesProvider);
      ref.invalidate(homeFeedProvider);
      Navigator.pop(context); // Hikaye ekranını kapat
    } else {
      CustomSnackBar.show(
        context: context,
        message: result['message'] ?? 'Hikaye silinemedi',
        type: NotificationType.error,
      );
    }
  }

  void _showBoostStore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const BoostStoreSheet(),
    );
  }

  void _showViewersList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Görüntüleyenler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: ref
                              .read(apiServiceProvider)
                              .getStoryViewers(widget.story['id']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError ||
                                snapshot.data?['success'] != true) {
                              return const Center(
                                child: Text('Görüntüleyenler alınamadı.'),
                              );
                            }

                            final viewers =
                                snapshot.data?['data'] as List<dynamic>? ?? [];
                            if (viewers.isEmpty) {
                              return const Center(
                                child: Text('Henüz görüntüleyen yok.'),
                              );
                            }

                            return ListView.builder(
                              controller: controller,
                              itemCount: viewers.length,
                              itemBuilder: (context, index) {
                                final viewer = viewers[index];
                                final avatarUrl = viewer['avatar_url'];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        avatarUrl != null
                                            ? CachedNetworkImageProvider(
                                              avatarUrl,
                                            )
                                            : null,
                                    child:
                                        avatarUrl == null
                                            ? const Icon(Icons.person)
                                            : null,
                                  ),
                                  title: Text(
                                    viewer['alias'] ?? 'Kullanıcı',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text('Görüntüledi'),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mediaUrl = widget.story['media_url'];
    final viewsCount = widget.story['views_count'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dx = details.globalPosition.dx;
          if (dx < screenWidth / 3) {
            // Sol tarafa tıklandı - Önceki hikaye (Şimdilik kapatıyor)
            Navigator.pop(context);
          } else if (dx > screenWidth * 2 / 3) {
            // Sağ tarafa tıklandı - Sonraki hikaye (Şimdilik kapatıyor)
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // Hikaye Fotoğrafı
            Positioned.fill(
              child: Hero(
                tag:
                    widget.isMyStory
                        ? 'story_me'
                        : 'story_${widget.ownerProfile?['user_id']}',
                child:
                    mediaUrl != null && mediaUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: mediaUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: cs.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.error, size: 50),
                                ),
                              ),
                        )
                        : Container(
                          color: cs.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.image, size: 100),
                          ),
                        ),
              ),
            ),

            // Yazıların okunabilirliği için karartma (Gradient)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Üst Kısım (Progress Bar ve Profil Bilgisi)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    // İlerleme çubuğu (Statik simülasyon)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Profil Bilgisi
                    Row(
                      children: [
                        ref
                            .watch(userProfileProvider)
                            .when(
                              data: (myProfile) {
                                // Eğer kendi hikayemse kendi avatarımı göster, değilse hikaye sahibinin (şimdilik kendi profili)
                                dynamic avatarUrl;
                                if (widget.isMyStory) {
                                  avatarUrl = myProfile?['avatar_url'];
                                } else {
                                  avatarUrl =
                                      widget.ownerProfile?['avatar_url'];
                                }

                                if (avatarUrl != null &&
                                    avatarUrl.toString().isNotEmpty) {
                                  return CircleAvatar(
                                    radius: 18,
                                    backgroundImage: CachedNetworkImageProvider(
                                      avatarUrl.toString(),
                                    ),
                                  );
                                }
                                return const CircleAvatar(
                                  radius: 18,
                                  child: Icon(Icons.person, size: 20),
                                );
                              },
                              loading:
                                  () => const CircleAvatar(
                                    radius: 18,
                                    child: CircularProgressIndicator(),
                                  ),
                              error:
                                  (_, __) => const CircleAvatar(
                                    radius: 18,
                                    child: Icon(Icons.error),
                                  ),
                            ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isMyStory
                                    ? 'Sen'
                                    : (widget.ownerProfile?['alias'] ??
                                        'Kullanıcı'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'Biraz önce',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Kapatma Butonu
                        if (widget.isMyStory)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => _deleteStory(context),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Alt Kısım (Görüntülenme ve Öne Çıkar Butonu)
            if (widget.isMyStory)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Görüntülenme Sayısı
                        GestureDetector(
                          onTap: () => _showViewersList(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$viewsCount Görüntülenme',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Öne Çıkar Butonu (Premium)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showBoostStore(context),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cs.primary, cs.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.rocket_launch_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Öne Çıkar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Öne Çıkar Mağazası (BottomSheet)
class BoostStoreSheet extends ConsumerWidget {
  const BoostStoreSheet({super.key});

  void _purchaseBoost(
    BuildContext context,
    WidgetRef ref,
    String time,
    int price,
  ) {
    final userAsync = ref.read(userProfileProvider);
    final currentCoins = userAsync.value?['coins'] ?? 0;

    if (currentCoins >= price) {
      Navigator.pop(context);
      // Not: Gerçek senaryoda backend'e istek atılıp jeton düşülecek ve öne çıkarma işlemi başlatılacak
      CustomSnackBar.show(
        context: context,
        message:
            'Tebrikler! Hikayen $time boyunca öne çıkarıldı 🚀 (-$price Jeton)',
        type: NotificationType.success,
      );
    } else {
      Navigator.pop(context);
      CustomSnackBar.show(
        context: context,
        message: 'Yetersiz bakiye. Lütfen jeton satın alın.',
        type: NotificationType.error,
      );
      // Opsiyonel: Jeton mağazasına yönlendirebilirsiniz
      // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProfileProvider);
    final currentCoins = userAsync.value?['coins'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sürükleme Çubuğu
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 40,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hikayeni Öne Çıkar',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bölgendeki binlerce kişiye ulaş ve yeni eşleşmeler yakala!',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Mevcut Bakiye
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.generating_tokens_rounded,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mevcut Jeton: $currentCoins',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mağaza Seçenekleri
            _buildBoostOption(
              context,
              ref,
              '5 Dakika',
              100,
              Icons.flash_on_rounded,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildBoostOption(
              context,
              ref,
              '10 Dakika',
              180,
              Icons.local_fire_department_rounded,
              Colors.deepOrange,
            ),
            const SizedBox(height: 12),
            _buildBoostOption(
              context,
              ref,
              '30 Dakika',
              400,
              Icons.whatshot_rounded,
              Colors.redAccent,
            ),
            const SizedBox(height: 12),
            _buildBoostOption(
              context,
              ref,
              '1 Saat',
              700,
              Icons.diamond_rounded,
              Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostOption(
    BuildContext context,
    WidgetRef ref,
    String time,
    int price,
    IconData icon,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _purchaseBoost(context, ref, time, price),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$price Jeton',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
