import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

import '../widgets/premium_paywall_sheet.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final List<Map<String, dynamic>> _coinPackages = [
    {'id': 'coins_100', 'coins': 100, 'price': '19.99 ₺', 'bonus': null},
    {'id': 'coins_500', 'coins': 500, 'price': '89.99 ₺', 'bonus': '%10 Bonus'},
    {
      'id': 'coins_1000',
      'coins': 1000,
      'price': '159.99 ₺',
      'bonus': '%20 Bonus',
    },
    {
      'id': 'coins_5000',
      'coins': 5000,
      'price': '699.99 ₺',
      'bonus': 'En İyi Fiyat',
    },
  ];

  bool _isProcessing = false;

  void _purchaseCoins(String packageId, int coins) async {
    setState(() => _isProcessing = true);

    // Simüle edilmiş satın alma gecikmesi (Gerçek uygulamada in_app_purchase burada çağrılır)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Not: Gerçek satın alma başarılı olduktan sonra backend'e istek atılıp bakiye güncellenmelidir.
    // Şimdilik sadece UI animasyonu gösteriyoruz.

    setState(() => _isProcessing = false);

    CustomSnackBar.show(
      context: context,
      message: 'Satın alma başarılı! $coins jeton eklendi. (Simülasyon)',
      type: NotificationType.success,
    );

    ref.invalidate(userProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mağaza',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(userProfileProvider);
              final coins = userAsync.value?['coins'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.generating_tokens_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // VIP Banner
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const PremiumPaywallSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VIP Üye Ol',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sınırsız mesaj, filtreler ve daha fazlası!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Jeton Paketleri',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Jeton Paketleri Listesi
              ..._coinPackages.map(
                (pkg) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMinimalCoinPackage(cs, pkg),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimalCoinPackage(ColorScheme cs, Map<String, dynamic> pkg) {
    final bool hasBonus = pkg['bonus'] != null;

    return GestureDetector(
      onTap: () => _purchaseCoins(pkg['id'], pkg['coins']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                hasBonus
                    ? cs.primary.withValues(alpha: 0.3)
                    : cs.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            if (hasBonus)
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    hasBonus
                        ? cs.primary.withValues(alpha: 0.1)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.generating_tokens_rounded,
                size: 28,
                color: hasBonus ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),

            // Jeton Miktarı ve Bonus
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${pkg['coins']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Jeton',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (hasBonus) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pkg['bonus'],
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Fiyat Butonu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    hasBonus
                        ? cs.primary
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pkg['price'],
                style: TextStyle(
                  color: hasBonus ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
