<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../utils/JwtHandler.php';
require_once __DIR__ . '/../core/Response.php';

class VenueController {
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    private function authenticate() {
        $headers = null;
        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER["Authorization"]);
        } else if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = trim($_SERVER["HTTP_AUTHORIZATION"]);
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            $requestHeaders = array_combine(array_map('ucwords', array_keys($requestHeaders)), array_values($requestHeaders));
            if (isset($requestHeaders['Authorization'])) {
                $headers = trim($requestHeaders['Authorization']);
            }
        }

        if (!$headers) {
            Response::json(401, "Yetkisiz erişim. Token bulunamadı.");
            exit();
        }

        $parts = explode(" ", $headers);
        if (count($parts) != 2 || $parts[0] !== 'Bearer') {
            Response::json(401, "Geçersiz token formatı.");
            exit();
        }

        $token = $parts[1];
        $payload = JwtHandler::decode($token);

        if (!$payload) {
            Response::json(401, "Geçersiz veya süresi dolmuş token.");
            exit();
        }

        $user_id = $payload['user_id'];

        $stmt = $this->db->prepare("SELECT id FROM users WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $user_id]);
        
        if ($stmt->rowCount() == 0) {
            Response::json(401, "Kullanıcı bulunamadı.");
            exit();
        }

        return $user_id;
    }

    // Aktif mekanları (insan olan) getir
    public function getActiveVenues() {
        $user_id = $this->authenticate();

        $query = "
            SELECT venue_name, MAX(fsq_id) as fsq_id, COUNT(DISTINCT user_id) as count
            FROM venue_checkins
            WHERE expires_at > NOW()
            GROUP BY venue_name
            ORDER BY count DESC
        ";
        
        $stmt = $this->db->query($query);
        $venues = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Format for frontend
        $formatted = array_map(function($v) {
            return [
                'id' => md5($v['venue_name']), // fake id for flutter list
                'fsq_id' => $v['fsq_id'],
                'name' => $v['venue_name'],
                'wefriend_checkin_count' => (int)$v['count'],
                'type' => 'custom'
            ];
        }, $venues);

        Response::json(200, "Aktif mekanlar getirildi", $formatted);
    }

    // Belirli bir mekandaki kişileri getir
    public function getVenueUsers() {
        $user_id = $this->authenticate();
        $venue_name = isset($_GET['venue_name']) ? $_GET['venue_name'] : '';

        if (empty($venue_name)) {
            Response::json(400, "Mekan adı eksik");
            exit();
        }

        $query = "
            SELECT u.id, u.alias, u.avatar_url, u.rank_level, u.bio, u.age, u.gender, u.city, 
                   IF(u.last_active >= NOW() - INTERVAL 5 MINUTE, 1, 0) as is_online
            FROM venue_checkins vc
            JOIN users u ON vc.user_id = u.id
            WHERE vc.venue_name = :venue_name AND vc.expires_at > NOW()
            GROUP BY u.id
            ORDER BY vc.checked_in_at DESC
        ";

        $stmt = $this->db->prepare($query);
        $stmt->execute([':venue_name' => $venue_name]);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json(200, "Mekandaki kullanıcılar", $users);
    }

    // Mekan Paylaş / Check-in
    public function checkIn() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        $venue_name = isset($data['venue_name']) ? trim($data['venue_name']) : '';
        $fsq_id = isset($data['fsq_id']) ? trim($data['fsq_id']) : 'custom';
        $icon_url = isset($data['icon_url']) ? trim($data['icon_url']) : null;
        $address = isset($data['address']) ? trim($data['address']) : null;

        if (empty($venue_name)) {
            Response::json(400, "Mekan adı boş olamaz");
            exit();
        }

        // Önceki checkinleri expire et (veya sil)
        $update = $this->db->prepare("UPDATE venue_checkins SET expires_at = NOW() WHERE user_id = :user_id");
        $update->execute([':user_id' => $user_id]);

        // Yeni checkin ekle (4 saat geçerli)
        $insert = $this->db->prepare("
            INSERT INTO venue_checkins (user_id, fsq_id, venue_name, expires_at) 
            VALUES (:user_id, :fsq_id, :venue_name, DATE_ADD(NOW(), INTERVAL 4 HOUR))
        ");
        $insert->execute([
            ':user_id' => $user_id,
            ':fsq_id' => $fsq_id,
            ':venue_name' => $venue_name
        ]);

        Response::json(200, "Mekan paylaşıldı");
    }
}
?>