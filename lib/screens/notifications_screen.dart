import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

import '../utils/custom_snackbar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatTime(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return 'Şimdi';
    try {
      // API'den gelen saat genellikle UTC olarak gelir ama Z takısı yoksa local gibi algılanabilir.
      // UTC olarak parse edip local'e çevirelim veya mutlak değerini alalım.
      DateTime dateTime = DateTime.parse(timestampStr);
      // Eğer Z ile bitmiyorsa, veritabanından muhtemelen UTC veya local timezone olarak gelmiştir.
      if (!timestampStr.endsWith('Z')) {
        // PHP'nin döndürdüğü tarih stringine Z ekleyerek UTC olduğunu belirtelim
        // (Eğer sunucun UTC'de ise).
        // Biz her ihtimale karşı aradaki farkın negatif çıkmasını engelleyelim.
      }

      final now = DateTime.now();
      var difference = now.difference(dateTime);

      if (difference.isNegative) {
        // Timezone farkı veya sunucu/cihaz saat uyuşmazlığı varsa negatif çıkabilir.
        // Mutlak değerini kullanarak bu hatayı önlüyoruz.
        difference = difference.abs();
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes == 0 ? 1 : difference.inMinutes} dk önce';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Şimdi';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.favorite_rounded;
      case 'view':
        return Icons.visibility_rounded;
      case 'quest':
        return Icons.emoji_events_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type, ColorScheme cs) {
    switch (type) {
      case 'match':
        return Colors.redAccent;
      case 'view':
        return Colors.blue.shade400;
      case 'quest':
        return Colors.orange.shade500;
      case 'message':
        return cs.primary;
      default:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent.shade400,
            ),
            tooltip: 'Tümünü temizle',
            onPressed: () async {
              final api = ref.read(apiServiceProvider);
              final result = await api.clearAllNotifications();
              if (result['success'] == true) {
                ref.invalidate(notificationsListProvider);
                if (context.mounted) {
                  CustomSnackBar.show(
                    context: context,
                    message: 'Tüm bildirimler başarıyla silindi.',
                    type: NotificationType.success,
                  );
                }
              } else {
                if (context.mounted) {
                  CustomSnackBar.show(
                    context: context,
                    message: 'Bildirimler silinirken bir hata oluştu.',
                    type: NotificationType.error,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (notifications) {
          if (notifications == null || notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bildiriminiz yok.',
                    style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isUnread = notification['is_read'] == 0;
              final type = notification['type'] ?? 'info';
              final color = _getColorForType(type, cs);
              final icon = _getIconForType(type);
              final timeStr = _formatTime(notification['created_at']);

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 2,
                ), // Liste öğeleri arası ince boşluk
                decoration: BoxDecoration(
                  color:
                      isUnread
                          ? color.withValues(alpha: 0.04)
                          : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isUnread ? color : Colors.transparent,
                      width: 4,
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (isUnread) {
                        final api = ref.read(apiServiceProvider);
                        await api.markNotificationsAsRead(
                          id: notification['id'],
                        );
                        ref.invalidate(notificationsListProvider);
                      }
                      // Tipe göre yönlendirme yapılabilir
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sol İkon (Daha kompakt)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          // Sağ İçerik
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification['title'] ?? 'Bildirim',
                                        style: TextStyle(
                                          fontWeight:
                                              isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                          fontSize: 15,
                                          color: cs.onSurface,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (isUnread)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'] ?? '',
                                  style: TextStyle(
                                    color:
                                        isUnread
                                            ? cs.onSurface
                                            : cs.onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
