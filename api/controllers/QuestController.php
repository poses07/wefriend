<?php
require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../core/Response.php';
require_once __DIR__ . '/../utils/JwtHandler.php';

class QuestController {
    private $db;

    public function __construct() {
        $this->db = (new Database())->getConnection();
    }

    private function authenticate() {
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

        return $decoded['user_id'];
    }

    // Görevleri listele ve eksik olanları oluştur
    public function getQuests() {
        $user_id = $this->authenticate();

        $response = ['daily' => [], 'weekly' => [], 'monthly' => []];

        try {
            // Aktif görevleri getir
            $stmt = $this->db->query("SELECT * FROM quests WHERE is_active = 1");
            $quests = $stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($quests as $q) {
                // Kullanıcının bu görevdeki durumunu kontrol et
                $stmt = $this->db->prepare("SELECT * FROM user_quests WHERE user_id = :u_id AND quest_id = :q_id ORDER BY created_at DESC LIMIT 1");
                $stmt->execute([':u_id' => $user_id, ':q_id' => $q['id']]);
                $user_quest = $stmt->fetch(PDO::FETCH_ASSOC);

                // Eğer kayıt yoksa, sıfırdan ekle
                if (!$user_quest) {
                    $stmt = $this->db->prepare("INSERT INTO user_quests (user_id, quest_id) VALUES (:u_id, :q_id)");
                    $stmt->execute([':u_id' => $user_id, ':q_id' => $q['id']]);
                    
                    $user_quest = [
                        'id' => $this->db->lastInsertId(),
                        'progress' => 0,
                        'is_completed' => 0,
                        'is_claimed' => 0
                    ];
                }

                $questData = [
                    'quest_id' => $q['id'],
                    'user_quest_id' => $user_quest['id'],
                    'title' => $q['title'],
                    'description' => $q['description'],
                    'target_count' => $q['target_count'],
                    'reward_xp' => $q['reward_xp'],
                    'reward_coins' => $q['reward_coins'],
                    'icon_name' => $q['icon_name'],
                    'color_hex' => $q['color_hex'],
                    'progress' => $user_quest['progress'],
                    'is_completed' => $user_quest['is_completed'],
                    'is_claimed' => $user_quest['is_claimed']
                ];

                $response[$q['quest_type']][] = $questData;
            }
        } catch (Exception $e) {
            // Tablo yoksa veya hata oluşursa boş response dön
        }

        Response::json(200, "Görevler getirildi.", $response);
    }

    // Ödül Al
    public function claimReward() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        $quest_id = $data['quest_id'] ?? 0;

        if ($quest_id == 0) {
            Response::json(400, "Geçersiz görev ID.");
            exit();
        }

        // Görevi ve kullanıcının durumunu kontrol et
        $stmt = $this->db->prepare("
            SELECT uq.id, uq.is_completed, uq.is_claimed, q.reward_xp, q.reward_coins, q.target_count, uq.progress
            FROM user_quests uq
            JOIN quests q ON uq.quest_id = q.id
            WHERE uq.user_id = :u_id AND uq.quest_id = :q_id
            ORDER BY uq.created_at DESC LIMIT 1
        ");
        $stmt->execute([':u_id' => $user_id, ':q_id' => $quest_id]);
        $quest = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$quest) {
            Response::json(404, "Görev bulunamadı.");
            exit();
        }

        if ($quest['is_claimed'] == 1) {
            Response::json(400, "Bu ödül zaten alınmış.");
            exit();
        }

        if ($quest['progress'] < $quest['target_count']) {
            Response::json(400, "Görev henüz tamamlanmamış.");
            exit();
        }

        try {
            $this->db->beginTransaction();

            // Ödülü alındı olarak işaretle
            $stmt = $this->db->prepare("UPDATE user_quests SET is_claimed = 1, is_completed = 1, completed_at = NOW() WHERE id = :uq_id");
            $stmt->execute([':uq_id' => $quest['id']]);

            // Kullanıcıya XP ve Coin ekle
            $stmt = $this->db->prepare("UPDATE users SET xp_points = xp_points + :xp, coins = coins + :coins WHERE id = :u_id");
            $stmt->execute([
                ':xp' => $quest['reward_xp'],
                ':coins' => $quest['reward_coins'],
                ':u_id' => $user_id
            ]);

            // Rank seviyesi kontrolü (Örn: XP'ye göre level artırma)
            $stmt = $this->db->prepare("SELECT xp_points, rank_level FROM users WHERE id = :u_id");
            $stmt->execute([':u_id' => $user_id]);
            $userData = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $newRank = 'newbie';
            if ($userData['xp_points'] >= 5000) $newRank = 'legendary';
            else if ($userData['xp_points'] >= 1000) $newRank = 'popular';
            
            if ($userData['rank_level'] !== $newRank) {
                $this->db->prepare("UPDATE users SET rank_level = :rank WHERE id = :u_id")
                         ->execute([':rank' => $newRank, ':u_id' => $user_id]);
            }

            $this->db->commit();
            Response::json(200, "Ödül başarıyla alındı.");

        } catch (Exception $e) {
            $this->db->rollBack();
            Response::json(500, "Ödül alınırken hata oluştu.");
        }
    }

    // Görev ilerlemesini artıran yardımcı metod (Diğer controller'lardan çağrılabilir)
    public static function incrementProgress($db, $user_id, $action_type, $amount = 1) {
        try {
            $stmt = $db->prepare("SELECT id, target_count FROM quests WHERE action_type = :action AND is_active = 1");
            $stmt->execute([':action' => $action_type]);
            $quests = $stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($quests as $q) {
                $q_id = $q['id'];
                $target = $q['target_count'];

                // Kullanıcının bu görevi var mı?
                $checkStmt = $db->prepare("SELECT id FROM user_quests WHERE user_id = :u_id AND quest_id = :q_id");
                $checkStmt->execute([':u_id' => $user_id, ':q_id' => $q_id]);
                if ($checkStmt->rowCount() == 0) {
                    $db->prepare("INSERT INTO user_quests (user_id, quest_id) VALUES (:u_id, :q_id)")
                       ->execute([':u_id' => $user_id, ':q_id' => $q_id]);
                }

                // İlerlemeyi artır
                $stmt = $db->prepare("
                    UPDATE user_quests 
                    SET progress = progress + :amount,
                        is_completed = IF(progress + :amount >= :target, 1, 0)
                    WHERE user_id = :u_id AND quest_id = :q_id AND is_completed = 0
                ");
                $stmt->execute([
                    ':amount' => $amount,
                    ':target' => $target,
                    ':u_id' => $user_id,
                    ':q_id' => $q_id
                ]);
            }
        } catch (Exception $e) {
            // Tablo yoksa veya hata olursa sessizce geç, ana akışı bozma
        }
    }
}
?>