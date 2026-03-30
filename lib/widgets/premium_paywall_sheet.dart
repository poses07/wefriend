import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class PremiumPaywallSheet extends ConsumerWidget {
  const PremiumPaywallSheet({super.key});

  void _purchasePremium(
    BuildContext context,
    WidgetRef ref,
    String package,
    int price,
  ) {
    final userAsync = ref.read(userProfileProvider);
    final currentCoins = userAsync.value?['coins'] ?? 0;

    if (currentCoins >= price) {
      Navigator.pop(context);
      // Gerçek senaryoda backend'e istek atılır ve 'is_premium' true yapılır
      CustomSnackBar.show(
        context: context,
        message:
            'Tebrikler! $package VIP üyelik satın alındı 👑 (-$price Jeton)',
        type: NotificationType.success,
      );
      // ref.invalidate(userProfileProvider); // Backend entegrasyonu sonrası profili güncelle
    } else {
      Navigator.pop(context);
      CustomSnackBar.show(
        context: context,
        message: 'Yetersiz bakiye. Lütfen mağazadan jeton satın alın.',
        type: NotificationType.error,
      );
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
        child: SingleChildScrollView(
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

              // Başlık ve İkon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'WeFriend VIP',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sınırları kaldır, gelişmiş özellikleri kullan ve hemen öne çık!',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Mevcut Bakiye
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
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

              // VIP Özellikleri Listesi
              _buildFeatureItem(
                cs,
                Icons.local_fire_department_rounded,
                Colors.orange,
                'Daha Çok Görüntülenme',
                'VIP rozetinle öne çık ve profiline %300 daha fazla ziyaretçi çek.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                cs,
                Icons.filter_alt_rounded,
                Colors.purple,
                'Gelişmiş Filtreleme',
                'Kullanıcıları cinsiyet, yaş ve konuma göre filtrele.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                cs,
                Icons.visibility_rounded,
                Colors.green,
                'Gizli Ziyaretçi',
                'Profilleri ziyaret ederken izinizi belli etmeyin.',
              ),
              const SizedBox(height: 32),

              // VIP Paketleri
              _buildVipOption(
                context,
                ref,
                '1 Aylık VIP',
                1000,
                Colors.amber.shade700,
              ),
              const SizedBox(height: 12),
              _buildVipOption(
                context,
                ref,
                '3 Aylık VIP',
                2500,
                Colors.orange.shade700,
                isPopular: true,
              ),
              const SizedBox(height: 12),
              _buildVipOption(
                context,
                ref,
                '6 Aylık VIP',
                4000,
                Colors.deepOrange.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    ColorScheme cs,
    IconData icon,
    Color color,
    String title,
    String desc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVipOption(
    BuildContext context,
    WidgetRef ref,
    String package,
    int price,
    Color color, {
    bool isPopular = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _purchasePremium(context, ref, package, price),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isPopular ? color.withValues(alpha: 0.1) : cs.surface,
          border: Border.all(
            color:
                isPopular
                    ? color.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.3),
            width: isPopular ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        package,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? color : cs.onSurface,
                        ),
                      ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'POPÜLER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPopular ? color : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$price Jeton',
                style: TextStyle(
                  color: isPopular ? Colors.white : cs.onSurface,
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
