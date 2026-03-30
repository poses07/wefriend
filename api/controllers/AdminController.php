<?php
require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../core/Response.php';
require_once __DIR__ . '/../utils/JwtHandler.php';

class AdminController {
    private $db;

    public function __construct() {
        $this->db = (new Database())->getConnection();
    }

    private function authenticateAdmin() {
        $headers = getallheaders();
        if (!isset($headers['Authorization'])) {
            Response::json(401, "Yetkilendirme başlığı eksik.");
            exit();
        }

        $authHeader = $headers['Authorization'];
        $token = str_replace('Bearer ', '', $authHeader);

        $decoded = JwtHandler::decode($token);
        if (!$decoded || isset($decoded['is_expired']) && $decoded['is_expired']) {
            Response::json(401, "Geçersiz veya süresi dolmuş token.");
            exit();
        }

        $user_id = $decoded['user_id'];
        
        $stmt = $this->db->prepare("SELECT is_admin FROM users WHERE id = :id");
        $stmt->execute([':id' => $user_id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user || $user['is_admin'] != 1) {
            Response::json(403, "Bu işlem için admin yetkisi gerekiyor.");
            exit();
        }

        return $user_id;
    }

    public function getDashboardStats() {
        $this->authenticateAdmin();

        $stats = [];
        
        $stats['total_users'] = $this->db->query("SELECT COUNT(*) FROM users")->fetchColumn();
        $stats['active_users_24h'] = $this->db->query("SELECT COUNT(*) FROM users WHERE last_active >= NOW() - INTERVAL 24 HOUR")->fetchColumn();
        $stats['total_chats'] = $this->db->query("SELECT COUNT(*) FROM chats")->fetchColumn();
        $stats['total_messages'] = $this->db->query("SELECT COUNT(*) FROM messages")->fetchColumn();
        $stats['active_stories'] = $this->db->query("SELECT COUNT(*) FROM stories WHERE expires_at > NOW()")->fetchColumn();
        $stats['total_reports'] = $this->db->query("SELECT COUNT(*) FROM reports")->fetchColumn();

        Response::json(200, "İstatistikler getirildi.", $stats);
    }

    public function getUsers() {
        $this->authenticateAdmin();
        $stmt = $this->db->query("SELECT id, alias, phone, age, gender, city, rank_level, coins, xp_points, is_admin, created_at, last_active FROM users ORDER BY created_at DESC");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        Response::json(200, "Kullanıcılar getirildi.", $users);
    }

    public function updateUser() {
        $this->authenticateAdmin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['id'])) {
            Response::json(400, "Kullanıcı ID gerekli.");
            exit;
        }

        $id = $data['id'];
        $updates = [];
        $params = [':id' => $id];

        $allowedFields = ['alias', 'coins', 'xp_points', 'rank_level', 'is_admin'];
        foreach ($allowedFields as $field) {
            if (isset($data[$field])) {
                $updates[] = "$field = :$field";
                $params[":$field"] = $data[$field];
            }
        }

        if (empty($updates)) {
            Response::json(400, "Güncellenecek veri yok.");
            exit;
        }

        $query = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = :id";
        $stmt = $this->db->prepare($query);
        
        if ($stmt->execute($params)) {
            Response::json(200, "Kullanıcı güncellendi.");
        } else {
            Response::json(500, "Güncelleme başarısız.");
        }
    }

    public function getReports() {
        $this->authenticateAdmin();
        $stmt = $this->db->query("
            SELECT r.*, 
                   u1.alias as reporter_name, 
                   u2.alias as reported_name 
            FROM reports r 
            JOIN users u1 ON r.reporter_id = u1.id 
            JOIN users u2 ON r.reported_id = u2.id 
            ORDER BY r.created_at DESC
        ");
        $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
        Response::json(200, "Şikayetler getirildi.", $reports);
    }

    public function resolveReport() {
        $this->authenticateAdmin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $report_id = $data['report_id'] ?? 0;
        $status = $data['status'] ?? 'resolved';

        if ($report_id <= 0) {
            Response::json(400, "Geçersiz şikayet ID.");
            exit;
        }

        $stmt = $this->db->prepare("UPDATE reports SET status = :status WHERE id = :id");
        if ($stmt->execute([':status' => $status, ':id' => $report_id])) {
            Response::json(200, "Şikayet durumu güncellendi.");
        } else {
            Response::json(500, "Şikayet güncellenemedi.");
        }
    }

    public function banUser() {
        $this->authenticateAdmin();
        $data = json_decode(file_get_contents("php://input"), true);
        $user_id = $data['user_id'] ?? 0;

        if ($user_id <= 0) {
            Response::json(400, "Geçersiz kullanıcı ID.");
            exit;
        }

        // Ban mantığı: Şimdilik token'ı geçersiz kılmak veya bir is_banned sütunu eklemek.
        // Basitlik için bir sütun eklenebilir veya şifre bozularak giriş engellenebilir.
        try {
            $this->db->exec("ALTER TABLE users ADD COLUMN is_banned TINYINT(1) DEFAULT 0");
        } catch (Exception $e) {}

        $stmt = $this->db->prepare("UPDATE users SET is_banned = 1 WHERE id = :id");
        $stmt->execute([':id' => $user_id]);

        Response::json(200, "Kullanıcı yasaklandı.");
    }
}
?>