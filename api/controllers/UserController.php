<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../utils/JwtHandler.php';
require_once __DIR__ . '/../core/Response.php';

class UserController {
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    // Ortak metod: Gelen istekteki Authorization header'ından token'ı okur ve doğrular
    private function authenticate() {
        $headers = null;
        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER["Authorization"]);
        }
        else if (isset($_SERVER['HTTP_AUTHORIZATION'])) { // Nginx or fast CGI
            $headers = trim($_SERVER["HTTP_AUTHORIZATION"]);
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            // Server-side fix for header name casing
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

        // Token geçerli ama kullanıcı veritabanında var mı? (Admin silmiş olabilir)
        $stmt = $this->db->prepare("SELECT id FROM users WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $user_id]);
        
        if ($stmt->rowCount() == 0) {
            Response::json(401, "Kullanıcı bulunamadı. Lütfen tekrar giriş yapın.");
            exit();
        }

        return $user_id;
    }

    // Profil bilgilerini getirir
    public function getProfile() {
        $user_id = $this->authenticate();
        $target_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : $user_id;

        $query = "SELECT id, uuid, alias, avatar_url, bio, age, gender, city, rank_level, xp_points, coins, interests, height, weight, zodiac_sign, created_at FROM users WHERE id = :id LIMIT 1";
        $stmt = $this->db->prepare($query);
        $stmt->execute([':id' => $target_id]);

        if ($stmt->rowCount() == 0) {
            Response::json(404, "Kullanıcı bulunamadı.");
            exit;
        }

        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Kendi profilimiz değilse, profil ziyareti kaydet
        if ($target_id !== $user_id) {
            try {
                $viewStmt = $this->db->prepare("
                    INSERT INTO profile_views (viewer_id, viewed_id, viewed_at) 
                    VALUES (:viewer, :viewed, NOW())
                    ON DUPLICATE KEY UPDATE viewed_at = NOW()
                ");
                $viewStmt->execute([':viewer' => $user_id, ':viewed' => $target_id]);
            } catch (Exception $e) {
                // Log the error silently
            }
        }

        // Kullanıcının kazandığı rozetleri (badges) çek
        $badgeQuery = "
            SELECT b.name, b.description, b.icon_name, b.color_hex, ub.earned_at 
            FROM user_badges ub 
            JOIN badges b ON ub.badge_id = b.id 
            WHERE ub.user_id = :id
        ";
        $badgeStmt = $this->db->prepare($badgeQuery);
        $badgeStmt->execute([':id' => $target_id]);
        
        $badges = [];
        if ($badgeStmt->rowCount() > 0) {
            $badges = $badgeStmt->fetchAll(PDO::FETCH_ASSOC);
        }
        $user['badges'] = $badges;

        // Şimdilik varsayılan istatistikler ekleyelim
        // Eğer kendi profiliysek gerçek ziyaretçi sayısını göster
        $viewsCount = 0;
        if ($target_id === $user_id) {
            $viewsStmt = $this->db->prepare("SELECT COUNT(*) FROM profile_views WHERE viewed_id = :id");
            $viewsStmt->execute([':id' => $user_id]);
            $viewsCount = (int)$viewsStmt->fetchColumn();
        }

        $user['stats'] = [
            'views' => $viewsCount,
            'likes' => 0
        ];

        Response::json(200, "Profil başarıyla getirildi.", $user);
    }

    // Profil bilgilerini günceller (Onboarding veya Edit Profile)
    public function updateProfile() {
        $user_id = $this->authenticate();
        
        // Form-data (fotoğraf dahil) gelebileceği için $_POST kullanıyoruz
        // Eğer JSON gelirse file_get_contents kullanılabilir ama resim işin içine girince multipart/form-data şart.
        $alias = isset($_POST['alias']) ? htmlspecialchars(strip_tags($_POST['alias'])) : null;
        $bio = isset($_POST['bio']) ? htmlspecialchars(strip_tags($_POST['bio'])) : null;
        $age = isset($_POST['age']) ? (int)$_POST['age'] : null;
        $gender = isset($_POST['gender']) ? htmlspecialchars(strip_tags($_POST['gender'])) : null;
        $city = isset($_POST['city']) ? htmlspecialchars(strip_tags($_POST['city'])) : null;
        $interests = isset($_POST['interests']) ? htmlspecialchars(strip_tags($_POST['interests'])) : null;
        $height = isset($_POST['height']) ? (int)$_POST['height'] : null;
        $weight = isset($_POST['weight']) ? (int)$_POST['weight'] : null;
        $zodiac_sign = isset($_POST['zodiac_sign']) ? htmlspecialchars(strip_tags($_POST['zodiac_sign'])) : null;
        
        // Avatar silme isteği var mı?
        $removeAvatar = isset($_POST['removeAvatar']) ? filter_var($_POST['removeAvatar'], FILTER_VALIDATE_BOOLEAN) : false;
        
        // JSON olarak gelme ihtimaline karşı fallback
        if (empty($_POST)) {
            $data = json_decode(file_get_contents("php://input"), true);
            if ($data) {
                $alias = isset($data['alias']) ? htmlspecialchars(strip_tags($data['alias'])) : $alias;
                $bio = isset($data['bio']) ? htmlspecialchars(strip_tags($data['bio'])) : $bio;
                $age = isset($data['age']) ? (int)$data['age'] : $age;
                $gender = isset($data['gender']) ? htmlspecialchars(strip_tags($data['gender'])) : $gender;
                $city = isset($data['city']) ? htmlspecialchars(strip_tags($data['city'])) : $city;
                $interests = isset($data['interests']) ? htmlspecialchars(strip_tags($data['interests'])) : $interests;
                $height = isset($data['height']) ? (int)$data['height'] : $height;
                $weight = isset($data['weight']) ? (int)$data['weight'] : $weight;
                $zodiac_sign = isset($data['zodiac_sign']) ? htmlspecialchars(strip_tags($data['zodiac_sign'])) : $zodiac_sign;
                $removeAvatar = isset($data['removeAvatar']) ? filter_var($data['removeAvatar'], FILTER_VALIDATE_BOOLEAN) : $removeAvatar;
            }
        }

        // Avatar Yükleme İşlemi (Eğer dosya gönderilmişse)
        $avatar_url = null;
        if (isset($_FILES['avatar']) && $_FILES['avatar']['error'] === UPLOAD_ERR_OK) {
            // Sunucudaki ana dizine uploads klasörü oluştur (controllers'tan bir üst dizin)
            $uploadDir = __DIR__ . '/../uploads/avatars/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }

            $fileExt = pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION);
            $fileName = "user_" . $user_id . "_" . time() . "." . $fileExt;
            $uploadFilePath = $uploadDir . $fileName;

            if (move_uploaded_file($_FILES['avatar']['tmp_name'], $uploadFilePath)) {
                // Veritabanına kaydedilecek URL (Proje yoluna göre ayarlanmalı)
                // Şimdilik localhost/wefriend/uploads/avatars/.. şeklinde dönecek
                $avatar_url = "https://operasyon.milatsoft.com/uploads/avatars/" . $fileName;
            }
        }

        // Dinamik Update Sorgusu Oluşturma
        $updateFields = [];
        $params = [':id' => $user_id];

        if ($alias !== null && $alias !== '') { 
            // Yeni takma ad alınmış mı kontrol et
            $checkStmt = $this->db->prepare("SELECT id FROM users WHERE alias = :alias AND id != :id LIMIT 1");
            $checkStmt->execute([':alias' => $alias, ':id' => $user_id]);
            if ($checkStmt->rowCount() > 0) {
                Response::json(409, "Bu takma ad (alias) zaten başkası tarafından kullanılıyor.");
                exit;
            }
            $updateFields[] = "alias = :alias"; 
            $params[':alias'] = $alias; 
        }
        if ($bio !== null) { $updateFields[] = "bio = :bio"; $params[':bio'] = $bio; }
        if ($age !== null) { $updateFields[] = "age = :age"; $params[':age'] = $age; }
        if ($gender !== null) { 
            // Sadece belirli değerlere izin ver
            $genderMap = ['Erkek' => 'Male', 'Kadın' => 'Female'];
            $mappedGender = isset($genderMap[$gender]) ? $genderMap[$gender] : 'Other';
            $updateFields[] = "gender = :gender"; 
            $params[':gender'] = $mappedGender; 
        }
        if ($city !== null) { $updateFields[] = "city = :city"; $params[':city'] = $city; }
        if ($interests !== null) { $updateFields[] = "interests = :interests"; $params[':interests'] = $interests; }
        if ($height !== null) { $updateFields[] = "height = :height"; $params[':height'] = $height; }
        if ($weight !== null) { $updateFields[] = "weight = :weight"; $params[':weight'] = $weight; }
        if ($zodiac_sign !== null) { $updateFields[] = "zodiac_sign = :zodiac_sign"; $params[':zodiac_sign'] = $zodiac_sign; }
        
        if ($avatar_url !== null) { 
            $updateFields[] = "avatar_url = :avatar_url"; 
            $params[':avatar_url'] = $avatar_url; 
        } elseif ($removeAvatar) {
            // Eğer yeni bir fotoğraf yüklenmediyse VE kullanıcı mevcut fotoğrafı sildiyse
            $updateFields[] = "avatar_url = NULL";
        }

        if (empty($updateFields)) {
            Response::json(400, "Güncellenecek veri bulunamadı.");
        }

        $query = "UPDATE users SET " . implode(", ", $updateFields) . " WHERE id = :id";
        $stmt = $this->db->prepare($query);

        try {
            $stmt->execute($params);
            Response::json(200, "Profil başarıyla güncellendi.");
        } catch (PDOException $e) {
            Response::json(500, "Profil güncellenirken bir hata oluştu: " . $e->getMessage());
        }
    }
    // Ana sayfa için diğer kullanıcıları getir
    public function getFeed() {
        $user_id = $this->authenticate();

        // Update own last_active implicitly by just doing a quick query
        $this->db->prepare("UPDATE users SET last_active = CURRENT_TIMESTAMP WHERE id = :id")->execute([':id' => $user_id]);

        $gender = isset($_GET['gender']) ? $_GET['gender'] : null;
        $city = isset($_GET['city']) ? $_GET['city'] : null;
        $online = isset($_GET['online']) ? filter_var($_GET['online'], FILTER_VALIDATE_BOOLEAN) : false;

        $query = "
            SELECT u.id, u.alias, u.avatar_url, u.rank_level, u.age, u.city, u.interests, u.zodiac_sign,
            IF(u.last_active >= NOW() - INTERVAL 5 MINUTE, 1, 0) as is_online,
            IF(pb.id IS NOT NULL, 1, 0) as is_boosted
            FROM users u
            LEFT JOIN profile_boosts pb ON u.id = pb.user_id AND pb.expires_at > NOW()
            WHERE u.id != :id1 
            AND u.id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = :id2)
            AND u.id NOT IN (SELECT blocker_id FROM user_blocks WHERE blocked_id = :id3)
        ";
        
        $params = [
            ':id1' => $user_id,
            ':id2' => $user_id,
            ':id3' => $user_id,
        ];

        if ($gender) {
            $query .= " AND gender = :gender";
            $params[':gender'] = $gender;
        }

        if ($city) {
            $query .= " AND city LIKE :city";
            $params[':city'] = '%' . $city . '%';
        }

        if ($online) {
            $query .= " AND u.last_active >= NOW() - INTERVAL 5 MINUTE";
        }

        // Öne çıkan profiller (boosted) en üstte görünsün
        $query .= " ORDER BY is_boosted DESC, u.id DESC LIMIT 50";

        $stmt = $this->db->prepare($query);
        $stmt->execute($params);

        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json(200, "Akış başarıyla getirildi.", $users);
    }

    public function blockUser() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['blocked_id'])) {
            Response::json(400, "Engellenecek kullanıcı ID eksik.");
            exit;
        }
        
        $blocked_id = $data['blocked_id'];
        
        if ($user_id == $blocked_id) {
            Response::json(400, "Kendinizi engelleyemezsiniz.");
            exit;
        }

        try {
            $stmt = $this->db->prepare("INSERT IGNORE INTO user_blocks (blocker_id, blocked_id) VALUES (:blocker, :blocked)");
            $stmt->execute([':blocker' => $user_id, ':blocked' => $blocked_id]);
            Response::json(200, "Kullanıcı engellendi.");
        } catch (PDOException $e) {
            Response::json(500, "Hata oluştu.");
        }
    }

    public function reportUser() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['reported_id']) || !isset($data['reason'])) {
            Response::json(400, "Eksik bilgi.");
            exit;
        }

        try {
            $stmt = $this->db->prepare("INSERT INTO user_reports (reporter_id, reported_id, reason, details) VALUES (:reporter, :reported, :reason, :details)");
            $stmt->execute([
                ':reporter' => $user_id,
                ':reported' => $data['reported_id'],
                ':reason' => $data['reason'],
                ':details' => $data['details'] ?? null
            ]);
            Response::json(200, "Şikayetiniz alındı.");
        } catch (PDOException $e) {
            Response::json(500, "Hata oluştu.");
        }
    }

    public function getBlockedUsers() {
        $user_id = $this->authenticate();

        $query = "
            SELECT u.id, u.alias, u.avatar_url 
            FROM user_blocks ub
            JOIN users u ON u.id = ub.blocked_id
            WHERE ub.blocker_id = :user_id
        ";
        
        $stmt = $this->db->prepare($query);
        $stmt->execute([':user_id' => $user_id]);
        $blockedUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json(200, "Engellenen kullanıcılar getirildi.", $blockedUsers);
    }

    public function unblockUser() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['blocked_id'])) {
            Response::json(400, "Kullanıcı ID eksik.");
            exit;
        }

        $stmt = $this->db->prepare("DELETE FROM user_blocks WHERE blocker_id = :blocker AND blocked_id = :blocked");
        $stmt->execute([
            ':blocker' => $user_id,
            ':blocked' => $data['blocked_id']
        ]);

        Response::json(200, "Engel kaldırıldı.");
    }

    public function updateFcmToken() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (isset($data['token'])) {
            $stmt = $this->db->prepare("UPDATE users SET fcm_token = :token WHERE id = :id");
            $stmt->execute([':token' => $data['token'], ':id' => $user_id]);
            Response::json(200, "FCM Token güncellendi.");
        } else {
            Response::json(400, "Token eksik.");
        }
    }
    public function getQuests() {
        $user_id = $this->authenticate();

        // Tüm görevleri ve kullanıcının bu görevlerdeki ilerlemesini getir
        $query = "
            SELECT q.id, q.title, q.description, q.reward_xp, q.target_count, q.icon_name, q.color_hex, q.quest_type,
                   COALESCE(uq.progress, 0) as progress, 
                   COALESCE(uq.is_completed, 0) as is_completed
            FROM quests q
            LEFT JOIN user_quests uq ON q.id = uq.quest_id AND uq.user_id = :user_id
        ";
        
        $stmt = $this->db->prepare($query);
        $stmt->execute([':user_id' => $user_id]);
        $allQuests = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Görevleri kategorilerine göre ayır
        $questsData = [
            'daily' => [],
            'weekly' => [],
            'monthly' => []
        ];

        foreach ($allQuests as $quest) {
            $type = $quest['quest_type'];
            // UI'ın beklediği formatta sayısal değerleri cast et
            $quest['reward_xp'] = (int)$quest['reward_xp'];
            $quest['target_count'] = (int)$quest['target_count'];
            $quest['progress'] = (int)$quest['progress'];
            $quest['is_completed'] = (bool)$quest['is_completed'];
            
            if (isset($questsData[$type])) {
                $questsData[$type][] = $quest;
            }
        }

        Response::json(200, "Görevler başarıyla getirildi.", $questsData);
    }

    // Profil ziyaretçilerini getirir (Sadece kendi profilimize bakanlar)
    public function getProfileVisitors() {
        $user_id = $this->authenticate();

        $query = "
            SELECT v.id as view_id, v.viewed_at, u.id as visitor_id, u.alias, u.avatar_url, u.gender, u.city, u.rank_level
            FROM profile_views v
            JOIN users u ON v.viewer_id = u.id
            WHERE v.viewed_id = :user_id
            ORDER BY v.viewed_at DESC
            LIMIT 50
        ";

        $stmt = $this->db->prepare($query);
        $stmt->execute([':user_id' => $user_id]);
        $visitors = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Kullanıcı VIP değilse, avatar_url'leri blur efekti için gizleyebiliriz veya front-end'de blur yapabiliriz.
        // Biz veriyi gönderelim, flutter tarafında blurlayalım ki VIP al diyelim.
        
        Response::json(200, "Ziyaretçiler getirildi.", $visitors);
    }
    // Kullanıcının profilini öne çıkarır (Boost)
    // Sadece bir tane boostProfile fonksiyonu olmalı
    public function boostProfile() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);

        // Paket seçimine göre jeton ve süre ayarla
        $package = isset($data['package']) ? $data['package'] : '1_hour';
        
        $cost = 0;
        $duration = '';

        if ($package == '1_hour') {
            $cost = 100;
            $duration = '+1 hour';
        } else if ($package == '24_hours') {
            $cost = 1500;
            $duration = '+24 hours';
        } else {
            Response::json(400, "Geçersiz paket seçimi.");
            exit;
        }

        try {
            $this->db->beginTransaction();

            // Kullanıcının yeterli jetonu var mı kontrol et
            $stmt = $this->db->prepare("SELECT coins FROM users WHERE id = :id FOR UPDATE");
            $stmt->execute([':id' => $user_id]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$user || $user['coins'] < $cost) {
                $this->db->rollBack();
                Response::json(400, "Yetersiz jeton.");
                exit;
            }

            // Jetonu düş
            $this->db->prepare("UPDATE users SET coins = coins - :cost WHERE id = :id")->execute([
                ':cost' => $cost,
                ':id' => $user_id
            ]);

            // Boost ekle veya süresini uzat
            $expires_at = date('Y-m-d H:i:s', strtotime($duration));
            $this->db->prepare("
                INSERT INTO profile_boosts (user_id, expires_at) 
                VALUES (:user_id, :expires_at)
                ON DUPLICATE KEY UPDATE expires_at = :expires_at_update
            ")->execute([
                ':user_id' => $user_id,
                ':expires_at' => $expires_at,
                ':expires_at_update' => $expires_at
            ]);

            $this->db->commit();
            Response::json(200, "Profiliniz başarıyla öne çıkarıldı!");
        } catch (Exception $e) {
            $this->db->rollBack();
            Response::json(500, "Hata oluştu.");
        }
    }

    public function likeUser() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);

        if (!isset($data['target_id'])) {
            Response::json(400, "Eksik bilgi.");
            exit;
        }

        $target_id = (int)$data['target_id'];
        $is_super_like = isset($data['is_super_like']) ? filter_var($data['is_super_like'], FILTER_VALIDATE_BOOLEAN) : false;

        if ($user_id == $target_id) {
            Response::json(400, "Kendinizi beğenemezsiniz.");
            exit;
        }

        try {
            $this->db->beginTransaction();

            // Eğer süper beğeni ise 50 jeton kes
            if ($is_super_like) {
                $stmt = $this->db->prepare("SELECT coins FROM users WHERE id = :id FOR UPDATE");
                $stmt->execute([':id' => $user_id]);
                $user = $stmt->fetch(PDO::FETCH_ASSOC);

                if (!$user || $user['coins'] < 50) {
                    $this->db->rollBack();
                    Response::json(400, "Süper beğeni için yeterli jetonunuz yok (50 Jeton gerekli).");
                    exit;
                }

                $this->db->prepare("UPDATE users SET coins = coins - 50 WHERE id = :id")->execute([':id' => $user_id]);
                
                // Fcm bildirimi gönder (Super Like)
                require_once __DIR__ . '/../utils/FcmHelper.php';
                FcmHelper::sendToUser($this->db, $target_id, "Süper Beğeni! 🌟", "Biri sana Süper Beğeni gönderdi! Kim olduğunu öğrenmek için tıkla.");
            }

            // Tabloyu oluştur (eğer yoksa)
            $this->db->exec("CREATE TABLE IF NOT EXISTS user_likes (
                id INT AUTO_INCREMENT PRIMARY KEY, 
                liker_id INT, 
                liked_id INT, 
                is_super_like BOOLEAN DEFAULT FALSE, 
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
                UNIQUE KEY(liker_id, liked_id)
            )");

            $stmt = $this->db->prepare("
                INSERT INTO user_likes (liker_id, liked_id, is_super_like) 
                VALUES (:liker, :liked, :super)
                ON DUPLICATE KEY UPDATE is_super_like = GREATEST(is_super_like, :super2)
            ");
            $stmt->execute([
                ':liker' => $user_id,
                ':liked' => $target_id,
                ':super' => $is_super_like ? 1 : 0,
                ':super2' => $is_super_like ? 1 : 0
            ]);

            // Eşleşme (Match) Kontrolü
            $matchCheck = $this->db->prepare("SELECT id FROM user_likes WHERE liker_id = :target AND liked_id = :me");
            $matchCheck->execute([':target' => $target_id, ':me' => $user_id]);
            
            $is_match = false;
            if ($matchCheck->rowCount() > 0) {
                $is_match = true;
                // İki tarafa da bildirim atılabilir
                require_once __DIR__ . '/../utils/FcmHelper.php';
                FcmHelper::sendToUser($this->db, $target_id, "Yeni Eşleşme! 💖", "Biriyle eşleştin! Hemen sohbete başla.");
            }

            $this->db->commit();
            
            Response::json(200, "Beğeni gönderildi.", ['is_match' => $is_match, 'is_super_like' => $is_super_like]);
        } catch (Exception $e) {
            $this->db->rollBack();
            Response::json(500, "Hata oluştu: " . $e->getMessage());
        }
    }
}
?>