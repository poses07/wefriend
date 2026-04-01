<?php

// Geçici olarak hataları ekrana basalım (500 hatasının sebebini görmek için)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS Ayarları (Mobil uygulamanın API'ye erişebilmesi için gerekli)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

// Eğer gelen istek bir OPTIONS isteğiyse (Preflight), hemen 200 dön ve çık.
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Otomatik Sınıf Yükleyici (Autoloader) - require/include kirliliğini önler
spl_autoload_register(function ($class) {
    // Sınıf isimlerini klasör yapısıyla eşleştirir (Örn: controllers/UserController)
    $paths = ['core/', 'controllers/', 'models/', 'utils/', 'config/'];
    foreach ($paths as $path) {
        $file = __DIR__ . '/' . $path . $class . '.php';
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
});

// Gelen isteği al ve Yönlendiriciye (Router) gönder
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

// Router sınıfını dahil et (Autoloader öncesi IDE uyarılarını gidermek için)
require_once __DIR__ . '/core/Router.php';

// Router sınıfını başlat
$router = new Router();

// Rotaları (Endpoint'leri) Tanımla
// Auth Rotaları
$router->add('POST', '/auth/register', 'AuthController', 'register');
$router->add('POST', '/auth/login', 'AuthController', 'login');
$router->add('GET', '/auth/login', 'AuthController', 'login'); // Test için tarayıcıdan GET isteği geldiğinde de çalışsın
$router->add('POST', '/auth/refresh', 'AuthController', 'refreshToken');

// User Rotaları
$router->add('GET', '/user/profile', 'UserController', 'getProfile');
// HTTP PUT ile form-data(resim yükleme) sorunlu olabiliyor, o yüzden POST ile update ediyoruz
$router->add('POST', '/user/profile/update', 'UserController', 'updateProfile');
$router->add('GET', '/user/feed', 'UserController', 'getFeed');
$router->add('POST', '/user/block', 'UserController', 'blockUser');
$router->add('POST', '/user/unblock', 'UserController', 'unblockUser');
$router->add('GET', '/user/blocked', 'UserController', 'getBlockedUsers');
$router->add('POST', '/user/report', 'UserController', 'reportUser');
$router->add('POST', '/user/fcm_token', 'UserController', 'updateFcmToken');
$router->add('POST', '/user/boost', 'UserController', 'boostProfile');
$router->add('GET', '/user/visitors', 'UserController', 'getProfileVisitors');
$router->add('POST', '/user/like', 'UserController', 'likeUser');

// Görevler (Quests)
require_once __DIR__ . '/controllers/QuestController.php';
$router->add('GET', '/quests', 'QuestController', 'getQuests');
$router->add('POST', '/quests/claim', 'QuestController', 'claimReward');

// Admin Dashboard
require_once __DIR__ . '/controllers/AdminController.php';
$router->add('GET', '/admin/stats', 'AdminController', 'getDashboardStats');
$router->add('GET', '/admin/users', 'AdminController', 'getUsers');
$router->add('POST', '/admin/users/update', 'AdminController', 'updateUser');
$router->add('GET', '/admin/reports', 'AdminController', 'getReports');
$router->add('POST', '/admin/reports/resolve', 'AdminController', 'resolveReport');
$router->add('POST', '/admin/users/ban', 'AdminController', 'banUser');
// Sohbetler
require_once __DIR__ . '/controllers/ChatController.php';
$router->add('GET', '/chats', 'ChatController', 'getChats');
$router->add('GET', '/chats/messages', 'ChatController', 'getMessages');
$router->add('POST', '/chats/start', 'ChatController', 'startChat');
$router->add('POST', '/chats/send', 'ChatController', 'sendMessage');
$router->add('POST', '/chats/delete', 'ChatController', 'deleteChat');
$router->add('POST', '/chats/upload_media', 'ChatController', 'uploadMedia');

// Mekanlar (Venues)
require_once __DIR__ . '/controllers/VenueController.php';
$router->add('GET', '/venues/active', 'VenueController', 'getActiveVenues');
$router->add('GET', '/venues/users', 'VenueController', 'getVenueUsers');
$router->add('POST', '/venues/checkin', 'VenueController', 'checkIn');

// Bildirimler
require_once __DIR__ . '/controllers/NotificationController.php';
$router->add('GET', '/notifications', 'NotificationController', 'getNotifications');
$router->add('POST', '/notifications/read', 'NotificationController', 'markAsRead');
$router->add('DELETE', '/notifications/clear', 'NotificationController', 'deleteAll');

// Hikayeler (Stories)
require_once __DIR__ . '/controllers/StoryController.php';
$router->add('GET', '/stories', 'StoryController', 'getStories');
$router->add('POST', '/stories/add', 'StoryController', 'addStory');
$router->add('POST', '/stories/view', 'StoryController', 'viewStory');
$router->add('GET', '/stories/viewers', 'StoryController', 'getStoryViewers');
$router->add('POST', '/stories/delete', 'StoryController', 'deleteStory');

// İsteği işle
$router->dispatch($method, $uri);

?>