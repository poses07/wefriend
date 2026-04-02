import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';
import '../widgets/match_overlay.dart';
import '../widgets/heart_explosion_overlay.dart';
import 'chat_detail_screen.dart';
import 'dart:ui';

class UserDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  List<String> get _images {
    final url = widget.user['avatar_url']?.toString();
    if (url != null && url.isNotEmpty) {
      return [url];
    }
    return [
      'https://ui-avatars.com/api/?name=${widget.user['alias'] ?? 'User'}&size=512&background=random&color=fff&bold=true',
    ];
  }

  // Örnek veriler (Şimdilik kullanılmıyor, ileride rozet eklenebilir)
  // final List<String> _tags = [];
  // final List<Map<String, dynamic>> _badges = [];

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text(
                  'Kullanıcıyı Engelle',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text(
                  'Şikayet Et',
                  style: TextStyle(color: Colors.orange),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Emin misiniz?'),
            content: const Text(
              'Bu kullanıcıyı engellemek istediğinize emin misiniz? Bir daha karşınıza çıkmayacak.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Engelle',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final api = ref.read(apiServiceProvider);
    final result = await api.blockUser(
      int.tryParse(widget.user['id']?.toString() ?? '0') ?? 0,
    );

    if (!mounted) return;

    if (result['success']) {
      CustomSnackBar.show(
        context: context,
        message: 'Kullanıcı engellendi.',
        type: NotificationType.success,
      );
      ref.invalidate(homeFeedProvider);
      ref.invalidate(chatsProvider);
      Navigator.pop(context);
    } else {
      CustomSnackBar.show(
        context: context,
        message: result['message'] ?? 'Hata',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _reportUser() async {
    String reason = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Şikayet Nedeni'),
          content: TextField(
            onChanged: (val) => reason = val,
            decoration: const InputDecoration(
              hintText: 'Neden şikayet ediyorsunuz?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );

    if (result != true || reason.isEmpty) return;

    final api = ref.read(apiServiceProvider);
    final res = await api.reportUser(
      int.tryParse(widget.user['id']?.toString() ?? '0') ?? 0,
      reason,
    );

    if (!mounted) return;

    if (res['success']) {
      CustomSnackBar.show(
        context: context,
        message: 'Şikayetiniz alındı.',
        type: NotificationType.success,
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: res['message'] ?? 'Hata',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryImageUrl =
        _images.isNotEmpty
            ? _images.first
            : 'https://ui-avatars.com/api/?name=${widget.user['alias'] ?? 'User'}&size=512&background=random&color=fff&bold=true';

    return Scaffold(
      backgroundColor: Colors.black, // Arka plan tamamen siyah
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Arka Plan Tam Ekran Fotoğraf
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: primaryImageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              errorWidget:
                  (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.user['alias'] ?? 'İsimsiz',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),

          // 2. Alt Kısım Siyah Gradient (Yazıların okunması için)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4), // Üst bar için karartı
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.15, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // 3. Sağ Taraf Aksiyon Butonları (Beğen, Mesaj, Kapat)
          Positioned(
            right: 16,
            bottom: size.height * 0.25, // Ekranın altından biraz yukarıda
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Beğen Butonu
                _buildActionCircle(
                  icon:
                      ref.watch(likedUsersProvider).contains(widget.user['id'])
                          ? CupertinoIcons.heart_solid
                          : CupertinoIcons.heart,
                  color:
                      ref.watch(likedUsersProvider).contains(widget.user['id'])
                          ? Colors.redAccent
                          : Colors.pinkAccent,
                  onTap: () async {
                    if (!ref
                        .read(likedUsersProvider)
                        .contains(widget.user['id'])) {
                      HapticFeedback.lightImpact();
                      ref
                          .read(likedUsersProvider.notifier)
                          .toggleLike(widget.user['id']);

                      final api = ref.read(apiServiceProvider);
                      final result = await api.likeUser(widget.user['id']);

                      if (!context.mounted) return;

                      if (result['success'] == true) {
                        final isMatch =
                            result['data'] != null &&
                            result['data']['is_match'] == true;

                        if (isMatch) {
                          final myProfile = ref.read(userProfileProvider).value;
                          MatchOverlay.show(
                            context,
                            myAvatarUrl: myProfile?['avatar_url'] ?? '',
                            theirAvatarUrl: primaryImageUrl,
                            theirName: widget.user['alias'] ?? 'İsimsiz',
                            onSendMessage: () async {
                              final chatRes = await api.startChat(
                                int.tryParse(
                                      widget.user['id']?.toString() ?? '0',
                                    ) ??
                                    0,
                              );
                              if (context.mounted &&
                                  chatRes['success'] == true) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatDetailScreen(
                                          chatId:
                                              int.tryParse(
                                                chatRes['data']['chat_id']
                                                        ?.toString() ??
                                                    '0',
                                              ) ??
                                              chatRes['chat_id'] ??
                                              0,
                                          otherUserId:
                                              int.tryParse(
                                                widget.user['id']?.toString() ??
                                                    '0',
                                              ) ??
                                              0,
                                          userName:
                                              widget.user['alias'] ?? 'Anonim',
                                          avatarUrl: primaryImageUrl,
                                        ),
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          HeartExplosionOverlay.show(
                            context,
                            isSuperLike: false,
                          );
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Mesaj Gönder Butonu
                _buildActionCircle(
                  icon: CupertinoIcons.chat_bubble_text_fill,
                  color: Colors.white,
                  onTap: () async {
                    final api = ref.read(apiServiceProvider);
                    final res = await api.startChat(
                      int.tryParse(widget.user['id']?.toString() ?? '0') ?? 0,
                    );
                    if (!context.mounted) return;

                    if (res['success']) {
                      final chatId =
                          int.tryParse(
                            res['data']['chat_id']?.toString() ?? '0',
                          ) ??
                          0;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatDetailScreen(
                                chatId: chatId,
                                otherUserId:
                                    int.tryParse(
                                      widget.user['id']?.toString() ?? '0',
                                    ) ??
                                    0,
                                userName: widget.user['alias'] ?? 'İsimsiz',
                                avatarUrl: widget.user['avatar_url'],
                                rankLevel: widget.user['rank_level'],
                                isOnline:
                                    widget.user['is_online'] == 1 ||
                                    widget.user['is_online'] == true ||
                                    widget.user['is_online'] == '1',
                              ),
                        ),
                      );
                    } else {
                      CustomSnackBar.show(
                        context: context,
                        message: res['message'] ?? 'Sohbet başlatılamadı',
                        type: NotificationType.error,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Kapat Butonu (Geri Dön)
                _buildActionCircle(
                  icon: CupertinoIcons.xmark,
                  color: Colors.white,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 4. Alt Kısım Kullanıcı Bilgileri
          Positioned(
            left: 20,
            right: 80, // Aksiyon butonlarıyla çakışmasın diye sağdan boşluk
            bottom: size.height * 0.1, // Alttan biraz boşluk
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // İsim ve Yaş
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        widget.user['alias'] ?? 'İsimsiz',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.user['age'] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                        child: Text(
                          ', ${widget.user['age']}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Konum ve Online Durumu
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.user['city'] ?? 'Gizli Konum',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Online Noktası
                    if (widget.user['is_online'] == 1 ||
                        widget.user['is_online'] == true ||
                        widget.user['is_online'] == '1') ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // İlgi Alanları veya Bio'dan Etiketler (Wrap)
                if (widget.user['interests'] != null &&
                    widget.user['interests'].toString().isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (widget.user['interests'] as String)
                            .split(',')
                            .take(4) // Sadece ilk 4 ilgi alanını göster
                            .map(
                              (interest) => _buildInterestChip(interest.trim()),
                            )
                            .toList(),
                  )
                else if (widget.user['bio'] != null &&
                    widget.user['bio'].toString().isNotEmpty)
                  // Eğer ilgi alanı yoksa ama bio varsa, biyo'yu hafifçe göster
                  Text(
                    widget.user['bio'],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // 5. Üst Menü (Geri Butonu ve Seçenekler)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                // Story/Fotoğraf Progress Çizgileri (Görsel amaçlı eklendi, birden fazla fotoğraf için ileride kullanılabilir)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
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
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildGlassButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showOptions(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestChip(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
