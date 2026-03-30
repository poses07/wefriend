<?php
require_once 'includes/auth.php';

// Silme İşlemi
if (isset($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    try {
        $stmt = $db->prepare("DELETE FROM users WHERE id = :id");
        $stmt->execute([':id' => $id]);
        $success = "Kullanıcı başarıyla silindi.";
    } catch (PDOException $e) {
        $error = "Silme hatası: " . $e->getMessage();
    }
}

// Kullanıcıları Çek
try {
    $stmt = $db->query("SELECT * FROM users ORDER BY id DESC");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $error = "Veritabanı hatası: " . $e->getMessage();
}

require_once 'includes/header.php';
require_once 'includes/sidebar.php';
?>

<?php if (isset($success)): ?>
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <?php echo $success; ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>
<?php if (isset($error)): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <?php echo $error; ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<div class="card p-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h5 class="fw-bold mb-0">Tüm Kullanıcılar</h5>
        <!-- İleride arama/filtreleme eklenebilir -->
        <div class="input-group" style="width: 250px;">
            <input type="text" class="form-control" placeholder="Kullanıcı Ara..." disabled>
            <button class="btn btn-outline-secondary" type="button" disabled><i class="bi bi-search"></i></button>
        </div>
    </div>
    
    <div class="table-responsive">
        <table class="table table-hover align-middle">
            <thead class="table-light">
                <tr>
                    <th>ID</th>
                    <th>Avatar</th>
                    <th>Takma Ad</th>
                    <th>Telefon</th>
                    <th>XP Puanı</th>
                    <th>Seviye</th>
                    <th>Kayıt Tarihi</th>
                    <th class="text-end">İşlemler</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($users)): ?>
                <tr><td colspan="8" class="text-center text-muted">Kayıtlı kullanıcı bulunamadı.</td></tr>
                <?php else: ?>
                    <?php foreach ($users as $u): ?>
                    <tr>
                        <td>#<?php echo $u['id']; ?></td>
                        <td>
                            <?php if ($u['avatar_url']): ?>
                                <img src="<?php echo htmlspecialchars($u['avatar_url']); ?>" class="rounded-circle" width="40" height="40" style="object-fit: cover;">
                            <?php else: ?>
                                <div class="bg-secondary text-white rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                                    <i class="bi bi-person"></i>
                                </div>
                            <?php endif; ?>
                        </td>
                        <td class="fw-bold"><?php echo htmlspecialchars($u['alias']); ?></td>
                        <td><?php echo htmlspecialchars($u['phone']); ?></td>
                        <td><?php echo number_format($u['xp_points']); ?> XP</td>
                        <td>
                            <?php 
                                if ($u['rank_level'] == 'legendary') echo '<span class="badge bg-purple" style="background-color:#6f42c1;">Efsanevi</span>';
                                elseif ($u['rank_level'] == 'popular') echo '<span class="badge bg-warning text-dark">Popüler</span>';
                                else echo '<span class="badge bg-secondary">Yeni</span>';
                            ?>
                        </td>
                        <td class="text-muted small"><?php echo date('d.m.Y H:i', strtotime($u['created_at'])); ?></td>
                        <td class="text-end">
                            <button class="btn btn-sm btn-outline-primary me-1" title="Düzenle (Yakında)" disabled>
                                <i class="bi bi-pencil"></i>
                            </button>
                            <a href="?delete=<?php echo $u['id']; ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Bu kullanıcıyı silmek istediğinize emin misiniz?');" title="Sil">
                                <i class="bi bi-trash"></i>
                            </a>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>