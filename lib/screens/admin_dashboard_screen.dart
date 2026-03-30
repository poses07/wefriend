import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli'), centerTitle: true),
      body: Row(
        children: [
          // Sol Menü
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: Text('Özet'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_rounded),
                label: Text('Kullanıcılar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report_rounded),
                label: Text('Şikayetler'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Sağ İçerik
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return const AdminStatsView();
      case 1:
        return const AdminUsersView();
      case 2:
        return const AdminReportsView();
      default:
        return const Center(child: Text('Hata'));
    }
  }
}

// ----------------------------------------------------------------------
// ÖZET / İSTATİSTİKLER (STATS VIEW)
// ----------------------------------------------------------------------
class AdminStatsView extends ConsumerWidget {
  const AdminStatsView({super.key});

  Future<Map<String, dynamic>> _fetchStats(WidgetRef ref) async {
    final res = await ref.read(apiServiceProvider).getAdminStats();
    if (res['success']) {
      return res['data'];
    }
    throw Exception(res['message']);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStats(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                'Toplam Kullanıcı',
                stats['total_users'].toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                '24S Aktif',
                stats['active_users_24h'].toString(),
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Toplam Mesaj',
                stats['total_messages'].toString(),
                Icons.chat,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Aktif Hikaye',
                stats['active_stories'].toString(),
                Icons.amp_stories,
                Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// KULLANICILAR LİSTESİ VE DÜZENLEME (USERS VIEW)
// ----------------------------------------------------------------------
class AdminUsersView extends ConsumerStatefulWidget {
  const AdminUsersView({super.key});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final res = await ref.read(apiServiceProvider).getAdminUsers();
    if (res['success'] && mounted) {
      setState(() {
        _users = res['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final coinsController = TextEditingController(
      text: user['coins']?.toString() ?? '0',
    );
    final rankController = TextEditingController(
      text: user['rank_level']?.toString() ?? 'newbie',
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${user['alias']} Düzenle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: coinsController,
                  decoration: const InputDecoration(
                    labelText: 'Jeton Ekle/Çıkar',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rankController,
                  decoration: const InputDecoration(
                    labelText: 'Rank (newbie, popular, legendary)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final res = await ref
                      .read(apiServiceProvider)
                      .updateAdminUser(user['id'], {
                        'coins': int.tryParse(coinsController.text) ?? 0,
                        'rank_level': rankController.text,
                      });

                  if (!mounted) return;

                  if (res['success']) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'Güncellendi',
                      type: NotificationType.success,
                    );
                    _loadUsers();
                  } else {
                    CustomSnackBar.show(
                      context: context,
                      message: 'Hata oluştu',
                      type: NotificationType.error,
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  void _banUser(int id) async {
    final res = await ref.read(apiServiceProvider).banAdminUser(id);
    if (!mounted) return;

    if (res['success']) {
      CustomSnackBar.show(
        context: context,
        message: 'Kullanıcı Banlandı',
        type: NotificationType.success,
      );
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isAdmin = user['is_admin'] == 1 || user['is_admin'] == '1';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isAdmin ? Colors.red : Colors.blue,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: Colors.white,
            ),
          ),
          title: Text(user['alias'] ?? 'İsimsiz'),
          subtitle: Text(
            'Jeton: ${user['coins']} | Rank: ${user['rank_level']}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: () => _showEditUserDialog(user),
              ),
              if (!isAdmin)
                IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => _banUser(user['id']),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// ŞİKAYETLER LİSTESİ (REPORTS VIEW)
// ----------------------------------------------------------------------
class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key});

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final res = await ref.read(apiServiceProvider).getAdminReports();
    if (res['success'] && mounted) {
      setState(() {
        _reports = res['data'];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resolveReport(int reportId, String status) async {
    final res = await ref
        .read(apiServiceProvider)
        .resolveAdminReport(reportId, status);
    if (!mounted) return;

    if (res['success']) {
      CustomSnackBar.show(
        context: context,
        message: 'Şikayet durumu güncellendi',
        type: NotificationType.success,
      );
      _loadReports();
    } else {
      CustomSnackBar.show(
        context: context,
        message: res['message'] ?? 'Hata oluştu',
        type: NotificationType.error,
      );
    }
  }

  void _banReportedUser(int userId, int reportId) async {
    // Önce kullanıcıyı banla
    final banRes = await ref.read(apiServiceProvider).banAdminUser(userId);
    if (!mounted) return;

    if (banRes['success']) {
      CustomSnackBar.show(
        context: context,
        message: 'Kullanıcı banlandı, şikayet çözüldü',
        type: NotificationType.success,
      );
      // Şikayeti çözüldü olarak işaretle
      _resolveReport(reportId, 'resolved');
    } else {
      CustomSnackBar.show(
        context: context,
        message: 'Kullanıcı banlanamadı',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_reports.isEmpty) {
      return const Center(child: Text('Bekleyen şikayet bulunmuyor.'));
    }

    return ListView.builder(
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final isResolved = report['status'] == 'resolved';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: Icon(
              isResolved ? Icons.check_circle : Icons.warning_rounded,
              color: isResolved ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(
              '${report['reporter_name']} ➔ ${report['reported_name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Sebep: ${report['reason']}\nDurum: ${report['status']}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tarih: ${report['created_at']}'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isResolved)
                          TextButton.icon(
                            icon: const Icon(Icons.check, color: Colors.green),
                            label: const Text('Çözüldü İşaretle'),
                            onPressed:
                                () => _resolveReport(report['id'], 'resolved'),
                          ),
                        const SizedBox(width: 8),
                        if (!isResolved)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.block, color: Colors.white),
                            label: const Text('Kullanıcıyı Banla'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed:
                                () => _banReportedUser(
                                  report['reported_id'],
                                  report['id'],
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
