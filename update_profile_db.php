<?php
require 'api/config/Database.php';
$db = (new Database())->getConnection();
$stmt = $db->query('DESCRIBE users');
$columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
print_r($columns);

$db->exec("ALTER TABLE users ADD COLUMN interests VARCHAR(255) DEFAULT NULL;");
$db->exec("ALTER TABLE users ADD COLUMN height INT DEFAULT NULL;");
$db->exec("ALTER TABLE users ADD COLUMN weight INT DEFAULT NULL;");
$db->exec("ALTER TABLE users ADD COLUMN zodiac_sign VARCHAR(50) DEFAULT NULL;");

echo "\nColumns added successfully.\n";
?>