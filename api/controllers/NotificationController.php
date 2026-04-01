<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../utils/JwtHandler.php';
require_once __DIR__ . '/../core/Response.php';

class NotificationController {
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

        return $payload['user_id'];
    }

    public function getNotifications() {
        $user_id = $this->authenticate();

        try {
            $this->db->exec("CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                type VARCHAR(50) DEFAULT 'info',
                is_read TINYINT(1) DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_user (user_id)
            )");
        } catch (Exception $e) {}

        $query = "SELECT id, title, message, type, is_read, created_at FROM notifications WHERE user_id = :user_id ORDER BY created_at DESC LIMIT 50";
        $stmt = $this->db->prepare($query);
        $stmt->execute([':user_id' => $user_id]);
        $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json(200, "Bildirimler getirildi.", $notifications);
    }

    public function markAsRead() {
        $user_id = $this->authenticate();
        
        $raw_input = file_get_contents("php://input");
        $data = json_decode($raw_input, true);

        if (isset($data['id'])) {
            // Belirli bir bildirimi okundu işaretle
            $notification_id = (int)$data['id'];
            $query = "UPDATE notifications SET is_read = 1 WHERE id = :id AND user_id = :user_id";
            $stmt = $this->db->prepare($query);
            $stmt->execute([':id' => $notification_id, ':user_id' => $user_id]);
        } else {
            // Tüm bildirimleri okundu işaretle
            $query = "UPDATE notifications SET is_read = 1 WHERE user_id = :user_id";
            $stmt = $this->db->prepare($query);
            $stmt->execute([':user_id' => $user_id]);
        }

        Response::json(200, "Bildirimler güncellendi.");
    }

    public function deleteAll() {
        $user_id = $this->authenticate();
        
        // Kullanıcıya ait tüm bildirimleri sil
        $query = "DELETE FROM notifications WHERE user_id = :user_id";
        $stmt = $this->db->prepare($query);
        $stmt->execute([':user_id' => $user_id]);

        Response::json(200, "Tüm bildirimler silindi.");
    }
}
?>