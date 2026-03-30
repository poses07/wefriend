<?php
require_once 'includes/auth.php';

// İstatistikleri çekelim
$stats = [
    'total_users' => 0,
    'total_chats' => 0,
    'total_messages' => 0,
    'total_quests' => 0
];

try {
    $stats['total_users'] = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
    $stats['total_chats'] = $db->query("SELECT COUNT(*) FROM chats")->fetchColumn();
    $stats['total_messages'] = $db->query("SELECT COUNT(*) FROM messages")->fetchColumn();
    $stats['total_quests'] = $db->query("SELECT COUNT(*) FROM quests")->fetchColumn();

    // Son 5 kullanıcı
    $stmt = $db->query("SELECT id, alias, rank_level, created_at FROM users ORDER BY created_at DESC LIMIT 5");
    $latest_users = $stmt->fetchAll(PDO::FETCH_ASSOC);

} catch (PDOException $e) {
    $error = "Veritabanı hatası: " . $e->getMessage();
}

require_once 'includes/header.php';
require_once 'includes/sidebar.php';
?>

<?php if (isset($error)): ?>
    <div class="alert alert-danger"><?php echo $error; ?></div>
<?php endif; ?>

<!-- İstatistik Kartları -->
<div class="row g-4 mb-4">
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card p-3 border-start border-danger border-4">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h6 class="text-muted mb-2">Toplam Kullanıcı</h6>
                    <h3 class="mb-0 fw-bold"><?php echo number_format($stats['total_users']); ?></h3>
                </div>
                <div class="bg-danger bg-opacity-10 p-3 rounded">
                    <i class="bi bi-people text-danger fs-4"></i>
                </div>
            </div>
        </div>
    </div>
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card p-3 border-start border-primary border-4">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h6 class="text-muted mb-2">Toplam Sohbet</h6>
                    <h3 class="mb-0 fw-bold"><?php echo number_format($stats['total_chats']); ?></h3>
                </div>
                <div class="bg-primary bg-opacity-10 p-3 rounded">
                    <i class="bi bi-chat-dots text-primary fs-4"></i>
                </div>
            </div>
        </div>
    </div>
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card p-3 border-start border-success border-4">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h6 class="text-muted mb-2">Toplam Mesaj</h6>
                    <h3 class="mb-0 fw-bold"><?php echo number_format($stats['total_messages']); ?></h3>
                </div>
                <div class="bg-success bg-opacity-10 p-3 rounded">
                    <i class="bi bi-envelope text-success fs-4"></i>
                </div>
            </div>
        </div>
    </div>
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card p-3 border-start border-warning border-4">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <h6 class="text-muted mb-2">Aktif Görevler</h6>
                    <h3 class="mb-0 fw-bold"><?php echo number_format($stats['total_quests']); ?></h3>
                </div>
                <div class="bg-warning bg-opacity-10 p-3 rounded">
                    <i class="bi bi-star text-warning fs-4"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <!-- Son Kayıt Olan Kullanıcılar -->
    <div class="col-lg-8">
        <div class="card p-4">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h5 class="fw-bold mb-0">Son Kayıt Olanlar</h5>
                <a href="users.php" class="btn btn-sm btn-outline-danger">Tümünü Gör</a>
            </div>
            <div class="table-responsive">
                <table class="table table-hover align-middle">
                    <thead class="table-light">
                        <tr>
                            <th>ID</th>
                            <th>Takma Ad</th>
                            <th>Seviye</th>
                            <th>Kayıt Tarihi</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($latest_users)): ?>
                        <tr><td colspan="4" class="text-center text-muted">Henüz kullanıcı yok.</td></tr>
                        <?php else: ?>
                            <?php foreach ($latest_users as $u): ?>
                            <tr>
                                <td>#<?php echo $u['id']; ?></td>
                                <td class="fw-bold"><?php echo htmlspecialchars($u['alias']); ?></td>
                                <td>
                                    <?php 
                                        if ($u['rank_level'] == 'legendary') echo '<span class="badge bg-purple" style="background-color:#6f42c1;">Efsanevi</span>';
                                        elseif ($u['rank_level'] == 'popular') echo '<span class="badge bg-warning text-dark">Popüler</span>';
                                        else echo '<span class="badge bg-secondary">Yeni</span>';
                                    ?>
                                </td>
                                <td class="text-muted small"><?php echo date('d.m.Y H:i', strtotime($u['created_at'])); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <!-- Hızlı İşlemler -->
    <div class="col-lg-4 mt-4 mt-lg-0">
        <div class="card p-4 h-100">
            <h5 class="fw-bold mb-4">Hızlı İşlemler</h5>
            <div class="d-grid gap-3">
                <a href="users.php" class="btn btn-light text-start p-3 border">
                    <i class="bi bi-person-plus text-primary me-2 fs-5"></i> Kullanıcıları Yönet
                </a>
                <a href="quests.php" class="btn btn-light text-start p-3 border">
                    <i class="bi bi-plus-circle text-success me-2 fs-5"></i> Yeni Görev Ekle
                </a>
                <button class="btn btn-light text-start p-3 border" onclick="alert('Yakında eklenecek')">
                    <i class="bi bi-megaphone text-warning me-2 fs-5"></i> Genel Bildirim Gönder
                </button>
            </div>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>