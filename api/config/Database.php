<?php

require_once __DIR__ . '/../core/Response.php';

class Database {
    private $host = "localhost";
    private $db_name = "wefriend_db";
    private $username = "root";
    private $password = ""; // XAMPP varsayılan şifresi boştur
    public $conn;

    // Veritabanı bağlantısını al (Singleton yapısına uygun)
    public function getConnection() {
        $this->conn = null;

        try {
            // Sadece PDO kullanıyoruz. Güvenlik için en iyisi. Türkçe karakterler (emoji vb.) için utf8mb4 kullanıyoruz.
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4", $this->username, $this->password);
            
            // Hata modunu Exception (İstisna) olarak ayarla
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            // Emulated prepares kapatılır (SQL Injection'a karşı ekstra güvenlik)
            $this->conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            
            // Verilerin varsayılan olarak Associative Array (İlişkisel Dizi) dönmesini sağla
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        } catch(PDOException $exception) {
            // Gerçek projede (production) bu hatayı loglara yazarız, ekrana basmayız.
            Response::json(500, "Veritabanı bağlantı hatası: " . $exception->getMessage());
        }

        return $this->conn;
    }
}
?>