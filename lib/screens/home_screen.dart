import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'my_story_screen.dart';
import 'notifications_screen.dart';
import 'user_detail_screen.dart';
import 'full_screen_camera_screen.dart'; // Eklenen yeni ekran
import '../widgets/premium_avatar.dart';
import '../widgets/premium_paywall_sheet.dart';
import '../providers.dart';
import '../widgets/filter_sheet.dart';
import 'chat_detail_screen.dart';
import '../utils/custom_snackbar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isUploadingStory = false;

  Future<void> _pickStoryImage() async {
    // Tam ekran kamera/galeri seçimine git
    final String? pickedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const FullScreenCameraScreen()),
    );

    if (pickedPath == null) return; // Kullanıcı seçim yapmadan kapattı

    if (!mounted) return;

    setState(() => _isUploadingStory = true);

    final result = await ref
        .read(apiServiceProvider)
        .uploadStory(File(pickedPath));

    if (!mounted) return;
    setState(() => _isUploadingStory = false);

    if (result['success'] == true) {
      CustomSnackBar.show(
        context: context,
        message: 'Hikaye başarıyla paylaşıldı!',
        type: NotificationType.success,
      );

      // Tüm sağlayıcıları temizle ve yenilemeye zorla (Önbellek sıfırlama)
      ref.invalidate(storiesProvider);
      ref.invalidate(homeFeedProvider);

      // Riverpod state'lerinin hemen güncellenmesi için ufak bir bekleme ve okuma
      await Future.delayed(const Duration(milliseconds: 300));
      ref.read(storiesProvider.future);
      ref.read(homeFeedProvider.future);
    } else {
      CustomSnackBar.show(
        context: context,
        message: result['message'] ?? 'Hikaye paylaşılamadı',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feedAsync = ref.watch(homeFeedProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WeFriend',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  // İkonlar (Filtre + Bildirim)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Filtre Butonu (VIP Özelliği)
                      IconButton(
                        icon: Icon(
                          Icons.filter_alt_outlined,
                          color: cs.onSurface,
                        ),
                        onPressed: () {
                          // VIP kontrolü
                          final profile = profileAsync.value;
                          final isPremium =
                              profile != null &&
                              (profile['rank_level'] == 'popular' ||
                                  profile['rank_level'] == 'legendary');

                          if (isPremium) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) {
                                return const FilterSheet();
                              },
                            );
                          } else {
                            // VIP değilse Paywall göster
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const PremiumPaywallSheet(),
                            );
                          }
                        },
                      ),
                      // Bildirimler (Modern İkon)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final notificationsAsync = ref.watch(
                              notificationsListProvider,
                            );
                            int unreadCount = 0;

                            notificationsAsync.whenData((notifications) {
                              if (notifications != null) {
                                unreadCount =
                                    notifications
                                        .where((n) => n['is_read'] == 0)
                                        .length;
                              }
                            });

                            return IconButton(
                              icon: Stack(
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    color: cs.onSurface,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).scaffoldBackgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 12,
                                          minHeight: 12,
                                        ),
                                        child: Text(
                                          unreadCount > 9
                                              ? '9+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const NotificationsScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Hikayeler Bölümü (Premium Gradient Rings)
              SizedBox(
                height: 110,
                child: Consumer(
                  builder: (context, ref, child) {
                    final profileAsync = ref.watch(userProfileProvider);
                    final storiesAsync = ref.watch(storiesProvider);

                    final myProfile = profileAsync.value;
                    final myAvatarUrl = myProfile?['avatar_url'];

                    List<dynamic> allStories = [];
                    if (storiesAsync.hasValue && storiesAsync.value != null) {
                      allStories = List.from(storiesAsync.value!);
                    }

                    // Kendi hikayemi bul
                    Map<String, dynamic>? myStoryGroup;
                    for (var s in allStories) {
                      if (s['is_me'] == true) {
                        myStoryGroup = s;
                        break;
                      }
                    }

                    // Kendi hikayem listede varsa çıkar, başa sabit ekleyeceğiz
                    if (myStoryGroup != null) {
                      allStories.removeWhere((s) => s['is_me'] == true);
                    }

                    final bool hasMyStory =
                        myStoryGroup != null &&
                        myStoryGroup['stories'] != null &&
                        myStoryGroup['stories'].isNotEmpty;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 1 + allStories.length, // 1 for me + others
                      itemBuilder: (context, index) {
                        final isMyStory = index == 0;

                        if (isMyStory) {
                          return GestureDetector(
                            onTap:
                                _isUploadingStory
                                    ? null
                                    : () {
                                      if (hasMyStory) {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) {
                                            final cs =
                                                Theme.of(context).colorScheme;
                                            return Container(
                                              margin: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: cs.surface,
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: Icon(
                                                      Icons.visibility_rounded,
                                                      color: cs.primary,
                                                    ),
                                                    title: const Text(
                                                      'Hikayemi Gör',
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => MyStoryScreen(
                                                                story:
                                                                    myStoryGroup!['stories'][0],
                                                                isMyStory: true,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Divider(
                                                    height: 1,
                                                    color: cs.outlineVariant
                                                        .withValues(alpha: 0.2),
                                                  ),
                                                  ListTile(
                                                    leading: Icon(
                                                      Icons
                                                          .add_circle_outline_rounded,
                                                      color: cs.primary,
                                                    ),
                                                    title: const Text(
                                                      'Yeni Hikaye Ekle',
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _pickStoryImage();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        _pickStoryImage();
                                      }
                                    },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Hero(
                                    tag: 'story_me',
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient:
                                                hasMyStory
                                                    ? LinearGradient(
                                                      colors: [
                                                        cs.primary,
                                                        cs.secondary,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    )
                                                    : null,
                                            color:
                                                hasMyStory
                                                    ? null
                                                    : cs.surfaceContainerHighest,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                            ),
                                            child: ClipOval(
                                              child:
                                                  _isUploadingStory
                                                      ? const SizedBox(
                                                        width: 64,
                                                        height: 64,
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                16.0,
                                                              ),
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      )
                                                      : CachedNetworkImage(
                                                        imageUrl:
                                                            myAvatarUrl !=
                                                                        null &&
                                                                    myAvatarUrl
                                                                        .isNotEmpty
                                                                ? myAvatarUrl
                                                                : 'https://ui-avatars.com/api/?name=${myProfile?['alias'] ?? 'Me'}&size=128&background=random&color=fff&bold=true',
                                                        width: 64,
                                                        height: 64,
                                                        fit: BoxFit.cover,
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => Icon(
                                                              Icons.person,
                                                              size: 64,
                                                              color:
                                                                  cs.onSurfaceVariant,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                        ),
                                        if (!hasMyStory)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: cs.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).scaffoldBackgroundColor,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hikayen',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Diğer kullanıcıların hikayeleri
                        final userStoryGroup = allStories[index - 1];
                        final userAvatarUrl = userStoryGroup['avatar_url'];
                        final userAlias =
                            userStoryGroup['alias'] ?? 'Kullanıcı';
                        final stories =
                            userStoryGroup['stories'] as List<dynamic>? ?? [];

                        if (stories.isEmpty) return const SizedBox();

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => MyStoryScreen(
                                      story: stories[0],
                                      isMyStory: false,
                                      ownerProfile: userStoryGroup,
                                    ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Hero(
                                  tag: 'story_${userStoryGroup['user_id']}',
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [cs.primary, cs.secondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                      ),
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              userAvatarUrl != null &&
                                                      userAvatarUrl.isNotEmpty
                                                  ? userAvatarUrl
                                                  : 'https://ui-avatars.com/api/?name=$userAlias&size=128&background=random&color=fff&bold=true',
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorWidget:
                                              (context, url, error) => Icon(
                                                Icons.person,
                                                size: 64,
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userAlias,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Kullanıcı Listesi
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: feedAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (err, stack) =>
                            Center(child: Text('Bir hata oluştu: $err')),
                    data: (users) {
                      if (users == null || users.isEmpty) {
                        return const Center(child: Text('Henüz kimse yok.'));
                      }

                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          // Küçük çekme çubuğu (Drag handle)
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 24,
                              ),
                              itemCount: users.length,
                              separatorBuilder:
                                  (context, index) => Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.2,
                                    ),
                                    indent: 96,
                                  ),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final alias = user['alias'];
                                final avatarUrl =
                                    user['avatar_url']?.toString();
                                final rankStr = user['rank_level'] ?? 'none';

                                UserRank userRank = UserRank.none;
                                if (rankStr == 'legendary') {
                                  userRank = UserRank.legendary;
                                }
                                if (rankStr == 'popular') {
                                  userRank = UserRank.popular;
                                }

                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                UserDetailScreen(user: user),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    color:
                                        userRank != UserRank.none
                                            ? (userRank == UserRank.legendary
                                                    ? Colors.purple
                                                    : Colors.orange)
                                                .withValues(alpha: 0.03)
                                            : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 14.0,
                                    ),
                                    child: Row(
                                      children: [
                                        // Premium Avatar Kullanımı (Animasyonlu Gradient)
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient:
                                                userRank != UserRank.none
                                                    ? LinearGradient(
                                                      colors:
                                                          userRank ==
                                                                  UserRank
                                                                      .legendary
                                                              ? [
                                                                Colors
                                                                    .purple
                                                                    .shade400,
                                                                Colors
                                                                    .deepPurple
                                                                    .shade700,
                                                                Colors
                                                                    .pinkAccent
                                                                    .shade400,
                                                              ]
                                                              : [
                                                                Colors
                                                                    .amber
                                                                    .shade300,
                                                                Colors
                                                                    .orange
                                                                    .shade500,
                                                                Colors
                                                                    .deepOrange
                                                                    .shade700,
                                                              ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    )
                                                    : null,
                                            boxShadow:
                                                userRank != UserRank.none
                                                    ? [
                                                      BoxShadow(
                                                        color: (userRank ==
                                                                    UserRank
                                                                        .legendary
                                                                ? Colors.purple
                                                                : Colors.orange)
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        blurRadius: 12,
                                                        spreadRadius: 2,
                                                      ),
                                                    ]
                                                    : null,
                                            color:
                                                userRank == UserRank.none
                                                    ? cs.surfaceContainerHighest
                                                    : null,
                                          ),
                                          child: Stack(
                                            children: [
                                              PremiumAvatar(
                                                imageUrl:
                                                    avatarUrl?.toString() ?? '',
                                                size:
                                                    54, // Biraz daha minimal avatar
                                                rank: userRank,
                                                showBadge: false,
                                                fallbackName:
                                                    alias?.toString() ?? 'User',
                                              ),
                                              if (user['is_online'] == 1 ||
                                                  user['is_online'] == true ||
                                                  user['is_online'] == '1')
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            Theme.of(
                                                              context,
                                                            ).scaffoldBackgroundColor,
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Kullanıcı Bilgileri
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            '${alias?.toString() ?? 'İsimsiz'}${user['age'] != null ? ', ${user['age']}' : ''}',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  -0.5,
                                                              color:
                                                                  cs.onSurface,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        if (user['gender'] ==
                                                                'Male' ||
                                                            user['gender'] ==
                                                                'Erkek') ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Icon(
                                                            Icons.male_rounded,
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade400,
                                                            size: 16,
                                                          ),
                                                        ] else if (user['gender'] ==
                                                                'Female' ||
                                                            user['gender'] ==
                                                                'Kadın') ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .female_rounded,
                                                            color:
                                                                Colors
                                                                    .pink
                                                                    .shade400,
                                                            size: 16,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (userRank !=
                                                      UserRank.none) ...[
                                                    PremiumNameBadge(
                                                      rank: userRank,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            userRank ==
                                                                    UserRank
                                                                        .legendary
                                                                ? Colors.purple
                                                                : Colors.orange,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        size: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_rounded,
                                                    size: 14,
                                                    color: cs.primary
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    user['city']?.toString() ??
                                                        'Gizli Konum',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          cs.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (user['bio'] != null &&
                                                  user['bio']
                                                      .toString()
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  user['bio'].toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: cs.onSurfaceVariant
                                                        .withValues(alpha: 0.8),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Şık İkon Buton
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: cs.primary.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: () async {
                                                // Butona tıklandığında yükleniyor göstergesi gösterebiliriz
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (context) => const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                );

                                                final api = ref.read(
                                                  apiServiceProvider,
                                                );
                                                final result = await api.startChat(
                                                  int.tryParse(
                                                        user['id']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0,
                                                );

                                                if (context.mounted) {
                                                  Navigator.pop(
                                                    context,
                                                  ); // Dialogu kapat
                                                }

                                                if (result['success'] == true &&
                                                    context.mounted) {
                                                  await Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => ChatDetailScreen(
                                                            chatId:
                                                                int.tryParse(
                                                                  result['data']['chat_id']
                                                                          ?.toString() ??
                                                                      '0',
                                                                ) ??
                                                                0,
                                                            userName:
                                                                alias
                                                                    ?.toString() ??
                                                                'İsimsiz',
                                                            avatarUrl:
                                                                avatarUrl,
                                                            otherUserId:
                                                                int.tryParse(
                                                                  user['id']
                                                                          ?.toString() ??
                                                                      '0',
                                                                ) ??
                                                                0,
                                                            rankLevel:
                                                                user['rank_level']
                                                                    ?.toString(),
                                                            isOnline:
                                                                user['is_online'] ==
                                                                    1 ||
                                                                user['is_online'] ==
                                                                    true ||
                                                                user['is_online'] ==
                                                                    '1',
                                                          ),
                                                    ),
                                                  );
                                                  // Sohbetten dönüldüğünde sohbet listesini yenile
                                                  ref.invalidate(chatsProvider);
                                                } else if (context.mounted) {
                                                  CustomSnackBar.show(
                                                    context: context,
                                                    message:
                                                        result['message'] ??
                                                        'Sohbet başlatılamadı',
                                                    type:
                                                        NotificationType.error,
                                                  );
                                                }
                                              },
                                              child: const Center(
                                                child: Icon(
                                                  Icons.chat_bubble_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
