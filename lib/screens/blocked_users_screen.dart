import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  List<dynamic> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.getBlockedUsers();

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _blockedUsers = result['data'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(int id, String alias) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Engeli Kaldır'),
            content: Text(
              '$alias adlı kullanıcının engelini kaldırmak istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Kaldır',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final api = ref.read(apiServiceProvider);
    final result = await api.unblockUser(id);

    if (result['success'] == true) {
      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == id);
      });
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Kullanıcının engeli kaldırıldı.',
          type: NotificationType.success,
        );
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Engel kaldırılamadı.',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engellenen Kullanıcılar'),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _blockedUsers.isEmpty
              ? const Center(child: Text('Engellenen kullanıcı bulunmuyor.'))
              : ListView.builder(
                itemCount: _blockedUsers.length,
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty
                            ? user['avatar_url'].toString()
                            : 'https://ui-avatars.com/api/?name=${user['alias'] ?? 'User'}&size=128&background=random&color=fff&bold=true',
                      ),
                    ),
                    title: Text(user['alias'] ?? 'İsimsiz'),
                    trailing: TextButton(
                      onPressed: () => _unblockUser(user['id'], user['alias']),
                      child: const Text(
                        'Engeli Kaldır',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
