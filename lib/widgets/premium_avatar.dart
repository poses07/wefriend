import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

enum UserRank { none, popular, legendary }

class PremiumAvatar extends StatefulWidget {
  final String imageUrl;
  final double size;
  final UserRank rank;
  final bool showBadge;
  final String fallbackName;

  const PremiumAvatar({
    super.key,
    required this.imageUrl,
    this.size = 60.0,
    this.rank = UserRank.none,
    this.showBadge = true,
    this.fallbackName = 'User',
  });

  @override
  State<PremiumAvatar> createState() => _PremiumAvatarState();
}

class _PremiumAvatarState extends State<PremiumAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Color> frameColors;
    IconData? badgeIcon;
    List<Color>? badgeColors;

    // 2026 Trendi: Yüksek kontrastlı neon gradientler ve animasyonlar
    switch (widget.rank) {
      case UserRank.popular:
        frameColors = [
          const Color(0xFFFFD700), // Altın Sarısı
          const Color(0xFFFF8C00), // Koyu Turuncu
          const Color(0xFFFF3D00), // Ateş Kırmızısı
          const Color(0xFFFFD700), // Döngü için tekrar Altın Sarısı
        ];
        badgeIcon = Icons.local_fire_department_rounded;
        badgeColors = [const Color(0xFFFF8C00), const Color(0xFFFF3D00)];
        break;
      case UserRank.legendary:
        frameColors = [
          const Color(0xFF00E5FF), // Neon Mavi
          const Color(0xFFD500F9), // Neon Mor
          const Color(0xFFFF1744), // Neon Pembe/Kırmızı
          const Color(0xFF00E5FF), // Döngü için tekrar Neon Mavi
        ];
        badgeIcon = Icons.diamond_rounded;
        badgeColors = [const Color(0xFFD500F9), const Color(0xFFFF1744)];
        break;
      case UserRank.none:
        final cs = Theme.of(context).colorScheme;
        frameColors = [
          cs.outlineVariant.withValues(alpha: 0.3),
          cs.outlineVariant.withValues(alpha: 0.3),
        ];
        break;
    }

    final bool isPremium = widget.rank != UserRank.none;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Dış Çerçeve (Animasyonlu Gradient)
        if (isPremium)
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: widget.size + 6, // Dışa taşan aura payı
                  height: widget.size + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: frameColors,
                      stops: const [0.0, 0.33, 0.66, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColors!.first.withValues(alpha: 0.6),
                        blurRadius: widget.size * 0.3,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Profil Fotoğrafı ve İç Çerçeve
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
            border: isPremium ? Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 3,
            ) : null,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl.isNotEmpty && widget.imageUrl.startsWith('http')
                  ? widget.imageUrl
                  : 'https://ui-avatars.com/api/?name=${widget.fallbackName}&size=${(widget.size * 2).toInt()}&background=random&color=fff&bold=true',
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.person,
                size: widget.size * 0.5,
                color: Colors.grey,
              ),
            ),
          ),
        ),

        // Rozet İkonu (3D efektli)
        if (widget.showBadge && isPremium && badgeIcon != null && badgeColors != null)
          Positioned(
            bottom: -(widget.size * 0.05),
            child: Container(
              padding: EdgeInsets.all(widget.size * 0.08),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: badgeColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColors.last.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                badgeIcon, 
                color: Colors.white, 
                size: widget.size * 0.25,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// İsimlerin yanına eklenecek minimal rozet ikonu
class PremiumNameBadge extends StatelessWidget {
  final UserRank rank;
  final double size;

  const PremiumNameBadge({super.key, required this.rank, this.size = 14.0});

  @override
  Widget build(BuildContext context) {
    if (rank == UserRank.none) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (rank) {
      case UserRank.popular:
        icon = Icons.local_fire_department_rounded;
        color = Colors.orange.shade500;
        break;
      case UserRank.legendary:
        icon = Icons.diamond_rounded;
        color = Colors.purple.shade400;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Icon(icon, size: size, color: color),
    );
  }
}
