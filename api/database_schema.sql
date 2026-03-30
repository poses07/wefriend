-- Veritabanını oluştur (Eğer yoksa)
CREATE DATABASE IF NOT EXISTS wefriend_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE wefriend_db;

-- 1. KULLANICILAR TABLOSU (users)
-- Anonimlik ön planda olduğu için isim/soyisim yerine alias(takma ad) ve UUID tutulur.
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL,              -- Cihazdan gelen benzersiz kimlik (Artık UNIQUE değil)
    alias VARCHAR(50) NOT NULL UNIQUE,      -- Rastgele atanan veya seçilen takma ad (Artık UNIQUE)
    avatar_url VARCHAR(255) DEFAULT NULL,   -- Profil fotoğrafı veya avatar linki
    bio VARCHAR(500) DEFAULT NULL,          -- Hakkımda (Onboarding'de doldurulur)
    age INT DEFAULT NULL,                   -- Yaş (Onboarding'de doldurulur)
    gender ENUM('Male', 'Female', 'Other') DEFAULT NULL, -- Cinsiyet (Onboarding'de doldurulur)
    city VARCHAR(100) DEFAULT NULL,         -- Şehir (Onboarding'de doldurulur)
    rank_level ENUM('none', 'popular', 'legendary') DEFAULT 'none', -- Kullanıcı seviyesi
    xp_points INT DEFAULT 0,                -- Kazanılan deneyim puanı
    fcm_token VARCHAR(255) DEFAULT NULL,    -- Firebase Cloud Messaging token'ı (Bildirimler için)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_uuid (uuid)                   -- Hızlı arama için indeks
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. MEKAN CHECK-IN TABLOSU (venue_checkins)
-- Hangi kullanıcının hangi Foursquare mekanında olduğunu tutar.
CREATE TABLE IF NOT EXISTS venue_checkins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,                   -- users tablosundaki id
    fsq_id VARCHAR(100) NOT NULL,           -- Foursquare mekan ID'si
    venue_name VARCHAR(150) NOT NULL,       -- Mekan adı
    checked_in_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,              -- Check-in'in geçerlilik süresi (Örn: 4 saat sonra otomatik düşer)
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_fsq_id (fsq_id),
    INDEX idx_active_checkins (expires_at)  -- Süresi dolmayanları hızlı çekmek için
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. KULLANICI ROZETLERİ (user_badges)
-- Kullanıcının kazandığı rozetleri tutar (Çoka-çok ilişki)
CREATE TABLE IF NOT EXISTS user_badges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    badge_type VARCHAR(50) NOT NULL,        -- Rozet tipi/kodu (Örn: 10k_club, loved, chat_bird)
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_badge (user_id, badge_type) -- Bir kullanıcı aynı rozeti 2 kez alamaz
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. SOHBET ODALARI (chats)
-- İki kullanıcı arasındaki konuşma odası
CREATE TABLE IF NOT EXISTS chats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user1_id INT NOT NULL,                  -- Sohbeti başlatan (Gönderen)
    user2_id INT NOT NULL,                  -- Mesajı alan (Profil sahibi)
    anonymous_name VARCHAR(100) NOT NULL,   -- Sistem tarafından atanan rastgele anonim isim (örn: Gizemli Kaplan)
    last_message TEXT DEFAULT NULL,
    last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_chat (user1_id, user2_id) -- İki kullanıcı arasında sadece 1 oda olabilir
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. MESAJLAR (messages)
-- Sohbet odalarındaki bireysel mesajlar
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chat_id INT NOT NULL,
    sender_id INT NOT NULL,
    content TEXT NOT NULL,                  -- Mesaj içeriği
    is_read BOOLEAN DEFAULT FALSE,          -- Okundu bilgisi
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_chat_id (chat_id),            -- Odadaki mesajları hızlı listelemek için
    INDEX idx_created_at (created_at)       -- Sıralama için
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;