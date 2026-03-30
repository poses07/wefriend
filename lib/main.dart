import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screens.dart';
import 'screens/shell.dart';
import 'screens/chat_detail_screen.dart';
import 'providers.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase yapılandırmasını kurmak için (google-services.json vb.)
    // Firebase console'dan proje oluşturup google-services.json dosyasını android/app içine atmalısın.
    // await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase başlatılamadı: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WeFriend',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AuthChecker(),
    );
  }
}

class AuthChecker extends ConsumerStatefulWidget {
  const AuthChecker({super.key});

  @override
  ConsumerState<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends ConsumerState<AuthChecker> {
  bool _isLoading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final api = ref.read(apiServiceProvider);
    final token = await api.getToken();

    // Eğer token varsa, API istekleri için Dio header'ına ekliyoruz
    if (token != null) {
      await api.saveToken(
        token,
      ); // Hem _storage'a yazar hem de header'a set eder

      // Token'ın geçerli olup olmadığını (veya kullanıcının silinip silinmediğini) kontrol et
      final profileResult = await api.getProfile();
      if (profileResult['success'] != true) {
        // Token geçersiz veya kullanıcı bulunamadı (401 vb.)
        await api
            .logout(); // api_service içindeki logout zaten login ekranına yönlendirme tetikleyebilir ama state'i de güncelleyelim
        if (mounted) {
          setState(() {
            _hasToken = false;
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _hasToken = token != null;
        _isLoading = false;
      });

      // Token varsa Push Notification servisini başlatmayı deneyelim
      if (_hasToken) {
        try {
          // Firebase initializeApp() yorum satırından çıkarıldığında çalışacaktır
          // final pushService = PushNotificationService();
          // await pushService.initialize();
          //
          // _handleNotificationNavigation(remoteMessage);
        } catch (e) {
          debugPrint('Push service hatası: $e');
        }
      }
    }
  }

  // Firebase bağlandığında kullanılacak
  // ignore: unused_element
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (data['type'] == 'chat' && data['chatId'] != null) {
      final chatId = int.tryParse(data['chatId'].toString()) ?? 0;
      final senderId = int.tryParse(data['senderId'].toString()) ?? 0;

      if (chatId > 0 && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: chatId,
                  otherUserId: senderId,
                  userName: 'Mesaj', // İdealde API'den çekilir
                ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasToken) {
      return const Shell();
    } else {
      return const LoginScreen();
    }
  }
}
