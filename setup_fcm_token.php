<?php
require_once __DIR__ . '/api/config/Database.php';

$db = (new Database())->getConnection();

try {
    $db->exec("ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255) NULL");
    echo "Column fcm_token added successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
