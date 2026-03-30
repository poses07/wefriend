<?php
require_once __DIR__ . '/api/config/Database.php';

$db = (new Database())->getConnection();

try {
    $db->exec("ALTER TABLE messages ADD COLUMN message_type ENUM('text', 'image') DEFAULT 'text' AFTER content");
    echo "Column message_type added successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
