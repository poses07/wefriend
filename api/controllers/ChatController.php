<?php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../utils/JwtHandler.php';
require_once __DIR__ . '/../core/Response.php';

class ChatController {
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    private function authenticate() {
        $headers = null;
        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER["Authorization"]);
        } else if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = trim($_SERVER["HTTP_AUTHORIZATION"]);
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            $requestHeaders = array_combine(array_map('ucwords', array_keys($requestHeaders)), array_values($requestHeaders));
            if (isset($requestHeaders['Authorization'])) {
                $headers = trim($requestHeaders['Authorization']);
            }
        }

        if (!$headers) {
            Response::json(401, "Yetkisiz erişim. Token bulunamadı.");
            exit();
        }

        $parts = explode(" ", $headers);
        if (count($parts) != 2 || $parts[0] !== 'Bearer') {
            Response::json(401, "Geçersiz token formatı.");
            exit();
        }

        $token = $parts[1];
        $payload = JwtHandler::decode($token);

        if (!$payload) {
            Response::json(401, "Geçersiz veya süresi dolmuş token.");
            exit();
        }

        $user_id = $payload['user_id'];

        $stmt = $this->db->prepare("SELECT id FROM users WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $user_id]);
        
        if ($stmt->rowCount() == 0) {
            Response::json(401, "Kullanıcı bulunamadı.");
            exit();
        }

        return $user_id;
    }

    // Kullanıcının sohbetlerini getir
    public function getChats() {
        $user_id = $this->authenticate();

        $query = "
            SELECT 
                c.id as chat_id,
                c.anonymous_name,
                c.last_message,
                c.last_message_at,
                u.id as other_user_id,
                u.alias,
                u.avatar_url,
                u.rank_level,
                IF(u.last_active >= NOW() - INTERVAL 5 MINUTE, 1, 0) as is_online,
                c.user1_id,
                c.user2_id,
                (SELECT COUNT(id) FROM messages WHERE chat_id = c.id AND sender_id != :user_id1 AND is_read = 0) as unread_count
            FROM chats c
            JOIN users u ON (u.id = c.user1_id OR u.id = c.user2_id) AND u.id != :user_id2
            WHERE (c.user1_id = :user_id3 OR c.user2_id = :user_id4)
            AND c.last_message IS NOT NULL AND c.last_message != ''
            AND (
                (c.user1_id = :user_id7 AND c.is_deleted_by_u1 = 0) 
                OR 
                (c.user2_id = :user_id8 AND c.is_deleted_by_u2 = 0)
            )
            AND u.id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = :user_id5)
            AND u.id NOT IN (SELECT blocker_id FROM user_blocks WHERE blocked_id = :user_id6)
            ORDER BY c.last_message_at DESC
        ";

        $stmt = $this->db->prepare($query);
        $stmt->execute([
            ':user_id1' => $user_id,
            ':user_id2' => $user_id,
            ':user_id3' => $user_id,
            ':user_id4' => $user_id,
            ':user_id5' => $user_id,
            ':user_id6' => $user_id,
            ':user_id7' => $user_id,
            ':user_id8' => $user_id,
        ]);
        $chats = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Anonimlik mantığını uygula (Connected2.me)
        foreach ($chats as &$chat) {
            // user1_id: Sohbeti başlatan (Gönderen) -> Her zaman Anonim
            // user2_id: Mesajı alan (Alıcı) -> Gerçek kimliği belli
            
            if ($user_id == $chat['user2_id']) {
                // Biz alıcıyız. Karşı taraf (other_user_id) sohbeti başlatan (user1_id).
                // Bu yüzden karşı taraf bize ANONİM görünmeli.
                $chat['display_name'] = $chat['anonymous_name'];
                $chat['avatar_url'] = null; // Anonim avatar
                $chat['rank_level'] = 'none'; // Anonim rank
                $chat['is_online'] = 0; // Anonim kullanıcının online durumu gizlenebilir (opsiyonel)
            } else {
                // Biz göndereniz (user_id == user1_id). Karşı taraf (other_user_id) alıcı (user2_id).
                // Bu yüzden karşı taraf kendi GERÇEK profiliyle görünür.
                $chat['display_name'] = $chat['alias'];
            }
            
            unset($chat['user1_id']);
            unset($chat['user2_id']);
            
            // Okunmamış mesaj sayısını integer'a çevir
            $chat['unread_count'] = (int)$chat['unread_count'];
            $chat['is_new'] = $chat['unread_count'] > 0;
        }

        Response::json(200, "Sohbetler getirildi.", $chats);
    }
    // Belirli bir sohbetin mesaj geçmişini getir
    public function getMessages() {
        $user_id = $this->authenticate();
        $chat_id = isset($_GET['chat_id']) ? (int)$_GET['chat_id'] : 0;
        $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;

        if ($chat_id <= 0) {
            Response::json(400, "Geçersiz sohbet ID'si.");
            exit();
        }

        $check = $this->db->prepare("SELECT id, user1_id, user2_id FROM chats WHERE id = :chat_id");
        $check->execute([':chat_id' => $chat_id]);
        $chatRow = $check->fetch(PDO::FETCH_ASSOC);

        if (!$chatRow) {
            Response::json(404, "Sohbet bulunamadı. (Chat: $chat_id)");
            exit();
        }

        if ($chatRow['user1_id'] != $user_id && $chatRow['user2_id'] != $user_id) {
            Response::json(403, "Bu sohbete erişim yetkiniz yok. (Chat: $chat_id, U1: {$chatRow['user1_id']}, U2: {$chatRow['user2_id']}, You: $user_id)");
            exit();
        }

        // Mesajları çek (Yeniden eskiye doğru çekip Flutter'da tersine çevireceğiz)
        $query = "SELECT id, sender_id, content, message_type, is_read, created_at 
                  FROM messages 
                  WHERE chat_id = :chat_id 
                  ORDER BY created_at DESC 
                  LIMIT :limit OFFSET :offset";
        
        $stmt = $this->db->prepare($query);
        // PDO'da LIMIT ve OFFSET parametrelerini bind ederken INT olarak belirtmek zorundayız
        $stmt->bindValue(':chat_id', $chat_id, PDO::PARAM_INT);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Tarih sırasına göre eski->yeni olması için diziyi tersine çeviriyoruz (sadece ilk yüklemede mantıklı olur)
        $messages = array_reverse($messages);

        // Kendi mesajımız mı diye işaretle
        foreach ($messages as &$msg) {
            $msg['isMe'] = ($msg['sender_id'] == $user_id);
            // Frontend için formatla
            $msg['text'] = $msg['content'];
            $msg['type'] = $msg['message_type'];
            $msg['time'] = date('H:i', strtotime($msg['created_at']));
            unset($msg['content']);
            unset($msg['message_type']);
        }

        // Karşı tarafın mesajlarını okundu olarak işaretle (Sadece ilk sayfada yapılması yeterli)
        if ($offset == 0) {
            $updateRead = $this->db->prepare("UPDATE messages SET is_read = 1 WHERE chat_id = :chat_id AND sender_id != :user_id AND is_read = 0");
            $updateRead->execute([':chat_id' => $chat_id, ':user_id' => $user_id]);
        }

        Response::json(200, "Mesajlar getirildi.", $messages);
    }

    // Yeni bir sohbet başlat veya olanı getir (Kullanıcı profiline tıklandığında)
    public function startChat() {
        $user_id = $this->authenticate();
        
        $other_user_id = 0;
        $raw_input = file_get_contents("php://input");
        $data = json_decode($raw_input, true);

        if (isset($_POST['user_id'])) {
            $other_user_id = (int)$_POST['user_id'];
        } elseif (isset($data['user_id'])) {
            $other_user_id = (int)$data['user_id'];
        }

        if ($other_user_id <= 0 || $other_user_id == $user_id) {
            Response::json(400, "Geçersiz kullanıcı. POST Verisi: " . json_encode($_POST) . " Raw: " . $raw_input);
            exit();
        }

        // Zaten aralarında bu yönde (Biz -> Karşı Taraf) bir sohbet var mı kontrol et
        // Connected2.me mantığı: A kişisi B'ye yazarsa A anonimdir. 
        // B kişisi A'ya yazarsa B anonimdir. Bunlar 2 ayrı sohbettir!
        $query = "SELECT id FROM chats WHERE user1_id = :u1 AND user2_id = :u2 LIMIT 1";
        $stmt = $this->db->prepare($query);
        $stmt->execute([
            ':u1' => $user_id, 
            ':u2' => $other_user_id
        ]);
        $existingChat = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($existingChat) {
            Response::json(200, "Sohbet mevcut.", ['chat_id' => $existingChat['id']]);
            exit();
        }

        // Mesajı socket server üzerinden veya veritabanından gönderildiğini varsayıyoruz.
        // Ancak bu API genelde ilk chat başlatma için kullanılıyor, 
        // gerçek mesajlaşma socket üzerinden döndüğü için socket server'a (index.js) bir tetikleme eklememiz gerekir.
        // Socket tarafında mesaj atıldığında, MySQL'e yazar yazmaz görev ilerlemesi tetiklenebilir.
        // Veya mesajlaşmayı tamamen API üzerinden de destekliyorsak buraya eklenebilir.
        require_once __DIR__ . '/../utils/AnonymousHelper.php';
        $anonName = AnonymousHelper::generateName();

        $insert = $this->db->prepare("INSERT INTO chats (user1_id, user2_id, anonymous_name) VALUES (:u1, :u2, :anon)");
        $insert->execute([
            ':u1' => $user_id, // Başlatan
            ':u2' => $other_user_id, // Alan
            ':anon' => $anonName
        ]);

        Response::json(200, "Sohbet oluşturuldu.", ['chat_id' => $this->db->lastInsertId()]);
    }

    // Yeni mesaj gönderme fonksiyonu (Sadece PHP + MySQL)
    public function sendMessage() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);

        $chat_id = isset($data['chat_id']) ? (int)$data['chat_id'] : 0;
        $content = isset($data['content']) ? trim($data['content']) : '';
        $type = isset($data['type']) ? $data['type'] : 'text';

        if ($chat_id <= 0 || empty($content)) {
            Response::json(400, "Geçersiz sohbet veya boş mesaj.");
            exit();
        }

        // Sohbeti kontrol et
        $stmt = $this->db->prepare("SELECT id, user1_id, user2_id FROM chats WHERE id = :chat_id");
        $stmt->execute([':chat_id' => $chat_id]);
        $chat = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$chat || ($chat['user1_id'] != $user_id && $chat['user2_id'] != $user_id)) {
            Response::json(403, "Bu sohbete mesaj gönderemezsiniz.");
            exit();
        }

        // Mesajı veritabanına kaydet
        $insert = $this->db->prepare("INSERT INTO messages (chat_id, sender_id, content, message_type) VALUES (:chat_id, :sender_id, :content, :type)");
        if ($insert->execute([
            ':chat_id' => $chat_id,
            ':sender_id' => $user_id,
            ':content' => $content,
            ':type' => $type
        ])) {
            $msg_id = $this->db->lastInsertId();

            // Sohbetin son mesajını ve tarihini güncelle
            $update = $this->db->prepare("UPDATE chats SET last_message = :content, last_message_at = NOW() WHERE id = :chat_id");
            // Eğer resimse son mesaj olarak "Fotoğraf" yazsın
            $lastMsgText = $type == 'image' ? '📷 Fotoğraf' : $content;
            $update->execute([':content' => $lastMsgText, ':chat_id' => $chat_id]);

            // FCM Bildirimi Gönder (Alıcıya)
            require_once __DIR__ . '/../utils/FcmHelper.php';
            $receiver_id = ($chat['user1_id'] == $user_id) ? $chat['user2_id'] : $chat['user1_id'];
            
            // Bildirimi gönderenin adını belirle (Anonimlik kuralı)
            if ($chat['user1_id'] == $user_id) {
                // Gönderen = Sohbeti başlatan (Anonim)
                $senderName = $chat['anonymous_name'] ?? 'Gizemli Biri';
            } else {
                // Gönderen = Sohbeti alan (Gerçek profil)
                $senderStmt = $this->db->prepare("SELECT alias FROM users WHERE id = :id LIMIT 1");
                $senderStmt->execute([':id' => $user_id]);
                $senderName = $senderStmt->fetchColumn() ?: 'Bir Kullanıcı';
            }

            FcmHelper::sendToUser(
                $this->db, 
                $receiver_id, 
                $senderName, 
                $lastMsgText, 
                [
                    'type' => 'chat_message',
                    'chat_id' => $chat_id,
                    'sender_id' => $user_id
                ]
            );

            // Görev ilerlemesi (Quest) - "3 kişiye mesaj at" vb. görevler için
            try {
                // Sadece db üzerinden user_quests tablosunu güncelleyelim (basitçe)
                $questStmt = $this->db->prepare("
                    UPDATE user_quests uq 
                    JOIN quests q ON uq.quest_id = q.id 
                    SET uq.progress = uq.progress + 1 
                    WHERE uq.user_id = :user_id 
                    AND q.action_type = 'send_message' 
                    AND uq.is_completed = 0 
                    AND DATE(uq.assigned_at) = CURDATE()
                ");
                $questStmt->execute([':user_id' => $user_id]);

                // Eğer progress target_count'a ulaştıysa is_completed = 1 yap
                $this->db->query("
                    UPDATE user_quests uq 
                    JOIN quests q ON uq.quest_id = q.id 
                    SET uq.is_completed = 1 
                    WHERE uq.progress >= q.target_count 
                    AND uq.is_completed = 0
                ");
            } catch (Exception $e) {
                // Hata olursa mesaj gönderimi engellenmesin
            }

            Response::json(200, "Mesaj gönderildi.", [
                'message_id' => $msg_id,
                'content' => $content,
                'type' => $type,
                'time' => date('H:i')
            ]);
        } else {
            Response::json(500, "Mesaj gönderilemedi.");
        }
    }

    public function deleteChat() {
        $user_id = $this->authenticate();
        $data = json_decode(file_get_contents("php://input"), true);
        $chat_id = isset($data['chat_id']) ? (int)$data['chat_id'] : 0;

        if ($chat_id <= 0) {
            Response::json(400, "Geçersiz sohbet ID");
            exit();
        }

        // Önce sohbetin bu kullanıcıya ait olup olmadığını kontrol et
        $stmt = $this->db->prepare("SELECT id, user1_id, user2_id FROM chats WHERE id = :chat_id");
        $stmt->execute([':chat_id' => $chat_id]);
        $chat = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$chat || ($chat['user1_id'] != $user_id && $chat['user2_id'] != $user_id)) {
            Response::json(403, "Bu sohbete erişim yetkiniz yok.");
            exit();
        }

        // Kullanıcı 1 ise is_deleted_by_u1 = 1 yap, Kullanıcı 2 ise is_deleted_by_u2 = 1 yap
        if ($chat['user1_id'] == $user_id) {
            $update = $this->db->prepare("UPDATE chats SET is_deleted_by_u1 = 1 WHERE id = :chat_id");
        } else {
            $update = $this->db->prepare("UPDATE chats SET is_deleted_by_u2 = 1 WHERE id = :chat_id");
        }
        $update->execute([':chat_id' => $chat_id]);

        Response::json(200, "Sohbet başarıyla silindi");
    }

    public function uploadMedia() {
        $user_id = $this->authenticate();

        if (!isset($_FILES['media']) || $_FILES['media']['error'] !== UPLOAD_ERR_OK) {
            Response::json(400, "Dosya yüklenemedi.");
            exit();
        }

        // Sunucudaki ana dizine uploads klasörü oluştur (controllers'tan bir üst dizin)
        $uploadDir = __DIR__ . '/../uploads/chat_media/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $fileExt = pathinfo($_FILES['media']['name'], PATHINFO_EXTENSION);
        $fileName = "media_" . $user_id . "_" . time() . "." . $fileExt;
        $uploadFilePath = $uploadDir . $fileName;

        if (move_uploaded_file($_FILES['media']['tmp_name'], $uploadFilePath)) {
            $media_url = "https://operasyon.milatsoft.com/uploads/chat_media/" . $fileName;
            Response::json(200, "Medya yüklendi.", ['url' => $media_url]);
        } else {
            Response::json(500, "Medya kaydedilemedi.");
        }
    }
}
?>