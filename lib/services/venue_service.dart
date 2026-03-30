import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // debugPrint için eklendi
import 'api_service.dart';

class VenueService {
  final ApiService _apiService = ApiService();

  // Foursquare API bilgileri
  final String _fsqApiKey =
      'fsq3O8j5Q2XyT7Xb2N7zB8Y0t4vL8xG1hR6mP9kK2bW5qE='; // Buraya kendi Foursquare API anahtarını eklemelisin
  final String _fsqBaseUrl = 'https://api.foursquare.com/v3/places';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Foursquare üzerinden yakındaki mekanları arar (Autocomplete için kullanılabilir)
  Future<List<Map<String, dynamic>>> searchFoursquareVenues(
    String query, {
    double lat = 41.0082,
    double lng = 28.9784,
  }) async {
    if (query.isEmpty) return [];

    try {
      final uri = Uri.parse('$_fsqBaseUrl/search').replace(
        queryParameters: {
          'query': query,
          'll': '$lat,$lng', // Enlem boylam (Örn: İstanbul)
          'radius': '10000', // 10km yarıçap
          'limit': '10',
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': _fsqApiKey, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        return results.map((place) {
          // Kategori ikonunu al
          String iconUrl = '';
          if (place['categories'] != null && place['categories'].isNotEmpty) {
            final category = place['categories'][0];
            if (category['icon'] != null) {
              final prefix = category['icon']['prefix'];
              final suffix = category['icon']['suffix'];
              iconUrl = '${prefix}64$suffix'; // 64px ikon
            }
          }

          // Foursquare fotoğrafı al (ayrı bir istek gerektirebilir, şimdilik sadece ID dönüyoruz)
          final fsqId = place['fsq_id'];

          return {
            'fsq_id': fsqId,
            'name': place['name'],
            'address': place['location']?['formatted_address'] ?? '',
            'distance': place['distance'],
            'icon_url': iconUrl,
            'type':
                place['categories'] != null && place['categories'].isNotEmpty
                    ? place['categories'][0]['name']
                    : 'Mekan',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Foursquare arama hatası: $e');
      return [];
    }
  }

  /// Belirli bir mekanın Foursquare fotoğraflarını getirir
  Future<List<String>> getVenuePhotos(String fsqId) async {
    try {
      final response = await http.get(
        Uri.parse('$_fsqBaseUrl/$fsqId/photos?limit=5'),
        headers: {'Authorization': _fsqApiKey, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List photos = jsonDecode(response.body);
        return photos.map((photo) {
          return '${photo['prefix']}original${photo['suffix']}';
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Foursquare fotoğraf hatası: $e');
      return [];
    }
  }

  /// Aktif mekanları getirir (kullanıcıların şu an bulunduğu mekanlar - Backend'den)
  Future<List<Map<String, dynamic>>> getActiveVenues() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/venues/active'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Aktif mekanlar alınamadı');
    } catch (e) {
      throw Exception('Mekanlar yüklenirken hata oluştu: $e');
    }
  }

  /// Belirli bir mekana check-in yapmış kullanıcıları getirir
  Future<List<Map<String, dynamic>>> getVenueUsers(String venueName) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '${ApiService.baseUrl}/venues/users',
      ).replace(queryParameters: {'venue_name': venueName});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Mekan kullanıcıları alınamadı');
    } catch (e) {
      throw Exception('Kullanıcılar yüklenirken hata oluştu: $e');
    }
  }

  /// Mekan paylaş (Check-in)
  Future<Map<String, dynamic>> checkIn(
    String venueName, {
    String? fsqId,
  }) async {
    try {
      final headers = await _getHeaders();
      final bodyData = {
        'venue_name': venueName,
        if (fsqId != null) 'fsq_id': fsqId,
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/venues/checkin'),
        headers: headers,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {'success': true, 'message': data['message']};
        }
      }
      return {'success': false, 'message': 'Mekan paylaşılamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Bağlantı hatası: $e'};
    }
  }
}
