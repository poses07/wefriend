<?php
require_once __DIR__ . '/api/config/Database.php';
$db = (new Database())->getConnection();
$stmt = $db->query('SELECT id, alias FROM users');
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Total users: " . count($users) . "\n";
foreach($users as $u) {
    echo $u['id'] . " - " . $u['alias'] . "\n";
}
