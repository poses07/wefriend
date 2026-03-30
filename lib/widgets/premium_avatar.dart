import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum UserRank { none, popular, legendary }

class PremiumAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final UserRank rank;
  final bool showBadge;

  const PremiumAvatar({
    super.key,
    required this.imageUrl,
    this.size = 60.0,
    this.rank = UserRank.none,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    List<Color> frameColors;
    IconData? badgeIcon;
    List<Color>? badgeColors;

    // Rank'e göre renkleri ve ikonları belirle
    switch (rank) {
      case UserRank.popular:
        frameColors = [Colors.amber.shade300, Colors.orange.shade600];
        badgeIcon = Icons.local_fire_department_rounded;
        badgeColors = [Colors.amber.shade400, Colors.orange.shade600];
        break;
      case UserRank.legendary:
        frameColors = [Colors.purple.shade300, Colors.deepPurple.shade600];
        badgeIcon = Icons.diamond_rounded;
        badgeColors = [Colors.purple.shade400, Colors.deepPurple.shade700];
        break;
      case UserRank.none:
        final cs = Theme.of(context).colorScheme;
        frameColors = [
          cs.primary.withValues(alpha: 0.5),
          cs.secondary.withValues(alpha: 0.5),
        ];
        break;
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Dış Çerçeve (Gradient)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: frameColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow:
                rank != UserRank.none
                    ? [
                      BoxShadow(
                        color: frameColors.last.withValues(alpha: 0.4),
                        blurRadius: size * 0.2,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Padding(
            padding: EdgeInsets.all(rank != UserRank.none ? 2.5 : 1.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
                image:
                    imageUrl.isNotEmpty && imageUrl.startsWith('http')
                        ? DecorationImage(
                          image: CachedNetworkImageProvider(imageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  imageUrl.isEmpty || !imageUrl.startsWith('http')
                      ? Icon(Icons.person, size: size * 0.5, color: Colors.grey)
                      : null,
            ),
          ),
        ),

        // Rozet İkonu
        if (showBadge &&
            rank != UserRank.none &&
            badgeIcon != null &&
            badgeColors != null)
          Positioned(
            bottom: -(size * 0.08),
            child: Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: badgeColors),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: size * 0.03,
                ),
              ),
              child: Icon(badgeIcon, color: Colors.white, size: size * 0.25),
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
