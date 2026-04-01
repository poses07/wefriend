import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../screens/auth_screens.dart';

class ApiService {
  // Test aşamasında local sunucuya (XAMPP) bağlanmak için:
  // Eğer fiziksel cihaz kullanıyorsan bilgisayarının yerel IP'sini yaz (Örn: 192.168.1.x)
  // Eğer Android Emulator kullanıyorsan 10.0.2.2 kullan.
  // Gerçek yayında 'https://operasyon.milatsoft.com/api' olarak değiştir.
  static const String baseUrl = 'https://operasyon.milatsoft.com/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await refreshAccessToken();
            if (refreshed) {
              final opts = error.requestOptions;
              final newToken = await getToken();
              opts.headers['Authorization'] = 'Bearer $newToken';

              try {
                final cloneReq = await _dio.fetch(opts);
                return handler.resolve(cloneReq);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // UUID (Cihaz Kimliği) Üretici/Getirici
  Future<String> getDeviceUuid() async {
    String? storedUuid = await _storage.read(key: 'device_uuid');
    if (storedUuid != null) {
      return storedUuid;
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String uuid = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        uuid = androidInfo.id; // Benzersiz cihaz ID'si
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        uuid =
            iosInfo.identifierForVendor ??
            DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      uuid = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }

    await _storage.write(key: 'device_uuid', value: uuid);
    return uuid;
  }

  // Token'ı güvenli depolamaya kaydet
  Future<void> saveToken(String token, {String? refreshToken}) async {
    await _storage.write(key: 'jwt_token', value: token);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    // Bundan sonraki isteklerde header'a token ekle
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Kayıtlı Token'ı getir
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Refresh Token kullanarak yeni Access Token al
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data']['token'] != null) {
          final newToken = data['data']['token'];
          await saveToken(newToken);
          return true;
        }
      }
      // Refresh token başarısız olursa çıkış yap
      await logout();
      return false;
    } catch (e) {
      return false;
    }
  }

  // Çıkış yap (Token'ı sil)
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    _dio.options.headers.remove('Authorization');

    // Token silindiğinde her yerden güvenle login ekranına yönlendir
    importMainAndRedirect();
  }

  void importMainAndRedirect() {
    // navigatorKey'i main'den kullanmak için
    // Future.microtask veya delayed ile build çakışmasını önle
    Future.microtask(() {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Zaten login ekranındaysa veya AuthChecker isLoading true iken push yapmamak için ufak bir kontrol:
        // Ancak en garantisi route yapısını temizlemektir.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  // --- API ENDPOINTLERİ ---

  // Kayıt Ol
  Future<Map<String, dynamic>> register({
    required String alias,
    required String phone,
    required String password,
  }) async {
    try {
      final uuid = await getDeviceUuid();
      debugPrint('Register Request: alias=$alias, phone=$phone, uuid=$uuid');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'alias': alias,
          'phone': phone,
          'password': password,
          'uuid': uuid,
        }),
      );

      debugPrint(
        'Register Response: ${response.statusCode} - ${response.body}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == 'success') {
          // Token dönüyorsa kaydet
          if (data['data'] != null && data['data']['token'] != null) {
            final token = data['data']['token'];
            final refreshToken = data['data']['refresh_token'];
            await saveToken(token, refreshToken: refreshToken);
          }
          return {'success': true, 'message': data['message']};
        }
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Kayıt yapılamadı',
      };
    } catch (e) {
      debugPrint('Register General Exception: $e');
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // Giriş Yap
  Future<Map<String, dynamic>> login({
    required String aliasOrPhone,
    required String password,
    required bool isPhone,
  }) async {
    try {
      final requestData = {'password': password};

      if (isPhone) {
        requestData['phone'] = aliasOrPhone;
      } else {
        requestData['alias'] = aliasOrPhone;
      }

      debugPrint('Login Request (HTTP): $requestData');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestData),
      );

      debugPrint(
        'Login Response (HTTP): ${response.statusCode} - ${response.body}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['data']['token'];
        final refreshToken = data['data']['refresh_token'];
        await saveToken(token, refreshToken: refreshToken);
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Giriş yapılamadı',
      };
    } catch (e) {
      debugPrint('Login General Exception: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası (Sunucuya ulaşılamıyor)',
      };
    }
  }

  // Profil Bilgilerini Getir
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['status'] == 'success') {
          return {'success': true, 'data': decoded['data']};
        }
      } else if (response.statusCode == 401) {
        await logout();
      }
      return {'success': false, 'message': 'Profil alınamadı'};
    } catch (e) {
      debugPrint('getProfile HTTP Error: $e');
      return {
        'success': false,
        'message': 'Profil verisi işlenemedi (Bağlantı)',
      };
    }
  }

  // Profil Ziyaretçilerini Getir
  Future<List<Map<String, dynamic>>> getProfileVisitors() async {
    try {
      final response = await _dio.get('/user/visitors');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('getProfileVisitors hatası: $e');
      return [];
    }
  }

  // Kullanıcıyı Beğen veya Süper Beğen (Match sistemi)
  Future<Map<String, dynamic>> likeUser(
    int targetId, {
    bool isSuperLike = false,
  }) async {
    try {
      final response = await _dio.post(
        '/user/like',
        data: {'target_id': targetId, 'is_super_like': isSuperLike},
      );

      return {
        'success': response.data['status'] == 'success',
        'message': response.data['message'],
        'is_match': response.data['data']?['is_match'] ?? false,
        'is_super_like': response.data['data']?['is_super_like'] ?? false,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Beğeni işlemi başarısız',
      };
    }
  }

  // Profili Öne Çıkar (Boost)
  Future<Map<String, dynamic>> boostProfile({String package = '1_hour'}) async {
    try {
      final response = await _dio.post(
        '/user/boost',
        data: {'package': package},
      );
      return {
        'success': response.data['status'] == 'success',
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Boost işlemi başarısız',
      };
    }
  }

  // Quests (Görevler) Getir
  Future<Map<String, dynamic>> getQuests() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/quests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['data']};
        }
      } else if (response.statusCode == 401) {
        await logout();
      }
      return {'success': false, 'message': 'Görevler alınamadı'};
    } catch (e) {
      debugPrint('getQuests hatası (HTTP): $e');
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Bildirimleri Getir
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['data']};
        }
      } else if (response.statusCode == 401) {
        await logout();
      }
      return {'success': false, 'message': 'Bildirimler alınamadı'};
    } catch (e) {
      debugPrint('getNotifications hatası: $e');
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Bildirimleri Okundu İşaretle
  Future<Map<String, dynamic>> markNotificationsAsRead({int? id}) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final body = id != null ? jsonEncode({'id': id}) : jsonEncode({});

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Tüm Bildirimleri Sil
  Future<Map<String, dynamic>> clearAllNotifications() async {
    try {
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/clear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Hikayeleri Getir
  Future<Map<String, dynamic>> getStories() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/stories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['data']};
        }
      }
      return {'success': false, 'message': 'Hikayeler alınamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Hikaye Görüntüleme Kaydet
  Future<Map<String, dynamic>> viewStory(int storyId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/stories/view'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'story_id': storyId}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Kendi Hikayemin Görüntüleyenlerini Getir
  Future<Map<String, dynamic>> getStoryViewers(int storyId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/stories/viewers?story_id=$storyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['data']};
        }
      }
      return {'success': false, 'message': 'Görüntüleyenler alınamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Akışı Getir (Home Screen)
  Future<Map<String, dynamic>> getFeed({
    String? gender,
    String? city,
    bool? online,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (online == true) queryParams['online'] = 'true';

      final response = await _dio.get(
        '/user/feed',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': 'Akış alınamadı'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Bağlantı hatası',
      };
    }
  }

  // Sohbet Başlat veya Getir (DIO YERİNE HTTP KULLANILACAK)
  Future<Map<String, dynamic>> startChat(int userId) async {
    try {
      debugPrint('StartChat Request (HTTP): user_id=$userId');

      final token = await getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/chats/start'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId}),
      );

      debugPrint(
        'StartChat Response (HTTP): ${response.statusCode} - ${response.body}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Sohbet başlatılamadı',
      };
    } catch (e) {
      debugPrint('StartChat GeneralError (HTTP): $e');
      return {'success': false, 'message': 'Bilinmeyen bir hata oluştu: $e'};
    }
  }

  // Sohbeti Sil
  Future<Map<String, dynamic>> deleteChat(int chatId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/chats/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({'chat_id': chatId}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // Mesaj Gönder (PHP API üzerinden)
  Future<Map<String, dynamic>> sendMessage(
    int chatId,
    String content, {
    String type = 'text',
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/chats/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({'chat_id': chatId, 'content': content, 'type': type}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Mesaj gönderilemedi',
      };
    } catch (e) {
      debugPrint('sendMessage hatası: $e');
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // Sohbetleri Getir
  Future<Map<String, dynamic>> getChats() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['data']};
        }
      } else if (response.statusCode == 401) {
        await logout();
      }
      return {'success': false, 'message': 'Sohbetler alınamadı'};
    } catch (e) {
      debugPrint('getChats hatası (HTTP): $e');
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Mesajları Getir
  Future<Map<String, dynamic>> getMessages(
    int chatId, {
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      debugPrint(
        'getMessages çağrılıyor (HTTP): chatId=$chatId, offset=$offset, limit=$limit',
      );
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(
          '$baseUrl/chats/messages?chat_id=$chatId&offset=$offset&limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      debugPrint(
        'getMessages cevap: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        if (parsed['status'] == 'success') {
          return {'success': true, 'data': parsed['data']};
        }
        return {'success': false, 'message': parsed['message'] ?? 'Hata'};
      } else if (response.statusCode == 401) {
        await logout();
        return {'success': false, 'message': 'Oturum süresi doldu'};
      } else {
        final parsed = jsonDecode(response.body);
        return {
          'success': false,
          'message': parsed['message'] ?? 'Bir hata oluştu',
        };
      }
    } catch (e) {
      debugPrint('getMessages Genel hata (HTTP): $e');
      return {'success': false, 'message': 'Bilinmeyen bir hata oluştu'};
    }
  }

  // Görev Ödülünü Al
  Future<Map<String, dynamic>> claimQuestReward(int questId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/quests/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'quest_id': questId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Hata oluştu'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Yardımcı Metot: Görsel Sıkıştırma
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // %70 kalite ile boyut ciddi oranda düşer
      minWidth: 1080,
      minHeight: 1080,
    );

    return result != null ? File(result.path) : file;
  }

  // Hikaye Yükle
  Future<Map<String, dynamic>> uploadStory(File imageFile) async {
    try {
      final token = await _storage.read(key: 'jwt_token');

      // Fotoğrafı sıkıştır
      final compressedFile = await _compressImage(imageFile);
      String fileName = compressedFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        "media": await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/stories/add',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Hikaye yüklenemedi: $e'};
    }
  }

  // Hikaye Sil
  Future<Map<String, dynamic>> deleteStory(int storyId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/stories/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'story_id': storyId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Hikaye silinemedi',
      };
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  // Profil Bilgilerini Güncelle (Edit veya Onboarding)
  Future<Map<String, dynamic>> updateProfile({
    String? alias,
    String? bio,
    String? age,
    String? gender,
    String? city,
    File? avatar,
    bool removeAvatar = false,
  }) async {
    try {
      // Resim varsa Multipart, yoksa normal data göndereceğiz
      final formData = FormData();

      if (alias != null) formData.fields.add(MapEntry('alias', alias));
      if (bio != null) formData.fields.add(MapEntry('bio', bio));
      if (age != null) formData.fields.add(MapEntry('age', age));
      if (gender != null) formData.fields.add(MapEntry('gender', gender));
      if (city != null) formData.fields.add(MapEntry('city', city));

      // removeAvatar true ise API'ye gönder
      if (removeAvatar) {
        formData.fields.add(const MapEntry('removeAvatar', 'true'));
      }

      if (avatar != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(
              avatar.path,
              filename: avatar.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post('/user/profile/update', data: formData);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': 'Profil güncellenemedi'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Bağlantı hatası',
      };
    }
  }

  // Engellenen Kullanıcıları Getir
  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/user/blocked'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'data': data['data']};
        }
      }
      return {'success': false, 'message': 'Engellenenler alınamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  // Kullanıcı Engelini Kaldır
  Future<Map<String, dynamic>> unblockUser(int blockedId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/user/unblock'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({'blocked_id': blockedId}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }

  Future<Map<String, dynamic>> reportUser(
    int userId,
    String reason, {
    String? details,
  }) async {
    try {
      final response = await _dio.post(
        '/user/report',
        data: {'reported_id': userId, 'reason': reason, 'details': details},
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': 'Şikayet edilemedi'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await logout();
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Bağlantı hatası',
      };
    }
  }

  Future<Map<String, dynamic>> blockUser(int userId) async {
    try {
      final response = await _dio.post(
        '/user/block',
        data: {'blocked_id': userId},
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': 'Kullanıcı engellenemedi'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await logout();
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Bağlantı hatası',
      };
    }
  }

  Future<Map<String, dynamic>> uploadChatMedia(File image) async {
    try {
      final compressedFile = await _compressImage(image);
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          compressedFile.path,
          filename: compressedFile.path.split('/').last,
        ),
      });

      final response = await _dio.post('/chats/upload_media', data: formData);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'url': response.data['data']['url']};
      }
      return {'success': false, 'message': 'Yüklenemedi'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await logout();
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Bağlantı hatası',
      };
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post('/user/fcm_token', data: {'token': token});
    } catch (e) {
      // Sessizce başarısız olabilir, kritik değil
      debugPrint('FCM Token güncellenemedi: $e');
    }
  }

  // --- ADMIN API ---

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': 'İstatistikler alınamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  Future<Map<String, dynamic>> getAdminUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': 'Kullanıcılar alınamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  Future<Map<String, dynamic>> updateAdminUser(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = {'id': id, ...updates};
      final response = await _dio.post('/admin/users/update', data: data);
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Güncellenemedi',
      };
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  Future<Map<String, dynamic>> banAdminUser(int userId) async {
    try {
      final response = await _dio.post(
        '/admin/users/ban',
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': 'Yasaklanamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  Future<Map<String, dynamic>> getAdminReports() async {
    try {
      final response = await _dio.get('/admin/reports');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': 'Şikayetler alınamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }

  Future<Map<String, dynamic>> resolveAdminReport(
    int reportId,
    String status,
  ) async {
    try {
      final response = await _dio.post(
        '/admin/reports/resolve',
        data: {'report_id': reportId, 'status': status},
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': 'Şikayet güncellenemedi'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası'};
    }
  }
}
