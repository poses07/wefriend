<?php
require 'api/config/Database.php';
$db = (new Database())->getConnection();

try {
    $db->exec("ALTER TABLE users ADD COLUMN is_admin TINYINT(1) DEFAULT 0;");
    echo "is_admin column added to users table.\n";
} catch (Exception $e) {
    echo "Column may already exist.\n";
}

$db->exec("UPDATE users SET is_admin = 1 ORDER BY id ASC LIMIT 1;");
echo "First user set as admin.\n";
?>