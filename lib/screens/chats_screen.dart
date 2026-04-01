import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'chat_detail_screen.dart';
import '../widgets/premium_avatar.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  String _formatTime(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return 'Şimdi';
    try {
      final dateTime = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0 && now.day == dateTime.day) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        return weekdays[dateTime.weekday - 1];
      } else {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Şimdi';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final chatsAsync = ref.watch(chatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sayfa Başlığı
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                'Mesajlar',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),

            // Arama Çubuğu (Premium Görünüm)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Mesajlarda ara...',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    prefixIcon: Icon(Icons.search, color: cs.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Colors
                            .transparent, // Arka plan rengini Container'dan alıyor
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Sohbet Listesi
            Expanded(
              child: chatsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Hata: $err')),
                data: (chats) {
                  if (chats == null || chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 80,
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz mesajın yok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keşfet sekmesinden yeni insanlarla\ntanışmaya başla!',
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

                  return ListView.builder(
                    itemCount: chats.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final hasUnread =
                          (chat['is_new'] == true) ||
                          (chat['unread_count'] != null &&
                              chat['unread_count'] > 0);
                      final unreadCount = chat['unread_count'] ?? 0;
                      final timeText = _formatTime(chat['last_message_at']);

                      final rankStr = chat['rank_level'] ?? 'none';
                      UserRank rank = UserRank.none;
                      if (rankStr == 'legendary') rank = UserRank.legendary;
                      if (rankStr == 'popular') rank = UserRank.popular;

                      final avatarUrl = chat['avatar_url'];

                      return Slidable(
                        key: ValueKey(chat['chat_id']),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) async {
                                // Burada sohbeti silme veya gizleme API isteği yapılacak
                                // Şimdilik sadece listeden kaldırıp uyarı veriyoruz
                                final api = ref.read(apiServiceProvider);
                                final result = await api.deleteChat(
                                  int.parse(chat['chat_id'].toString()),
                                );

                                if (result['success']) {
                                  ref.invalidate(chatsProvider);
                                  if (context.mounted) {
                                    CustomSnackBar.show(
                                      context: context,
                                      message: 'Sohbet silindi',
                                      type: NotificationType.success,
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    CustomSnackBar.show(
                                      context: context,
                                      message: 'Sohbet silinemedi',
                                      type: NotificationType.error,
                                    );
                                  }
                                }
                              },
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outline_rounded,
                              label: 'Sil',
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => ChatDetailScreen(
                                      chatId:
                                          int.tryParse(
                                            chat['chat_id']?.toString() ?? '0',
                                          ) ??
                                          0,
                                      otherUserId:
                                          int.tryParse(
                                            chat['other_user_id']?.toString() ??
                                                '0',
                                          ) ??
                                          0,
                                      userName:
                                          chat['display_name'] ?? 'İsimsiz',
                                      avatarUrl: avatarUrl,
                                    ),
                              ),
                            );
                            // Detay ekranından dönüldüğünde sohbet listesini güncelle
                            ref.invalidate(chatsProvider);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                // Avatar ve Online Durumu
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    PremiumAvatar(
                                      imageUrl: avatarUrl?.toString() ?? '',
                                      size: 56,
                                      rank: rank,
                                      showBadge: false,
                                      fallbackName: chat['display_name']?.toString() ?? 'User',
                                    ),
                                    if (chat['is_online'] == 1 ||
                                        chat['is_online'] ==
                                            true) // Gerçek çevrimiçi durumu
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.shade400,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                              width: 2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),

                                // İsim ve Son Mesaj
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              chat['display_name'] ?? 'İsimsiz',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    hasUnread
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                color: cs.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          PremiumNameBadge(rank: rank),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        chat['last_message'] ??
                                            'Sohbet başladı',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              hasUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                          color:
                                              hasUnread
                                                  ? cs.onSurface
                                                  : cs.onSurface.withValues(
                                                    alpha: 0.5,
                                                  ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Saat ve Okunmamış Rozeti
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      timeText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            hasUnread
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                        color:
                                            hasUnread
                                                ? cs.primary
                                                : cs.onSurface.withValues(
                                                  alpha: 0.4,
                                                ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (hasUnread)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [cs.primary, cs.secondary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount > 0
                                              ? '$unreadCount'
                                              : 'Yeni',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
