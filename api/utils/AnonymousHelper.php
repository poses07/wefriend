<?php

class AnonymousHelper {
    private static $prefixes = [
        "gizemli", "yabanci", "golge", "maskeli", "anonim", 
        "hayalet", "misafir", "yolcu", "gezgin", "sessiz"
    ];

    /**
     * Rastgele bir anonim isim üretir (Örn: gizemli-1711543210452)
     * Çakışmayı önlemek için milisaniye cinsinden zaman damgası ve rastgele sayı kullanır.
     * 
     * @return string
     */
    public static function generateName() {
        $prefixIndex = array_rand(self::$prefixes);
        $prefix = self::$prefixes[$prefixIndex];
        
        // Milisaniye cinsinden benzersiz zaman damgası oluştur (Örn: 1711543210452)
        $timestamp = (int)(microtime(true) * 1000);
        
        // Ekstra güvenlik için sonuna 2-3 haneli rastgele bir sayı daha ekleyebiliriz ama 
        // microtime(true) genelde yeterince benzersizdir. Biz yine de ekleyelim.
        $randomSuffix = mt_rand(10, 99);

        return $prefix . "-" . $timestamp . $randomSuffix;
    }
}
?>