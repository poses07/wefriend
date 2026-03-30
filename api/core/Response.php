<?php

class Response {
    // API'nin her zaman standart bir JSON dönmesini sağlayan yardımcı sınıf
    public static function json($statusCode, $message, $data = null) {
        http_response_code($statusCode);
        
        $response = [
            'status' => ($statusCode >= 200 && $statusCode < 300) ? 'success' : 'error',
            'message' => $message
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit(); // Yanıt döndükten sonra PHP'nin çalışmasını durdur (Güvenlik ve performans için)
    }
}
?>