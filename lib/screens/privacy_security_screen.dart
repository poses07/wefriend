import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik ve Güvenlik'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Güvenlik Başlığı
            Text(
              'Güvenlik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionContainer(
              cs: cs,
              children: [
                _buildToggleItem(
                  cs: cs,
                  icon: Icons.fingerprint_rounded,
                  title: 'Biyometrik Kilit',
                  subtitle: 'Uygulamayı açarken Face ID/Touch ID iste',
                  value: true,
                  onChanged: (val) {},
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3), indent: 16),
                _buildActionItem(
                  cs: cs,
                  icon: Icons.password_rounded,
                  title: 'Şifreyi Değiştir',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Gizlilik Başlığı
            Text(
              'Gizlilik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionContainer(
              cs: cs,
              children: [
                _buildToggleItem(
                  cs: cs,
                  icon: Icons.location_off_rounded,
                  title: 'Konumumu Gizle',
                  subtitle: 'Keşfet ekranında mesafen görünmez',
                  value: false,
                  onChanged: (val) {},
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3), indent: 16),
                _buildToggleItem(
                  cs: cs,
                  icon: Icons.visibility_off_rounded,
                  title: 'Okundu Bilgisi',
                  subtitle: 'Mesajları okuduğunda karşı tarafa bildirme',
                  value: true,
                  onChanged: (val) {},
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3), indent: 16),
                _buildToggleItem(
                  cs: cs,
                  icon: Icons.person_off_rounded,
                  title: 'Keşfette Görünme',
                  subtitle: 'Yeni insanlarla eşleşmeye kapat',
                  value: false,
                  onChanged: (val) {},
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Tehlikeli Alan (Hesap Silme)
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Hesabımı Kalıcı Olarak Sil'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required ColorScheme cs, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildToggleItem({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: cs.onSurfaceVariant, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(icon, color: cs.onSurfaceVariant, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
