<?php
require_once 'includes/auth.php';

// Silme İşlemi
if (isset($_GET['delete'])) {
    $id = (int)$_GET['delete'];
    try {
        $stmt = $db->prepare("DELETE FROM quests WHERE id = :id");
        $stmt->execute([':id' => $id]);
        $success = "Görev başarıyla silindi.";
    } catch (PDOException $e) {
        $error = "Silme hatası: " . $e->getMessage();
    }
}

// Ekleme İşlemi
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['action']) && $_POST['action'] == 'add') {
    $title = $_POST['title'] ?? '';
    $desc = $_POST['description'] ?? '';
    $xp = (int)($_POST['reward_xp'] ?? 0);
    $target = (int)($_POST['target_count'] ?? 1);
    $type = $_POST['quest_type'] ?? 'daily';
    $icon = $_POST['icon_name'] ?? 'star_rounded';
    $color = $_POST['color_hex'] ?? '#FF9800';

    if ($title && $desc) {
        try {
            $stmt = $db->prepare("INSERT INTO quests (title, description, reward_xp, target_count, quest_type, icon_name, color_hex) VALUES (:title, :desc, :xp, :target, :type, :icon, :color)");
            $stmt->execute([
                ':title' => $title,
                ':desc' => $desc,
                ':xp' => $xp,
                ':target' => $target,
                ':type' => $type,
                ':icon' => $icon,
                ':color' => $color
            ]);
            $success = "Görev başarıyla eklendi.";
        } catch (PDOException $e) {
            $error = "Ekleme hatası: " . $e->getMessage();
        }
    } else {
        $error = "Lütfen başlık ve açıklama alanlarını doldurun.";
    }
}

// Görevleri Çek
try {
    $stmt = $db->query("SELECT * FROM quests ORDER BY FIELD(quest_type, 'daily', 'weekly', 'monthly'), id ASC");
    $quests = $stmt->fetchAll(PDO::FETCH_ASSOC);
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

<div class="row">
    <!-- Görev Listesi -->
    <div class="col-lg-8">
        <div class="card p-4">
            <h5 class="fw-bold mb-4">Mevcut Görevler</h5>
            <div class="table-responsive">
                <table class="table table-hover align-middle">
                    <thead class="table-light">
                        <tr>
                            <th>ID</th>
                            <th>Tip</th>
                            <th>Başlık</th>
                            <th>Hedef</th>
                            <th>Ödül (XP)</th>
                            <th class="text-end">İşlemler</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($quests)): ?>
                        <tr><td colspan="6" class="text-center text-muted">Kayıtlı görev bulunamadı.</td></tr>
                        <?php else: ?>
                            <?php foreach ($quests as $q): ?>
                            <tr>
                                <td>#<?php echo $q['id']; ?></td>
                                <td>
                                    <?php 
                                        if ($q['quest_type'] == 'daily') echo '<span class="badge bg-success">Günlük</span>';
                                        elseif ($q['quest_type'] == 'weekly') echo '<span class="badge bg-primary">Haftalık</span>';
                                        elseif ($q['quest_type'] == 'monthly') echo '<span class="badge bg-danger">Aylık</span>';
                                    ?>
                                </td>
                                <td>
                                    <div class="fw-bold"><?php echo htmlspecialchars($q['title']); ?></div>
                                    <div class="small text-muted text-truncate" style="max-width: 200px;"><?php echo htmlspecialchars($q['description']); ?></div>
                                </td>
                                <td><?php echo $q['target_count']; ?></td>
                                <td class="fw-bold text-warning"><?php echo $q['reward_xp']; ?> XP</td>
                                <td class="text-end">
                                    <a href="?delete=<?php echo $q['id']; ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Bu görevi silmek istediğinize emin misiniz?');" title="Sil">
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
    </div>

    <!-- Yeni Görev Ekle -->
    <div class="col-lg-4 mt-4 mt-lg-0">
        <div class="card p-4">
            <h5 class="fw-bold mb-4">Yeni Görev Ekle</h5>
            <form method="POST" action="">
                <input type="hidden" name="action" value="add">
                
                <div class="mb-3">
                    <label class="form-label">Görev Tipi</label>
                    <select name="quest_type" class="form-select" required>
                        <option value="daily">Günlük</option>
                        <option value="weekly">Haftalık</option>
                        <option value="monthly">Aylık</option>
                    </select>
                </div>

                <div class="mb-3">
                    <label class="form-label">Başlık</label>
                    <input type="text" name="title" class="form-control" required placeholder="Örn: Sosyalleşme Vakti">
                </div>

                <div class="mb-3">
                    <label class="form-label">Açıklama</label>
                    <textarea name="description" class="form-control" rows="2" required placeholder="Örn: 5 farklı kişiyle sohbet et."></textarea>
                </div>

                <div class="row">
                    <div class="col-6 mb-3">
                        <label class="form-label">Hedef Sayı</label>
                        <input type="number" name="target_count" class="form-control" required min="1" value="1">
                    </div>
                    <div class="col-6 mb-3">
                        <label class="form-label">Ödül XP</label>
                        <input type="number" name="reward_xp" class="form-control" required min="0" value="50">
                    </div>
                </div>

                <div class="row">
                    <div class="col-6 mb-4">
                        <label class="form-label">İkon (Material)</label>
                        <select name="icon_name" class="form-select">
                            <option value="star_rounded">Yıldız</option>
                            <option value="chat_bubble_rounded">Sohbet</option>
                            <option value="explore_rounded">Keşfet</option>
                            <option value="timer_rounded">Zaman</option>
                            <option value="visibility_rounded">Göz</option>
                            <option value="diamond_rounded">Elmas</option>
                        </select>
                    </div>
                    <div class="col-6 mb-4">
                        <label class="form-label">Renk</label>
                        <input type="color" name="color_hex" class="form-control form-control-color w-100" value="#FF9800" title="Renk seçin">
                    </div>
                </div>

                <button type="submit" class="btn btn-primary w-100 fw-bold">Görevi Kaydet</button>
            </form>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>