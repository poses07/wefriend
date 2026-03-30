<?php
session_save_path(__DIR__ . '/../../api/sessions');
if (!is_dir(__DIR__ . '/../../api/sessions')) {
    mkdir(__DIR__ . '/../../api/sessions', 0777, true);
}
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header("Location: login.php");
    exit;
}

require_once __DIR__ . '/../../api/config/Database.php';
$db = (new Database())->getConnection();
?>