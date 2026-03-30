<?php

require_once __DIR__ . '/config/Database.php';

$db = (new Database())->getConnection();

$sql = "
CREATE TABLE IF NOT EXISTS quests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description VARCHAR(255) NOT NULL,
    reward_xp INT DEFAULT 0,
    target_count INT DEFAULT 1,
    icon_name VARCHAR(50) DEFAULT 'star',
    color_hex VARCHAR(20) DEFAULT '#FFA500',
    quest_type ENUM('daily', 'weekly', 'monthly') DEFAULT 'daily',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_quests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    quest_id INT NOT NULL,
    progress INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (quest_id) REFERENCES quests(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_quest (user_id, quest_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
";

try {
    $db->exec($sql);
    echo "Quests tables created successfully.\n";

    // Insert some default quests if table is empty
    $stmt = $db->query("SELECT COUNT(*) FROM quests");
    if ($stmt->fetchColumn() == 0) {
        $insert = "INSERT INTO quests (title, description, reward_xp, target_count, icon_name, color_hex, quest_type) VALUES 
        ('Sosyalleşme Vakti', '5 farklı kişiyle sohbet et.', 50, 5, 'chat_bubble_rounded', '#2196F3', 'daily'),
        ('Keşifçi', 'Keşfet bölümünde 20 kişiyi beğen.', 100, 20, 'explore_rounded', '#FF9800', 'daily'),
        ('Aktif Üye', 'Uygulamada zaman geçir.', 40, 1, 'timer_rounded', '#009688', 'daily'),
        ('Haftanın Yıldızı', 'Hafta boyunca 100 mesaj gönder.', 300, 100, 'star_rounded', '#9C27B0', 'weekly'),
        ('Efsanevi Başlangıç', 'Aylık 1000 XP topla.', 1000, 1000, 'diamond_rounded', '#E91E63', 'monthly');";
        $db->exec($insert);
        echo "Default quests inserted.\n";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
