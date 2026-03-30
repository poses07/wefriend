import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';
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
      'https://ui-avatars.com/api/?name=${widget.user['alias'] ?? 'User'}&size=512&background=random',
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
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final primaryImageUrl =
        _images.isNotEmpty
            ? _images.first
            : 'https://ui-avatars.com/api/?name=${widget.user['alias'] ?? 'User'}&size=512&background=random';

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
                  (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.white),
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
                    Colors.black.withValues(
                      alpha: 0.3,
                    ), // Üstte hafif karartma (geri butonu için)
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.15, 0.4, 0.65, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // 3. İçerik (Kaydırılabilir alan)
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Üst boşluk
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: size.height * 0.45,
                  ), // Fotoğrafın üst kısmını boş bırakır
                ),

                // Bilgiler
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // İsim, Yaş, Cinsiyet
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${widget.user['alias'] ?? 'İsimsiz'}${widget.user['age'] != null ? ', ${widget.user['age']}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                if (widget.user['gender'] == 'Male' ||
                                    widget.user['gender'] == 'Erkek') ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.male_rounded,
                                    color: Colors.lightBlueAccent,
                                    size: 32,
                                  ),
                                ] else if (widget.user['gender'] == 'Female' ||
                                    widget.user['gender'] == 'Kadın') ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.female_rounded,
                                    color: Colors.pinkAccent,
                                    size: 32,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Online Göstergesi
                          if (widget.user['is_online'] == 1 ||
                              widget.user['is_online'] == true)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.circle,
                                color: Colors.greenAccent,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Konum
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.user['city'] ?? 'Bilinmeyen Konum'} • Yakınlarda',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Fiziksel Özellikler (Chip'ler)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.user['height'] != null)
                            _buildGlassChip(
                              Icons.height,
                              '${widget.user['height']} cm',
                            ),
                          if (widget.user['weight'] != null)
                            _buildGlassChip(
                              Icons.monitor_weight_outlined,
                              '${widget.user['weight']} kg',
                            ),
                          if (widget.user['zodiac_sign'] != null &&
                              widget.user['zodiac_sign'].toString().isNotEmpty)
                            _buildGlassChip(
                              Icons.auto_awesome,
                              widget.user['zodiac_sign'],
                            ),
                        ],
                      ),

                      // İlgi Alanları
                      if (widget.user['interests'] != null &&
                          widget.user['interests'].toString().isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'İlgi Alanları',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              widget.user['interests']
                                  .toString()
                                  .split(',')
                                  .map((interest) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: cs.primary.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        interest.trim(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                        ),
                      ],

                      // Hakkında (Bio)
                      if (widget.user['bio'] != null &&
                          widget.user['bio'].toString().isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'Hakkında',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.user['bio'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],

                      // En altta butonlar için boşluk
                      const SizedBox(height: 140),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // 4. Üst Menü (Geri Butonu ve Seçenekler)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _buildGlassButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showOptions(context),
                ),
              ],
            ),
          ),

          // 5. Sabit Alt Butonlar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final api = ref.read(apiServiceProvider);
                    final res = await api.startChat(
                      int.tryParse(widget.user['id']?.toString() ?? '0') ?? 0,
                    );
                    if (!context.mounted) return;

                    if (res['success']) {
                      final chatId = res['data']['chat_id'];
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
                                    widget.user['is_online'] == true,
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shadowColor: cs.primary.withValues(alpha: 0.5),
                    elevation: 10,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip(IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
