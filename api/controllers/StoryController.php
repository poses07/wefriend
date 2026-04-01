<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../utils/JwtHandler.php';
require_once __DIR__ . '/../core/Response.php';

class StoryController {
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
        return $user_id;
    }

    public function getStories() {
        $user_id = $this->authenticate();

        // Önce süresi dolmuş hikayeleri veritabanından ve sunucudan temizleyelim (Cron yerine istek bazlı otomatik temizlik)
        $this->cleanupExpiredStories();

        $query = "
            SELECT s.id as story_id, s.media_url, s.created_at, s.expires_at, s.views_count,
                   u.id as user_id, u.alias, u.avatar_url, u.rank_level
            FROM stories s
            JOIN users u ON s.user_id = u.id
            WHERE s.expires_at > NOW()
            AND u.id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = :user_id1)
            AND u.id NOT IN (SELECT blocker_id FROM user_blocks WHERE blocked_id = :user_id2)
            ORDER BY s.created_at DESC
        ";

        $stmt = $this->db->prepare($query);
        $stmt->execute([':user_id1' => $user_id, ':user_id2' => $user_id]);
        $stories = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Hikayeleri kullanıcılara göre grupla
        $groupedStories = [];
        foreach ($stories as $story) {
            $u_id = $story['user_id'];
            if (!isset($groupedStories[$u_id])) {
                $groupedStories[$u_id] = [
                    'user_id' => $u_id,
                    'alias' => $story['alias'],
                    'avatar_url' => $story['avatar_url'],
                    'rank_level' => $story['rank_level'],
                    'is_me' => ($u_id == $user_id),
                    'stories' => []
                ];
            }
            $groupedStories[$u_id]['stories'][] = [
                'id' => $story['story_id'],
                'media_url' => $story['media_url'],
                'created_at' => $story['created_at'],
                'views_count' => $story['views_count'] ?? 0
            ];
        }

        // is_me (kendi hikayemiz) her zaman en başta olsun
        usort($groupedStories, function($a, $b) {
            if ($a['is_me']) return -1;
            if ($b['is_me']) return 1;
            // Kendi hikayemiz değilse, en son eklenen hikayeye göre sırala
            $lastStoryA = end($a['stories'])['created_at'];
            $lastStoryB = end($b['stories'])['created_at'];
            return strtotime($lastStoryB) - strtotime($lastStoryA);
        });

        Response::json(200, "Hikayeler getirildi.", array_values($groupedStories));
    }

    private function cleanupExpiredStories() {
        try {
            // Süresi dolmuş hikayeleri bul
            $stmt = $this->db->query("SELECT id, media_url FROM stories WHERE expires_at <= NOW()");
            $expiredStories = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if (count($expiredStories) > 0) {
                foreach ($expiredStories as $story) {
                    $media_url = $story['media_url'];
                    $fileName = basename($media_url);
                    $filePath = __DIR__ . '/../uploads/stories/' . $fileName;
                    
                    // Sunucudan dosyayı sil
                    if (file_exists($filePath)) {
                        unlink($filePath);
                    }
                    
                    // Views tablosundan sil
                    $this->db->prepare("DELETE FROM story_views WHERE story_id = :story_id")->execute([':story_id' => $story['id']]);
                }
                
                // Hikayeleri veritabanından topluca sil
                $this->db->query("DELETE FROM stories WHERE expires_at <= NOW()");
            }
        } catch (Exception $e) {
            // Hata olursa sessizce devam et, akışı bozma
        }
    }

    public function addStory() {
        $user_id = $this->authenticate();

        if (!isset($_FILES['media']) || $_FILES['media']['error'] !== UPLOAD_ERR_OK) {
            Response::json(400, "Dosya yüklenemedi.");
            exit();
        }

        // Sunucudaki ana dizine uploads klasörü oluştur (controllers'tan bir üst dizin)
        $uploadDir = __DIR__ . '/../uploads/stories/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $fileExt = pathinfo($_FILES['media']['name'], PATHINFO_EXTENSION);
        $fileName = "story_" . $user_id . "_" . time() . "." . $fileExt;
        $uploadFilePath = $uploadDir . $fileName;

        if (move_uploaded_file($_FILES['media']['tmp_name'], $uploadFilePath)) {
            // HTTPS bağlantı olduğundan emin olalım
            $media_url = "https://operasyon.milatsoft.com/uploads/stories/" . $fileName;
            
            // 24 saat geçerlilik süresi
            $expires_at = date('Y-m-d H:i:s', strtotime('+24 hours'));

            $stmt = $this->db->prepare("INSERT INTO stories (user_id, media_url, expires_at) VALUES (:user_id, :media_url, :expires_at)");
            $stmt->execute([
                ':user_id' => $user_id,
                ':media_url' => $media_url,
                ':expires_at' => $expires_at
            ]);

            // Görev ilerlemesini tetikle (1 hikaye paylaştı)
            require_once __DIR__ . '/QuestController.php';
            QuestController::incrementProgress($this->db, $user_id, 'post_story', 1);

            Response::json(200, "Hikaye başarıyla eklendi.", ['url' => $media_url]);
        } else {
            Response::json(500, "Medya kaydedilemedi.");
        }
    }

    public function viewStory() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $story_id = isset($data['story_id']) ? (int)$data['story_id'] : 0;

        if ($story_id > 0) {
            try {
                $stmt = $this->db->prepare("INSERT IGNORE INTO story_views (story_id, viewer_id) VALUES (:story_id, :viewer_id)");
                $stmt->execute([':story_id' => $story_id, ':viewer_id' => $user_id]);
                
                if ($stmt->rowCount() > 0) {
                    $this->db->prepare("UPDATE stories SET views_count = views_count + 1 WHERE id = :story_id")->execute([':story_id' => $story_id]);
                }
                Response::json(200, "Görüntüleme kaydedildi.");
            } catch (Exception $e) {
                Response::json(500, "Hata oluştu.");
            }
        } else {
            Response::json(400, "Geçersiz hikaye ID'si.");
        }
    }

    public function getStoryViewers() {
        $user_id = $this->authenticate();
        $story_id = isset($_GET['story_id']) ? (int)$_GET['story_id'] : 0;

        if ($story_id <= 0) {
            Response::json(400, "Geçersiz hikaye ID'si.");
            exit();
        }

        // Kendi hikayesi mi kontrol et
        $stmt = $this->db->prepare("SELECT user_id FROM stories WHERE id = :story_id");
        $stmt->execute([':story_id' => $story_id]);
        $story = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$story || $story['user_id'] != $user_id) {
            Response::json(403, "Bu hikayenin görüntüleyenlerini göremezsiniz.");
            exit();
        }

        $query = "
            SELECT u.id, u.alias, u.avatar_url, u.rank_level, sv.viewed_at
            FROM story_views sv
            JOIN users u ON sv.viewer_id = u.id
            WHERE sv.story_id = :story_id
            ORDER BY sv.viewed_at DESC
        ";
        $stmt = $this->db->prepare($query);
        $stmt->execute([':story_id' => $story_id]);
        $viewers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json(200, "Görüntüleyenler getirildi.", $viewers);
    }

    public function deleteStory() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        $story_id = isset($data['story_id']) ? (int)$data['story_id'] : 0;

        if ($story_id <= 0) {
            Response::json(400, "Geçersiz hikaye ID'si.");
            exit();
        }

        // Kendi hikayesi mi?
        $stmt = $this->db->prepare("SELECT id, media_url FROM stories WHERE id = :story_id AND user_id = :user_id");
        $stmt->execute([':story_id' => $story_id, ':user_id' => $user_id]);
        $story = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$story) {
            Response::json(403, "Hikaye bulunamadı veya silme yetkiniz yok.");
            exit();
        }

        // Dosyayı sunucudan sil (opsiyonel)
        $media_url = $story['media_url'];
        $fileName = basename($media_url);
        $filePath = __DIR__ . '/../uploads/stories/' . $fileName;
        if (file_exists($filePath)) {
            unlink($filePath);
        }

        // Veritabanından sil
        $this->db->prepare("DELETE FROM story_views WHERE story_id = :story_id")->execute([':story_id' => $story_id]);
        $this->db->prepare("DELETE FROM stories WHERE id = :story_id")->execute([':story_id' => $story_id]);

        Response::json(200, "Hikaye başarıyla silindi.");
    }
}
?>