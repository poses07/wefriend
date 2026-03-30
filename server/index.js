require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mysql = require('mysql2');
const cors = require('cors');
const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat (Bu dosyanın yolu sende farklı olabilir, firebase console'dan indirip server klasörüne atman gerekecek)
// Şimdilik try-catch içine alalım ki dosya yoksa sunucu çökmesin
try {
  const serviceAccount = require('./firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("Firebase Admin başlatıldı.");
} catch (error) {
  console.log("Firebase başlatılamadı (serviceAccount dosyası eksik olabilir):", error.message);
}

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Geliştirme aşamasında her yerden erişime izin ver
    methods: ["GET", "POST"]
  }
});

// Veritabanı Bağlantısı
const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'wefriend_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Kullanıcıların online durumunu ve soket ID'lerini tutacağımız map
// Yapı: { userId: socketId }
const connectedUsers = new Map();

io.on('connection', (socket) => {
  console.log(`Yeni bağlantı: ${socket.id}`);

  // Kullanıcı giriş yaptığında (Flutter'dan socket.emit('join', userId) atılacak)
  socket.on('join', (userId) => {
    connectedUsers.set(userId, socket.id);
    console.log(`Kullanıcı katıldı: ${userId} -> Socket: ${socket.id}`);
    
    // Arkadaşlarına "çevrimiçi oldu" bilgisi atılabilir (İleride)
    io.emit('userStatus', { userId, status: 'online' });
  });

  // Yazıyor... bildirimi
  socket.on('typing', (data) => {
    const { chatId, senderId, receiverId, isTyping } = data;
    const receiverSocketId = connectedUsers.get(receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('typing', { chatId, senderId, isTyping });
    }
  });

  // Mesaj gönderme işlemi
  socket.on('sendMessage', async (data) => {
    const { chatId, senderId, receiverId, content, type = 'text' } = data;

    console.log(`Mesaj geldi: ${senderId} -> ${receiverId}: ${content} [${type}]`);

    if (!chatId || !senderId || !receiverId || !content) {
      console.log('Eksik mesaj verisi:', data);
      return;
    }

    // 1. Veritabanına kaydet
    try {
      // Engelleme Kontrolü
      // Alıcı, Göndereni engellemiş mi?
      const [blockCheck] = await db.promise().query(
        'SELECT id FROM user_blocks WHERE blocker_id = ? AND blocked_id = ?',
        [receiverId, senderId]
      );

      if (blockCheck.length > 0) {
        console.log(`Mesaj reddedildi: Kullanıcı ${receiverId}, ${senderId} idli kullanıcıyı engellemiş.`);
        // İsteğe bağlı olarak gönderene "Bu kullanıcı sizi engelledi" mesajı döndürülebilir
        socket.emit('messageError', { message: 'Bu kullanıcıya mesaj gönderemezsiniz.' });
        return; // İşlemi durdur, mesajı kaydetme
      }
      const [result] = await db.promise().query(
        'INSERT INTO messages (chat_id, sender_id, content, message_type) VALUES (?, ?, ?, ?)',
        [chatId, senderId, content, type]
      );

      // Görev ilerlemesini tetikle (PHP scripti üzerinden çağırabilir veya direkt Node.js'ten MySQL'e yazabiliriz)
      // Performans için direkt MySQL üzerinden user_quests tablosunu güncelleyelim
      const updateQuest = `
        UPDATE user_quests uq
        JOIN quests q ON uq.quest_id = q.id
        SET uq.progress = uq.progress + 1,
            uq.is_completed = IF(uq.progress + 1 >= q.target_count, 1, 0)
        WHERE uq.user_id = ? AND q.action_type = 'send_message' AND uq.is_completed = 0
      `;
      db.query(updateQuest, [senderId], (err) => {
        if (err) console.error('Görev güncelleme hatası:', err);
      });

      const lastMessageText = type === 'image' ? '📷 Fotoğraf' : content;

      // Chats tablosunu son mesajla güncelle
      await db.promise().query(
        'UPDATE chats SET last_message = ?, last_message_at = CURRENT_TIMESTAMP WHERE id = ?',
        [lastMessageText, chatId]
      );

      const messageId = result.insertId;

      const messageData = {
        id: messageId,
        chatId,
        senderId,
        content,
        type,
        createdAt: new Date().toISOString()
      };

      // 2. Karşı taraf (alıcı) online ise ona ilet
      const receiverSocketId = connectedUsers.get(receiverId);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('receiveMessage', messageData);
        console.log(`Mesaj alıcıya iletildi (Socket ID: ${receiverSocketId})`);
      } else {
        // Alıcı online değilse veya socket'e bağlı değilse Push Notification (FCM) gönder
        try {
          const [userRows] = await db.promise().query('SELECT fcm_token FROM users WHERE id = ?', [receiverId]);
          const fcmToken = userRows.length > 0 ? userRows[0].fcm_token : null;

          if (fcmToken) {
            const payload = {
              notification: {
                title: 'Yeni Mesaj', // Anonimliği korumak için gönderen adını çekmedik
                body: lastMessageText
              },
              data: {
                type: 'chat',
                chatId: chatId.toString(),
                senderId: senderId.toString()
              },
              token: fcmToken
            };

            admin.messaging().send(payload)
              .then((response) => {
                console.log('FCM Bildirimi başarıyla gönderildi:', response);
              })
              .catch((error) => {
                console.log('FCM Bildirim gönderme hatası:', error);
              });
          }
        } catch (fcmErr) {
          console.error("FCM Token alınırken hata:", fcmErr);
        }
      }

      // 3. Gönderene de başarılı olduğuna dair geri bildirim ver (Opsiyonel)
      socket.emit('messageSent', messageData);

    } catch (err) {
      console.error("Mesaj kaydedilirken hata oluştu:", err);
    }
  });

  // Bağlantı koptuğunda
  socket.on('disconnect', () => {
    console.log(`Bağlantı koptu: ${socket.id}`);
    // Map'ten çıkar
    for (let [userId, socketId] of connectedUsers.entries()) {
      if (socketId === socket.id) {
        connectedUsers.delete(userId);
        io.emit('userStatus', { userId, status: 'offline' });
        console.log(`Kullanıcı ayrıldı: ${userId}`);
        break;
      }
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Socket.IO Sunucusu ${PORT} portunda çalışıyor.`);
});
