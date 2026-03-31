import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedCity;
  String? _selectedGender;
  bool _isLoading = false;

  // Türkiye'nin 81 ili
  final List<String> _cities = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kilis',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Şanlıurfa',
    'Şırnak',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
  ];

  // Artık yerel dosya yollarını (String olarak) veya API'den gelen URL'leri tutacağız
  List<String?> photos = [null, null, null, null, null, null];

  @override
  void initState() {
    super.initState();
    // Mevcut profil verilerini dinleyip controller'a aktarıyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileAsync = ref.read(userProfileProvider);
      if (profileAsync.value != null) {
        final data = profileAsync.value!;
        _aliasController.text = data['alias'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedCity = data['city'] ?? '';
        if (!_cities.contains(_selectedCity)) _selectedCity = null;
        _ageController.text = data['age']?.toString() ?? '';

        final gender = data['gender'];
        if (gender == 'Male') {
          _selectedGender = 'Erkek';
        } else if (gender == 'Female') {
          _selectedGender = 'Kadın';
        }

        // Eğer avatar_url varsa ilk slota koyalım (şimdilik tek fotoğraf destekli)
        if (data['avatar_url'] != null) {
          photos[0] = data['avatar_url'];
        }
      }
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  void _removeImage(int index) {
    setState(() {
      photos[index] = null;
    });
  }

  Future<void> _pickImage(int index) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fotoğraf Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.blue,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kamera',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.purple,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Galeri',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Performans için kaliteyi hafif düşürüyoruz
      );

      if (image != null) {
        setState(() {
          photos[index] = image.path;
        });
      }
    } catch (e) {
      debugPrint('Fotoğraf seçilirken hata oluştu: $e');
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Fotoğraf seçilemedi.',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          _isLoading
              ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
              : TextButton(
                onPressed: () async {
                  setState(() => _isLoading = true);

                  final api = ref.read(apiServiceProvider);
                  final result = await api.updateProfile(
                    alias: _aliasController.text.trim(),
                    bio: _bioController.text.trim(),
                    city: _selectedCity ?? '',
                    age: _ageController.text.trim(),
                    gender: _selectedGender,
                    avatar:
                        (photos[0] != null && !photos[0]!.startsWith('http'))
                            ? File(photos[0]!)
                            : null,
                    removeAvatar: photos[0] == null,
                  );

                  if (!context.mounted) return;
                  setState(() => _isLoading = false);

                  if (result['success']) {
                    // Başarılıysa veriyi yenile ve sayfadan çık
                    ref.invalidate(userProfileProvider);
                    // Değişikliğin hemen yansıması için küçük bir gecikme ekliyoruz
                    await Future.delayed(const Duration(milliseconds: 500));
                    ref.invalidate(userProfileProvider);

                    if (context.mounted) {
                      CustomSnackBar.show(
                        context: context,
                        message: 'Profil başarıyla güncellendi',
                        type: NotificationType.success,
                      );
                      Navigator.of(context).pop();
                    }
                  } else {
                    CustomSnackBar.show(
                      context: context,
                      message: result['message'] ?? 'Güncelleme başarısız',
                      type: NotificationType.error,
                    );
                  }
                },
                child: Text(
                  'Kaydet',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraflar Bölümü (6'lı Grid)
            Text(
              'Fotoğraflar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'En iyi fotoğraflarını yükleyerek eşleşme şansını artır.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75, // Dikdörtgen Tinder tarzı slotlar
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final photoUrl = photos[index];
                return _buildPhotoSlot(cs, photoUrl, index);
              },
            ),
            const SizedBox(height: 32),

            // Hakkımda Bölümü
            Text(
              'Hakkımda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Kendinden biraz bahset...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Temel Bilgiler
            Text(
              'Temel Bilgiler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              cs,
              'İsim / Takma Ad',
              'Takma adınızı girin',
              controller: _aliasController,
            ),
            const SizedBox(height: 12),
            _buildCityPickerField(
              cs,
              'Şehir',
              'Hangi şehirdesin?',
              _cities,
              _selectedCity,
              (val) => setState(() => _selectedCity = val),
            ),
            const SizedBox(height: 12),
            _buildGenderPickerField(cs),
            const SizedBox(height: 12),
            _buildInfoField(
              cs,
              'Yaş',
              'Kaç yaşındasın?',
              controller: _ageController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPickerField(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cinsiyet',
          style: TextStyle(
            fontSize: 13,
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'Erkek'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        _selectedGender == 'Erkek'
                            ? Colors.blue.withValues(alpha: 0.1)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _selectedGender == 'Erkek'
                              ? Colors.blue
                              : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color:
                            _selectedGender == 'Erkek'
                                ? Colors.blue
                                : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Erkek',
                        style: TextStyle(
                          color:
                              _selectedGender == 'Erkek'
                                  ? Colors.blue
                                  : cs.onSurface,
                          fontWeight:
                              _selectedGender == 'Erkek'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'Kadın'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        _selectedGender == 'Kadın'
                            ? Colors.pink.withValues(alpha: 0.1)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _selectedGender == 'Kadın'
                              ? Colors.pink
                              : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color:
                            _selectedGender == 'Kadın'
                                ? Colors.pink
                                : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kadın',
                        style: TextStyle(
                          color:
                              _selectedGender == 'Kadın'
                                  ? Colors.pink
                                  : cs.onSurface,
                          fontWeight:
                              _selectedGender == 'Kadın'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoField(
    ColorScheme cs,
    String label,
    String hint, {
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityPickerField(
    ColorScheme cs,
    String label,
    String hint,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCityPicker(cs, items, selectedValue, onChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedValue ?? hint,
                  style: TextStyle(
                    color:
                        selectedValue != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCityPicker(
    ColorScheme cs,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredItems =
                items
                    .where(
                      (item) => item.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Şehir Seç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Şehir ara...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: cs.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onChanged: (val) {
                            setSheetState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = item == selectedValue;
                          return ListTile(
                            title: Text(
                              item,
                              style: TextStyle(
                                color: isSelected ? cs.primary : cs.onSurface,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle,
                                      color: cs.primary,
                                    )
                                    : null,
                            onTap: () {
                              onChanged(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPhotoSlot(ColorScheme cs, String? photoUrl, int index) {
    final bool isMain = index == 0;

    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: isMain ? Border.all(color: cs.primary, width: 2) : null,
            ),
            child:
                photoUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(isMain ? 14 : 16),
                      child:
                          photoUrl.startsWith('http')
                              ? Image.network(
                                photoUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                              : Image.file(
                                File(photoUrl),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                    )
                    : Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: cs.onSurfaceVariant,
                        size: 32,
                      ),
                    ),
          ),

          // Eğer fotoğraf varsa ve sağ üstte "sil" ikonu çıkmasını istiyorsak
          if (photoUrl != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

          if (isMain)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ana Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
