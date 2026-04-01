<?php

class AuthController {
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    // Kullanıcı Kayıt İşlemi
    public function register() {
        // Gelen JSON verisini al
        $data = json_decode(file_get_contents("php://input"));

        // Veri doğrulama
        if (!isset($data->alias) || !isset($data->phone) || !isset($data->password) || !isset($data->uuid)) {
            Response::json(400, "Eksik bilgi. Lütfen takma ad, telefon, şifre ve cihaz kimliğini gönderin.");
        }

        try {
            $this->db->exec("CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                uuid VARCHAR(100) NOT NULL,
                alias VARCHAR(100) NOT NULL UNIQUE,
                phone VARCHAR(50) NOT NULL UNIQUE,
                password_hash VARCHAR(255) NOT NULL,
                avatar_url VARCHAR(255),
                bio TEXT,
                age INT,
                gender ENUM('Male', 'Female', 'Other'),
                city VARCHAR(100),
                rank_level VARCHAR(50) DEFAULT 'none',
                xp_points INT DEFAULT 0,
                coins INT DEFAULT 0,
                interests TEXT,
                height INT,
                weight INT,
                zodiac_sign VARCHAR(50),
                refresh_token TEXT,
                is_admin TINYINT(1) DEFAULT 0,
                is_banned TINYINT(1) DEFAULT 0,
                last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )");
        } catch (Exception $e) {}

        $alias = htmlspecialchars(strip_tags($data->alias));
        $phone = htmlspecialchars(strip_tags($data->phone));
        $uuid = htmlspecialchars(strip_tags($data->uuid));
        $password = $data->password;

        // Telefon numarası veya takma ad daha önce alınmış mı kontrol et
        $checkQuery = "SELECT id, phone, alias FROM users WHERE phone = :phone OR alias = :alias LIMIT 1";
        $checkStmt = $this->db->prepare($checkQuery);
        $checkStmt->execute([':phone' => $phone, ':alias' => $alias]);

        if ($checkStmt->rowCount() > 0) {
            $existingUser = $checkStmt->fetch();
            if ($existingUser['phone'] === $phone) {
                Response::json(409, "Bu telefon numarası zaten sisteme kayıtlı.");
            } else {
                Response::json(409, "Bu takma ad (alias) zaten başkası tarafından alınmış. Lütfen başka bir tane seçin.");
            }
        }

        // Şifreyi güvenli bir şekilde hashle (bcrypt)
        $password_hash = password_hash($password, PASSWORD_BCRYPT);

        // Kullanıcıyı veritabanına ekle
        $query = "INSERT INTO users (uuid, alias, phone, password_hash) VALUES (:uuid, :alias, :phone, :password_hash)";
        $stmt = $this->db->prepare($query);

        try {
            $stmt->execute([
                ':uuid' => $uuid,
                ':alias' => $alias,
                ':phone' => $phone,
                ':password_hash' => $password_hash
            ]);

            $user_id = $this->db->lastInsertId();

            // Kayıt başarılı, JWT Token oluştur (Örn: 30 gün geçerli)
            $payload = [
                'user_id' => $user_id,
                'uuid' => $uuid,
                'alias' => $alias,
                'exp' => time() + (60 * 60 * 24 * 30) // 30 Gün
            ];
            
            $token = JwtHandler::encode($payload);

            // Refresh Token oluştur (Örn: 90 gün geçerli)
            $refreshPayload = [
                'user_id' => $user_id,
                'uuid' => $uuid,
                'type' => 'refresh',
                'exp' => time() + (60 * 60 * 24 * 90) // 90 Gün
            ];
            $refreshToken = JwtHandler::encode($refreshPayload);

            // Refresh token'ı veritabanına kaydet (Güvenlik için)
            $this->saveRefreshToken($user_id, $refreshToken);

            Response::json(201, "Kayıt işlemi başarılı.", [
                'token' => $token,
                'refresh_token' => $refreshToken,
                'user' => [
                    'id' => $user_id,
                    'alias' => $alias,
                    'uuid' => $uuid
                ]
            ]);

        } catch (PDOException $e) {
            Response::json(500, "Kayıt işlemi sırasında bir hata oluştu: " . $e->getMessage());
        }
    }

