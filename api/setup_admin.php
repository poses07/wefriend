<?php

require_once __DIR__ . '/config/Database.php';

$db = (new Database())->getConnection();

$sql = "
CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
";

try {
    $db->exec($sql);
    echo "Admins table created successfully.\n";

    // Insert default admin if table is empty
    $stmt = $db->query("SELECT COUNT(*) FROM admins");
    if ($stmt->fetchColumn() == 0) {
        $hash = password_hash('123456', PASSWORD_BCRYPT);
        $insert = $db->prepare("INSERT INTO admins (username, password_hash) VALUES (:username, :password_hash)");
        $insert->execute([':username' => 'admin', ':password_hash' => $hash]);
        echo "Default admin inserted. Username: admin, Password: 123456\n";
    } else {
        echo "Admin user already exists.\n";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
