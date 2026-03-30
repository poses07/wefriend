import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_service.dart';

// Temanın State'ini (Dark/Light Mode) tutan Notifier
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

// Bildirimlerin State'ini tutan Notifier
class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Varsayılan olarak bildirimler açık
  }

  void setNotifications(bool isEnabled) {
    state = isEnabled;
  }

  void toggle() {
    state = !state;
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, bool>(() {
  return NotificationsNotifier();
});

// ApiService Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// User Profile Provider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getProfile();

  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});

// User Quests Provider
final userQuestsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getQuests();

  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});

// Feed Filtreleri
class FeedFilter {
  final String? gender;
  final String? city;
  final bool online;

  FeedFilter({this.gender, this.city, this.online = false});

  FeedFilter copyWith({String? gender, String? city, bool? online}) {
    return FeedFilter(
      gender: gender ?? this.gender,
      city: city ?? this.city,
      online: online ?? this.online,
    );
  }
}

final feedFilterProvider = StateProvider<FeedFilter>((ref) {
  return FeedFilter();
});

// Home Feed Provider
final homeFeedProvider = FutureProvider<List<dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final filter = ref.watch(feedFilterProvider);

  final result = await api.getFeed(
    gender: filter.gender,
    city: filter.city,
    online: filter.online,
  );

  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});

// Chats Provider
final chatsProvider = FutureProvider<List<dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getChats();

  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});

// Stories Provider
final storiesProvider = FutureProvider<List<dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getStories();

  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});

// Notifications Provider
final notificationsListProvider = FutureProvider<List<dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.getNotifications();

  if (result['success'] == true) {
    return result['data'];
  }
  return null;
});
