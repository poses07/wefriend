import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/premium_avatar.dart';
import '../services/venue_service.dart';
import 'user_detail_screen.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> venue;

  const VenueDetailScreen({super.key, required this.venue});

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  final VenueService _venueService = VenueService();
  late Future<List<Map<String, dynamic>>> _venueUsersFuture;

  @override
  void initState() {
    super.initState();
    _venueUsersFuture = _venueService.getVenueUsers(widget.venue['name']);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int checkinCount =
        int.tryParse(widget.venue['count']?.toString() ?? '0') ?? 0;
    final fsqId = widget.venue['fsq_id'] as String?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Mekan Kapak Fotoğrafı ve Başlık
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.venue['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Arka plan: Foursquare fotoğrafı veya varsayılan renk
                  if (fsqId != null && fsqId != 'custom')
                    FutureBuilder<List<String>>(
                      future: _venueService.getVenuePhotos(fsqId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Image.network(
                            snapshot.data!.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: cs.primary),
                          );
                        }
                        return Container(color: (widget.venue['color'] as Color?) ?? cs.primary);
                      },
                    )
                  else
                    Container(
                      color: (widget.venue['color'] as Color?) ?? cs.primary,
                      child: Center(
                        child: Icon(
                          widget.venue['icon'] as IconData?,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  // Karanlık Gradient Overlay (Yazının okunması için)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check-in Butonu ve Bilgi
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (widget.venue['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.venue['icon'] as IconData,
                            color: widget.venue['color'] as Color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Şu an $checkinCount kişi burada',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check-in yap ve yerel sohbete katıl!',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Büyük Check-in Butonu
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final result = await _venueService.checkIn(
                            widget.venue['name'] as String,
                          );
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor:
                                  result['success'] ? Colors.green : Colors.red,
                            ),
                          );
                          if (result['success']) {
                            setState(() {
                              _venueUsersFuture = _venueService.getVenueUsers(
                                widget.venue['name'],
                              );
                            });
                          }
                        },
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Buradayım (Check-in)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Mekandaki Kullanıcılar Listesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İçeridekiler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Local Sohbeti Aç',
                          style: TextStyle(color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kullanıcı Grid'i
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _venueUsersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Şu an burada kimse yok.'),
                        );
                      }

                      final displayUsers = snapshot.data!;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: displayUsers.length,
                        itemBuilder: (context, index) {
                          final user = displayUsers[index];
                          final rankStr = user['rank_level'] ?? 'none';
                          UserRank rank = UserRank.none;
                          if (rankStr == 'legendary') rank = UserRank.legendary;
                          if (rankStr == 'popular') rank = UserRank.popular;

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => UserDetailScreen(user: user),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                PremiumAvatar(
                                  imageUrl:
                                      user['avatar_url']?.toString() ?? '',
                                  size: 70,
                                  rank: rank,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user['alias'] ?? 'İsimsiz',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    PremiumNameBadge(rank: rank, size: 10),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
