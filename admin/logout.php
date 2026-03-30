<?php
session_save_path(__DIR__ . '/../api/sessions');
if (!is_dir(__DIR__ . '/../api/sessions')) {
    mkdir(__DIR__ . '/../api/sessions', 0777, true);
}
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
$_SESSION = [];
session_destroy();
header("Location: login.php");
exit;
?>