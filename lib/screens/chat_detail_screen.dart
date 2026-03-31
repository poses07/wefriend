import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';
import '../widgets/premium_avatar.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int chatId;
  final int otherUserId;
  final String userName;
  final String? avatarUrl;
  final String? rankLevel;
  final bool? isOnline;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.userName,
    this.avatarUrl,
    this.rankLevel,
    this.isOnline,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  final int _limit = 50;

  int? _myUserId;
  final ImagePicker _picker = ImagePicker();

  // Hangi resimlerin bluru kaldırıldı (ID veya index bazlı tutabiliriz)
  // Şimdilik URL bazlı tutuyoruz
  final Set<String> _unblurredImages = {};

  @override
  void initState() {
    super.initState();
    _initChat();

    _scrollController.addListener(() {
      // En üste (eski mesajlara) kaydırıldığında ve daha fazla mesaj varsa yükle
      if (_scrollController.position.pixels ==
              _scrollController.position.minScrollExtent &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreMessages();
      }
    });
  }

  void _startPolling() {
    // Her 3 saniyede bir yeni mesaj var mı diye kontrol et (Polling)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _pollNewMessages();
    });
  }

  Future<void> _pollNewMessages() async {
    if (!mounted) return;
    final api = ref.read(apiServiceProvider);

    try {
      // Sadece en son gelen 10 mesajı çekerek polling maliyetini düşürüyoruz
      final result = await api.getMessages(widget.chatId, offset: 0, limit: 10);

      if (result['success'] == true && mounted) {
        final List<Map<String, dynamic>> fetchedMessages =
            List<Map<String, dynamic>>.from(result['data']);

        // Eğer yeni mesaj varsa (mevcut listede olmayan mesaj)
        bool isNewMessageAdded = false;
        for (var newMsg in fetchedMessages.reversed) {
          // Basit bir kontrol: Bu mesaj zaten _messages içinde var mı? (Gerçekte ID ile kontrol edilmeli, şimdilik text ve zaman kontrolü)
          // Not: API'den gelen veride 'id' alanı da varsa ona göre kontrol etmek daha sağlam olur.
          final exists = _messages.any(
            (m) =>
                m['text'] == newMsg['text'] &&
                m['time'] == newMsg['time'] &&
                m['isMe'] == newMsg['isMe'],
          );

          if (!exists) {
            _messages.add(newMsg);
            isNewMessageAdded = true;
          }
        }

        if (isNewMessageAdded) {
          setState(() {});
          _scrollToBottom();
        }
      }
    } catch (e) {
      // Polling hatalarını sessizce yoksay
    }
  }

  Future<void> _loadMoreMessages() async {
    setState(() {
      _isLoadingMore = true;
    });

    final api = ref.read(apiServiceProvider);
    _currentOffset += _limit;

    try {
      final result = await api.getMessages(
        widget.chatId,
        offset: _currentOffset,
        limit: _limit,
      );

      if (result['success'] == true) {
        final List<Map<String, dynamic>> newMessages =
            List<Map<String, dynamic>>.from(result['data']);

        if (mounted) {
          setState(() {
            if (newMessages.isEmpty || newMessages.length < _limit) {
              _hasMore = false;
            }
            // Eski mesajları listenin BAŞINA ekle
            _messages.insertAll(0, newMessages);
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _initChat() async {
    // Profil bilgisinden kendi ID'mizi alalım
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _myUserId = int.tryParse(profile['id']?.toString() ?? '0');
    }

    // Geçmiş mesajları yükle
    final api = ref.read(apiServiceProvider);

    try {
      final result = await api.getMessages(
        widget.chatId,
        offset: 0,
        limit: _limit,
      );

      if (result['success'] == true) {
        if (mounted) {
          final fetchedMessages = List<Map<String, dynamic>>.from(
            result['data'],
          );
          setState(() {
            _messages = fetchedMessages;
            _isLoading = false;
            if (fetchedMessages.length < _limit) {
              _hasMore = false;
            }
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          CustomSnackBar.show(
            context: context,
            message: result['message'] ?? 'Mesajlar yüklenemedi',
            type: NotificationType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('getMessages error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(
          context: context,
          message: 'Beklenmeyen bir hata oluştu.',
          type: NotificationType.error,
        );
      }
    }

    // Polling'i Başlat
    _startPolling();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
              'Bu kullanıcıyı engellemek istediğinize emin misiniz? Sohbet kapatılacak.',
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
    final result = await api.blockUser(widget.otherUserId);

    if (!mounted) return;

    if (result['success']) {
      CustomSnackBar.show(
        context: context,
        message: 'Kullanıcı engellendi.',
        type: NotificationType.success,
      );
      ref.invalidate(homeFeedProvider);
      ref.invalidate(chatsProvider);
      Navigator.pop(context); // Sohbetten çık
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
    final res = await api.reportUser(widget.otherUserId, reason);

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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _myUserId == null) return;

    // Önce UI'a ekleyelim (Optimistic UI update)
    final tempMessage = {
      'isMe': true,
      'text': text,
      'type': 'text',
      'time': _formatTime(DateTime.now()),
    };

    setState(() {
      _messages.add(tempMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    // API'ye gönder
    final api = ref.read(apiServiceProvider);
    final result = await api.sendMessage(widget.chatId, text, type: 'text');

    if (result['success'] != true) {
      // Gönderim başarısızsa kullanıcıya bildir
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: result['message'] ?? 'Mesaj gönderilemedi',
          type: NotificationType.error,
        );
        // İstersen burada tempMessage'i listeden silebilirsin
      }
    }
  }

  Future<void> _sendImage() async {
    // Kullanıcıya Kamera veya Galeri seçeneği sunalım
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fotoğraf Gönder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  _buildMediaOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: Colors.purple,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile == null || _myUserId == null) return;

    setState(() => _isUploadingImage = true);

    final api = ref.read(apiServiceProvider);
    final result = await api.uploadChatMedia(File(pickedFile.path));

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (result['success'] == true) {
      final imageUrl = result['url'];

      // Mesajı API'ye gönder
      final sendResult = await api.sendMessage(
        widget.chatId,
        imageUrl,
        type: 'image',
      );

      if (sendResult['success'] == true && mounted) {
        setState(() {
          _messages.add({
            'isMe': true,
            'text': imageUrl,
            'type': 'image',
            'time': _formatTime(DateTime.now()),
          });
        });
        _scrollToBottom();
      }
    } else {
      CustomSnackBar.show(
        context: context,
        message: result['message'] ?? 'Fotoğraf gönderilemedi',
        type: NotificationType.error,
      );
    }
  }

  Widget _buildMediaOption(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    UserRank userRank = UserRank.none;
    if (widget.rankLevel == 'legendary') userRank = UserRank.legendary;
    if (widget.rankLevel == 'popular') userRank = UserRank.popular;

    final isUserOnline = widget.isOnline ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            PremiumAvatar(
              imageUrl: widget.avatarUrl ?? '',
              size: 44,
              rank: userRank,
              showBadge: true,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    PremiumNameBadge(rank: userRank, size: 14),
                  ],
                ),
                Text(
                  isUserOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUserOnline ? cs.primary : cs.onSurfaceVariant,
                    fontWeight:
                        isUserOnline ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sohbet Alanı
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message['isMe'] as bool;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  backgroundImage:
                                      widget.avatarUrl != null &&
                                              widget.avatarUrl!.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                            widget.avatarUrl!,
                                          )
                                          : null,
                                  child:
                                      widget.avatarUrl == null ||
                                              widget.avatarUrl!.isEmpty
                                          ? Icon(
                                            Icons.person,
                                            color: cs.onSurfaceVariant,
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow:
                                        isMe
                                            ? [
                                              BoxShadow(
                                                color: cs.primary.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                            : [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(24),
                                      topRight: const Radius.circular(24),
                                      bottomLeft:
                                          isMe
                                              ? const Radius.circular(24)
                                              : const Radius.circular(6),
                                      bottomRight:
                                          isMe
                                              ? const Radius.circular(6)
                                              : const Radius.circular(24),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(24),
                                      topRight: const Radius.circular(24),
                                      bottomLeft:
                                          isMe
                                              ? const Radius.circular(24)
                                              : const Radius.circular(6),
                                      bottomRight:
                                          isMe
                                              ? const Radius.circular(6)
                                              : const Radius.circular(24),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        padding:
                                            message['type'] == 'image'
                                                ? const EdgeInsets.all(8)
                                                : const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 14,
                                                ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              isMe
                                                  ? LinearGradient(
                                                    colors: [
                                                      cs.primary.withValues(
                                                        alpha: 0.9,
                                                      ),
                                                      cs.secondary.withValues(
                                                        alpha: 0.9,
                                                      ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                  : null,
                                          color:
                                              isMe
                                                  ? null
                                                  : cs.surfaceContainerHighest
                                                      .withValues(alpha: 0.8),
                                          border: Border.all(
                                            color:
                                                isMe
                                                    ? Colors.white.withValues(
                                                      alpha: 0.2,
                                                    )
                                                    : cs.outlineVariant
                                                        .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                          children: [
                                            message['type'] == 'image'
                                                ? GestureDetector(
                                                  onTap: () {
                                                    if (!isMe) {
                                                      setState(() {
                                                        _unblurredImages.add(
                                                          message['text']
                                                              as String,
                                                        );
                                                      });
                                                    }
                                                  },
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        CachedNetworkImage(
                                                          imageUrl:
                                                              message['text']
                                                                  as String,
                                                          width: 200,
                                                          fit: BoxFit.cover,
                                                          placeholder:
                                                              (
                                                                context,
                                                                url,
                                                              ) => const SizedBox(
                                                                width: 200,
                                                                height: 200,
                                                                child: Center(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ),
                                                              ),
                                                          errorWidget:
                                                              (
                                                                context,
                                                                url,
                                                                error,
                                                              ) => const SizedBox(
                                                                width: 200,
                                                                height: 200,
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    size: 50,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              ),
                                                        ),
                                                        // Blur Efekti (Eğer ben göndermediysem ve henüz tıklamadıysam)
                                                        if (!isMe &&
                                                            !_unblurredImages
                                                                .contains(
                                                                  message['text'],
                                                                ))
                                                          Positioned.fill(
                                                            child: BackdropFilter(
                                                              filter:
                                                                  ImageFilter.blur(
                                                                    sigmaX: 15,
                                                                    sigmaY: 15,
                                                                  ),
                                                              child: Container(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: const Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .visibility_off,
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      size: 32,
                                                                    ),
                                                                    SizedBox(
                                                                      height: 8,
                                                                    ),
                                                                    Text(
                                                                      'Görmek için tıkla',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                : Text(
                                                  message['text'] as String,
                                                  style: TextStyle(
                                                    color:
                                                        isMe
                                                            ? Colors.white
                                                            : cs.onSurface,
                                                    fontSize: 15,
                                                    height: 1.3,
                                                  ),
                                                ),
                                            const SizedBox(height: 6),
                                            Text(
                                              message['time'] as String,
                                              style: TextStyle(
                                                color:
                                                    isMe
                                                        ? Colors.white
                                                            .withValues(
                                                              alpha: 0.7,
                                                            )
                                                        : cs.onSurfaceVariant,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),

          // Mesaj Yazma Alanı (Modern Input)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Eklenti Butonu
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child:
                        _isUploadingImage
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : IconButton(
                              icon: Icon(
                                Icons.image_rounded,
                                color: cs.primary,
                              ),
                              onPressed: _sendImage,
                            ),
                  ),
                  const SizedBox(width: 12),

                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Mesaj yaz...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.sentiment_satisfied_alt),
                            color: cs.onSurfaceVariant,
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Gönder Butonu (Gradient)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
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
