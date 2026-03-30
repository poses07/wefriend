<?php

require_once __DIR__ . '/../config/Database.php';

class QuestHelper {
    public static function incrementProgress($user_id, $quest_id, $amount = 1) {
        $db = (new Database())->getConnection();

        // Görevi bul
        $stmt = $db->prepare("SELECT target_count, reward_xp FROM quests WHERE id = :quest_id");
        $stmt->execute([':quest_id' => $quest_id]);
        $quest = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$quest) return false;

        $target = (int)$quest['target_count'];
        $reward = (int)$quest['reward_xp'];

        // Kullanıcının mevcut durumunu bul veya oluştur
        $stmt = $db->prepare("SELECT id, progress, is_completed FROM user_quests WHERE user_id = :user_id AND quest_id = :quest_id");
        $stmt->execute([':user_id' => $user_id, ':quest_id' => $quest_id]);
        $userQuest = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($userQuest) {
            if ($userQuest['is_completed']) {
                return true; // Zaten tamamlanmış
            }

            $newProgress = $userQuest['progress'] + $amount;
            $is_completed = $newProgress >= $target;

            $update = $db->prepare("UPDATE user_quests SET progress = :progress, is_completed = :is_completed, completed_at = IF(:is_completed_2, CURRENT_TIMESTAMP, NULL) WHERE id = :id");
            $update->execute([
                ':progress' => min($newProgress, $target),
                ':is_completed' => $is_completed ? 1 : 0,
                ':is_completed_2' => $is_completed ? 1 : 0,
                ':id' => $userQuest['id']
            ]);

            // Eğer yeni tamamlandıysa kullanıcıya XP ver
            if ($is_completed) {
                self::awardXp($user_id, $reward, $db);
            }
        } else {
            $newProgress = $amount;
            $is_completed = $newProgress >= $target;

            $insert = $db->prepare("INSERT INTO user_quests (user_id, quest_id, progress, is_completed, completed_at) VALUES (:user_id, :quest_id, :progress, :is_completed, IF(:is_completed_2, CURRENT_TIMESTAMP, NULL))");
            $insert->execute([
                ':user_id' => $user_id,
                ':quest_id' => $quest_id,
                ':progress' => min($newProgress, $target),
                ':is_completed' => $is_completed ? 1 : 0,
                ':is_completed_2' => $is_completed ? 1 : 0
            ]);

            if ($is_completed) {
                self::awardXp($user_id, $reward, $db);
            }
        }

        return true;
    }

    private static function awardXp($user_id, $amount, $db) {
        $stmt = $db->prepare("UPDATE users SET xp_points = xp_points + :amount WHERE id = :id");
        $stmt->execute([':amount' => $amount, ':id' => $user_id]);

        // XP'ye göre rank güncellemesi de yapılabilir
        self::checkRankUpgrade($user_id, $db);
    }

    private static function checkRankUpgrade($user_id, $db) {
        $stmt = $db->prepare("SELECT xp_points, rank_level FROM users WHERE id = :id");
        $stmt->execute([':id' => $user_id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) return;

        $xp = (int)$user['xp_points'];
        $currentRank = $user['rank_level'];
        $newRank = $currentRank;

        if ($xp >= 10000) {
            $newRank = 'legendary';
        } elseif ($xp >= 5000) {
            $newRank = 'popular';
        }

        if ($newRank !== $currentRank && $currentRank !== 'legendary') {
            $update = $db->prepare("UPDATE users SET rank_level = :rank WHERE id = :id");
            $update->execute([':rank' => $newRank, ':id' => $user_id]);
        }
    }
}
?>