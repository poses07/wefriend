<?php
require 'api/config/Database.php';
$db = (new Database())->getConnection();

$db->exec("
CREATE TABLE IF NOT EXISTS `quests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text,
  `quest_type` enum('daily','weekly','monthly') DEFAULT 'daily',
  `action_type` varchar(50) NOT NULL,
  `target_count` int(11) NOT NULL DEFAULT 1,
  `reward_xp` int(11) NOT NULL DEFAULT 0,
  `reward_coins` int(11) NOT NULL DEFAULT 0,
  `icon_name` varchar(50) DEFAULT 'star_rounded',
  `color_hex` varchar(10) DEFAULT '#FFD700',
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user_quests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `quest_id` int(11) NOT NULL,
  `progress` int(11) DEFAULT 0,
  `is_completed` tinyint(1) DEFAULT 0,
  `is_claimed` tinyint(1) DEFAULT 0,
  `completed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
");

$stmt = $db->query("SELECT count(*) FROM quests");
if ($stmt->fetchColumn() == 0) {
    $db->exec("
    INSERT INTO quests (title, description, quest_type, action_type, target_count, reward_xp, reward_coins, icon_name, color_hex) VALUES
    ('Giriş Yap', 'Uygulamaya her gün giriş yap', 'daily', 'login', 1, 50, 5, 'timer_rounded', '#4CAF50'),
    ('Mesaj Gönder', '3 farklı kişiye mesaj gönder', 'daily', 'send_message', 3, 100, 10, 'chat_bubble_rounded', '#2196F3'),
    ('Hikaye Paylaş', '1 adet hikaye paylaş', 'daily', 'post_story', 1, 150, 15, 'camera_alt_rounded', '#9C27B0'),
    ('Haftalık Giriş', 'Haftada 5 gün giriş yap', 'weekly', 'login_weekly', 5, 500, 50, 'timer_rounded', '#FF9800'),
    ('Sohbet Kuşu', 'Haftada 20 mesaj gönder', 'weekly', 'send_message', 20, 800, 100, 'chat_bubble_rounded', '#F44336'),
    ('Aylık VIP', 'Bu ay boyunca aktif ol', 'monthly', 'active_monthly', 1, 2000, 500, 'diamond_rounded', '#E91E63');
    ");
}

echo "Quests tables created and populated.\n";
?>