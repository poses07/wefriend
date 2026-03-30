<?php
require_once __DIR__ . '/api/config/Database.php';

$db = (new Database())->getConnection();

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS user_blocks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            blocker_id INT NOT NULL,
            blocked_id INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_block (blocker_id, blocked_id)
        );
    ");
    
    $db->exec("
        CREATE TABLE IF NOT EXISTS user_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            reporter_id INT NOT NULL,
            reported_id INT NOT NULL,
            reason VARCHAR(255) NOT NULL,
            details TEXT,
            status ENUM('pending', 'reviewed', 'resolved') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");

    echo "Tables created successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
