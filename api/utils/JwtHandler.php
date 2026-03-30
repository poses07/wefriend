<?php

class JwtHandler {
    // Gerçek bir projede bu anahtar çevre değişkenlerinden (env) alınmalıdır.
    private static $secret_key = "wefriend_super_secret_jwt_key_2026";
    private static $algo = 'HS256';

    public static function encode($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => self::$algo]);
        $payload = json_encode($payload);

        $base64UrlHeader = self::base64UrlEncode($header);
        $base64UrlPayload = self::base64UrlEncode($payload);

        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::$secret_key, true);
        $base64UrlSignature = self::base64UrlEncode($signature);

        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    public static function decode($token) {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return false; // Geçersiz token formatı
        }

        list($base64UrlHeader, $base64UrlPayload, $base64UrlSignature) = $parts;

        $signature = self::base64UrlDecode($base64UrlSignature);
        $expectedSignature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::$secret_key, true);

        if (hash_equals($signature, $expectedSignature)) {
            $payload = json_decode(self::base64UrlDecode($base64UrlPayload), true);
            // Süre kontrolü (Eğer ignore_expiration true ise süreyi göz ardı et)
            // Bu özellik sadece refresh_token için gereklidir
            if (isset($payload['exp']) && $payload['exp'] < time()) {
                // Return expired payload for token refreshing purposes if needed
                $payload['is_expired'] = true;
                return $payload; 
            }
            $payload['is_expired'] = false;
            return $payload;
        }

        return false; // İmza eşleşmedi
    }

    private static function base64UrlEncode($data) {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    }

    private static function base64UrlDecode($data) {
        $padding = strlen($data) % 4;
        if ($padding !== 0) {
            $data .= str_repeat('=', 4 - $padding);
        }
        return base64_decode(str_replace(['-', '_'], ['+', '/'], $data));
    }
}
?>