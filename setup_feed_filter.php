<?php
require_once __DIR__ . '/api/config/Database.php';

$db = (new Database())->getConnection();

try {
    $db->exec("ALTER TABLE users ADD COLUMN last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
    echo "Column last_active added successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
