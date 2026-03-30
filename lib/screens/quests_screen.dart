import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Görevler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Günlük'),
            Tab(text: 'Haftalık'),
            Tab(text: 'Aylık'),
          ],
        ),
      ),
      body: ref
          .watch(userQuestsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hata: $err')),
            data: (questsData) {
              if (questsData == null) {
                return const Center(child: Text('Görevler bulunamadı.'));
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestList(context, 'Günlük', questsData['daily'] ?? []),
                  _buildQuestList(
                    context,
                    'Haftalık',
                    questsData['weekly'] ?? [],
                  ),
                  _buildQuestList(
                    context,
                    'Aylık',
                    questsData['monthly'] ?? [],
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildQuestList(
    BuildContext context,
    String type,
    List<dynamic> quests,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Gelecek Ödül / Rozet Bilgisi (Sadece Günlük sekmesinde örnek olarak üstte gösterelim)
        if (type == 'Günlük') ...[
          _buildNextRewardCard(context),
          const SizedBox(height: 24),
          const Text(
            'Görevlerin',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],

        if (quests.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Bu kategori için görev bulunamadı.'),
            ),
          )
        else
          ...quests.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildCompactQuestCard(
                context,
                questId: q['quest_id'] ?? 0,
                title: q['title'] ?? 'Görev',
                description: q['description'] ?? '',
                reward:
                    '${q['reward_xp']} XP / ${q['reward_coins'] ?? 0} Jeton',
                progress: q['progress'] ?? 0,
                target: q['target_count'] ?? 1,
                icon: _getIconData(q['icon_name']),
                color: _parseColor(q['color_hex']),
                isCompleted:
                    q['is_completed'] == true || q['is_completed'] == 1,
              ),
            );
          }),
      ],
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'chat_bubble_rounded':
        return Icons.chat_bubble_rounded;
      case 'camera_alt_rounded':
        return Icons.camera_alt_rounded;
      case 'explore_rounded':
        return Icons.explore_rounded;
      case 'visibility_rounded':
        return Icons.visibility_rounded;
      case 'timer_rounded':
        return Icons.timer_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.blue;
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return Colors.blue;
  }

  Widget _buildNextRewardCard(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final xpPoints = userProfileAsync.value?['xp_points'] ?? 0;
    final rankLevel = userProfileAsync.value?['rank_level'] ?? 'none';

    String nextRank = 'Popüler (Popular)';
    int nextTargetXp = 5000;
    String desc = 'Profilinde ateşli çerçeve ve popülerlik rozeti kazan.';
    IconData iconData = Icons.local_fire_department_rounded;
    List<Color> gradientColors = [
      Colors.orange.shade400,
      Colors.deepOrange.shade700,
    ];

    if (rankLevel == 'popular') {
      nextRank = 'Efsanevi (Legendary)';
      nextTargetXp = 10000;
      desc = 'Profilinde mor elmas çerçeve ve efsanevi ikonu kazan.';
      iconData = Icons.diamond_rounded;
      gradientColors = [Colors.purple.shade400, Colors.deepPurple.shade700];
    } else if (rankLevel == 'legendary') {
      nextRank = 'Maksimum Seviye';
      nextTargetXp = xpPoints; // Tam dolu bar
      desc = 'Zaten en yüksek seviyedesin!';
    }

    final double xpProgress = (xpPoints / nextTargetXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animasyonlu parlayan rozet simülasyonu
              Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(seconds: 2),
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: val,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    },
                    onEnd: () {},
                  ),
                  Icon(iconData, color: Colors.white, size: 32),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sonraki Seviye Rozeti',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextRank,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // XP Barı
          Row(
            children: [
              Text(
                '$xpPoints XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$nextTargetXp XP',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 8,
              backgroundColor: Colors.black.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactQuestCard(
    BuildContext context, {
    required int questId,
    required String title,
    required String description,
    required String reward,
    required int progress,
    required int target,
    required IconData icon,
    required Color color,
    bool isCompleted = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final progressRatio = (progress / target).clamp(0.0, 1.0);
    final canClaim = progress >= target && !isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted ? color.withValues(alpha: 0.05) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCompleted
                  ? color.withValues(alpha: 0.3)
                  : cs.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Sol İkon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              color: isCompleted ? Colors.white : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Orta Metin ve Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isCompleted ? color : cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.generating_tokens_rounded,
                            size: 14,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reward,
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 6,
                          backgroundColor: cs.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            canClaim ? Colors.green : color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${progress > target ? target : progress}/$target',
                      style: TextStyle(
                        color:
                            canClaim
                                ? Colors.green
                                : (isCompleted ? color : cs.onSurfaceVariant),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (canClaim) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                final api = ref.read(apiServiceProvider);
                final res = await api.claimQuestReward(questId);

                if (context.mounted) {
                  if (res['success'] == true) {
                    ref.invalidate(userQuestsProvider);
                    ref.invalidate(userProfileProvider);
                    CustomSnackBar.show(
                      context: context,
                      message: 'Ödül başarıyla alındı!',
                      type: NotificationType.success,
                    );
                  } else {
                    CustomSnackBar.show(
                      context: context,
                      message: res['message'] ?? 'Ödül alınamadı',
                      type: NotificationType.error,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'AL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
