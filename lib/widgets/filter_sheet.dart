import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? selectedGender;
  final TextEditingController cityController = TextEditingController();
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(feedFilterProvider);
    selectedGender = currentFilter.gender;
    cityController.text = currentFilter.city ?? '';
    isOnline = currentFilter.online;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrele',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Cinsiyet
            const Text(
              'Cinsiyet',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGenderChip('Hepsi', null, cs),
                const SizedBox(width: 8),
                _buildGenderChip('Erkek', 'Erkek', cs),
                const SizedBox(width: 8),
                _buildGenderChip('Kadın', 'Kadın', cs),
              ],
            ),
            const SizedBox(height: 16),

            // Şehir
            const Text('Şehir', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: cityController,
              decoration: InputDecoration(
                hintText: 'Şehir giriniz...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Çevrimiçi Durumu
            SwitchListTile(
              title: const Text(
                'Sadece Çevrimiçi Olanlar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: isOnline,
              onChanged: (val) => setState(() => isOnline = val),
              contentPadding: EdgeInsets.zero,
              activeColor: cs.primary,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(feedFilterProvider.notifier).state = FeedFilter(
                    gender: selectedGender,
                    city:
                        cityController.text.trim().isEmpty
                            ? null
                            : cityController.text.trim(),
                    online: isOnline,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Uygula'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(String label, String? value, ColorScheme cs) {
    final isSelected = selectedGender == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          selectedGender = value;
        });
      },
      selectedColor: cs.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
      ),
    );
  }
}
