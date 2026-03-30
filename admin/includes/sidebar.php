            <!-- Sidebar -->
            <nav class="col-md-3 col-lg-2 d-md-block sidebar collapse px-0">
                <div class="position-sticky pt-4 px-3">
                    <div class="text-center mb-4">
                        <a href="index.php" class="brand-text">
                            <i class="bi bi-fire"></i> WeFriend
                        </a>
                        <div class="text-muted small mt-1">Yönetici Paneli</div>
                    </div>
                    
                    <ul class="nav flex-column mt-4">
                        <li class="nav-item">
                            <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'index.php' ? 'active' : ''; ?>" href="index.php">
                                <i class="bi bi-grid-1x2-fill"></i> Dashboard
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'users.php' ? 'active' : ''; ?>" href="users.php">
                                <i class="bi bi-people-fill"></i> Kullanıcılar
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link <?php echo basename($_SERVER['PHP_SELF']) == 'quests.php' ? 'active' : ''; ?>" href="quests.php">
                                <i class="bi bi-star-fill"></i> Görevler & Rozetler
                            </a>
                        </li>
                        <li class="nav-item mt-4">
                            <a class="nav-link text-danger" href="logout.php">
                                <i class="bi bi-box-arrow-right"></i> Çıkış Yap
                            </a>
                        </li>
                    </ul>
                </div>
            </nav>

            <!-- Main Content -->
            <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4 bg-light min-vh-100">
                <div class="topbar d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-4 border-bottom px-3 rounded-bottom">
                    <h1 class="h4 text-dark fw-bold">
                        <?php 
                            $page = basename($_SERVER['PHP_SELF']);
                            if ($page == 'index.php') echo 'Dashboard';
                            elseif ($page == 'users.php') echo 'Kullanıcı Yönetimi';
                            elseif ($page == 'quests.php') echo 'Görev Yönetimi';
                            else echo 'WeFriend Admin';
                        ?>
                    </h1>
                    <div class="d-flex align-items-center">
                        <span class="me-3 text-muted">Merhaba, <strong><?php echo htmlspecialchars($_SESSION['admin_username']); ?></strong></span>
                        <div class="bg-danger rounded-circle text-white d-flex align-items-center justify-content-center" style="width: 35px; height: 35px;">
                            <i class="bi bi-person-fill"></i>
                        </div>
                    </div>
                </div>