    // Kullanıcı Giriş İşlemi
    public function login() {
        $data = json_decode(file_get_contents("php://input"));

        // Kullanıcı telefon VEYA takma ad ile giriş yapabilir
        if ((!isset($data->phone) && !isset($data->alias)) || !isset($data->password)) {
            Response::json(400, "Giriş yapmak için telefon (veya takma ad) ve şifre gereklidir.");
        }

        $password = $data->password;
        
        // Giriş tipini belirle
        $loginField = isset($data->phone) ? 'phone' : 'alias';
        $loginValue = isset($data->phone) ? htmlspecialchars(strip_tags($data->phone)) : htmlspecialchars(strip_tags($data->alias));

        // Boşlukları temizle (trim)
        $loginValue = trim($loginValue);
        
        // Kullanıcıyı bul
        $query = "SELECT id, uuid, alias, password_hash, is_banned FROM users WHERE $loginField = :login_value LIMIT 1";
        $stmt = $this->db->prepare($query);
        $stmt->execute([':login_value' => $loginValue]);

        if ($stmt->rowCount() == 0) {
            Response::json(401, "Kullanıcı bulunamadı veya şifre hatalı.");
        }

        $user = $stmt->fetch();

        if (isset($user['is_banned']) && $user['is_banned'] == 1) {
            Response::json(403, "Hesabınız askıya alınmıştır. Lütfen destek ile iletişime geçin.");
            exit;
        }

        // Şifreyi doğrula
        if (password_verify($password, $user['password_hash'])) {
            // Son aktif olma zamanını güncelle
            $this->db->prepare("UPDATE users SET last_active = NOW() WHERE id = :id")
                     ->execute([':id' => $user['id']]);

            // Görev ilerlemesini tetikle (Giriş yaptı)
            require_once __DIR__ . '/QuestController.php';
            QuestController::incrementProgress($this->db, $user['id'], 'login', 1);

            // Giriş başarılı, Token oluştur
            $payload = [
                'user_id' => $user['id'],
                'uuid' => $user['uuid'],
                'alias' => $user['alias'],
                'exp' => time() + (60 * 60 * 24 * 30)
            ];
            
            $token = JwtHandler::encode($payload);

            // Refresh Token oluştur
            $refreshPayload = [
                'user_id' => $user['id'],
                'uuid' => $user['uuid'],
                'type' => 'refresh',
                'exp' => time() + (60 * 60 * 24 * 90) // 90 Gün
            ];
            $refreshToken = JwtHandler::encode($refreshPayload);

            $this->saveRefreshToken($user['id'], $refreshToken);

            Response::json(200, "Giriş başarılı.", [
                'token' => $token,
                'refresh_token' => $refreshToken,
                'user' => [
                    'id' => $user['id'],
                    'alias' => $user['alias'],
                    'uuid' => $user['uuid']
                ]
            ]);
        } else {
            Response::json(401, "Kullanıcı bulunamadı veya şifre hatalı.");
        }
    }

    public function refreshToken() {
        $data = json_decode(file_get_contents("php://input"));
        
        if (!isset($data->refresh_token)) {
            Response::json(400, "Refresh token eksik.");
            exit;
        }

        $refreshToken = $data->refresh_token;
        $payload = JwtHandler::decode($refreshToken);

        if (!$payload || isset($payload['is_expired']) && $payload['is_expired'] === true || !isset($payload['type']) || $payload['type'] !== 'refresh') {
            Response::json(401, "Geçersiz veya süresi dolmuş refresh token.");
            exit;
        }

        $user_id = $payload['user_id'];

        // Token'ın veritabanında (veya geçerli bir sistemde) olup olmadığını kontrol et
        $stmt = $this->db->prepare("SELECT refresh_token, alias, uuid FROM users WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $user_id]);
        $user = $stmt->fetch();

        if (!$user || $user['refresh_token'] !== $refreshToken) {
            Response::json(401, "Geçersiz refresh token (Revoke edilmiş).");
            exit;
        }

        // Yeni Access Token oluştur
        $newPayload = [
            'user_id' => $user_id,
            'uuid' => $user['uuid'],
            'alias' => $user['alias'],
            'exp' => time() + (60 * 60 * 24 * 30) // 30 Gün
        ];
        
        $newToken = JwtHandler::encode($newPayload);

        Response::json(200, "Token yenilendi.", [
            'token' => $newToken
        ]);
    }

    private function saveRefreshToken($userId, $token) {
        // Bu işlem için veritabanında refresh_token sütunu olması gerekiyor.
        try {
            $stmt = $this->db->prepare("UPDATE users SET refresh_token = :token WHERE id = :id");
            $stmt->execute([':token' => $token, ':id' => $userId]);
        } catch (Exception $e) {
            // Loglanabilir
        }
    }
}
?>