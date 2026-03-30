<?php
require_once __DIR__ . '/api/config/Database.php';
$db = (new Database())->getConnection();
$user_id = 1; // Pose
$query = "
    SELECT id, alias, gender, city
    FROM users 
    WHERE id != :id 
    AND id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = :id)
    AND id NOT IN (SELECT blocker_id FROM user_blocks WHERE blocked_id = :id)
";
$stmt = $db->prepare($query);
$stmt->execute([':id' => $user_id]);
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Users visible to user 1:\n";
print_r($users);
