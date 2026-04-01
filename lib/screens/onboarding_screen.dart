import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'shell.dart';
import '../providers.dart';
import '../utils/custom_snackbar.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Veriler
  String? _selectedGender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage;

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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Kullanıcıya Kamera veya Galeri seçeneği sunalım
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
                'Profil Fotoğrafı Seç',
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
                  _buildMediaOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  _buildMediaOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: Colors.purple,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });

      // Fotoğraf seçilince de kısa bir süre sonra direkt kayıt işlemini tetiklesin (Daha akıcı UX)
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _currentPage == 3) {
          _nextPage(); // 3. sayfadaysa bu direkt finishOnboarding'i çağırır
        }
      });
    }
  }

  Widget _buildMediaOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    // 1. Sayfa (Cinsiyet) Validasyonu
    if (_currentPage == 0 && _selectedGender == null) {
      CustomSnackBar.show(
        context: context,
        message: 'Lütfen cinsiyetinizi seçin.',
        type: NotificationType.error,
      );
      return;
    }

    // 2. Sayfa (Yaş ve Şehir) Validasyonu
    if (_currentPage == 1) {
      if (_ageController.text.isEmpty) {
        CustomSnackBar.show(
          context: context,
          message: 'Lütfen yaşınızı girin.',
          type: NotificationType.error,
        );
        return;
      }
      if (_cityController.text.isEmpty) {
        CustomSnackBar.show(
          context: context,
          message: 'Lütfen şehrinizi seçin.',
          type: NotificationType.error,
        );
        return;
      }
    }

    if (_currentPage < 3) {
      FocusScope.of(context).unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);

    final api = ref.read(apiServiceProvider);

    final result = await api.updateProfile(
      gender: _selectedGender,
      age: _ageController.text,
      city: _cityController.text,
      bio: _bioController.text,
      avatar: _profileImage,
    );

    if (!mounted) return;

    if (result['success']) {
      ref.invalidate(userProfileProvider); // Yeni verileri çekmek için
      setState(() => _isLoading = false);

      CustomSnackBar.show(
        context: context,
        message: 'Hoş geldin! Profilin başarıyla oluşturuldu.',
        type: NotificationType.success,
      );

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      setState(() => _isLoading = false);
      CustomSnackBar.show(
        context: context,
        message: result['message'] ?? 'Profil kaydedilemedi',
        type: NotificationType.error,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // İlerleme Çubuğu
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            index <= _currentPage
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Sayfalar
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Sadece butonla geçiş
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildGenderPage(cs),
                  _buildAgeCityPage(cs),
                  _buildBioPage(cs),
                  _buildPhotoPage(cs),
                ],
              ),
            ),

            // Alt Butonlar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Geri',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(_currentPage == 3 ? 'Tamamla' : 'İleri'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Cinsiyet Seçimi
  Widget _buildGenderPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.wc_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Cinsiyetin Nedir?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sana daha iyi eşleşmeler sunabilmemiz için gerekli.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _genderCard('Erkek', Icons.male_rounded, Colors.blue),
                _genderCard('Kadın', Icons.female_rounded, Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderCard(String gender, IconData icon, Color color) {
    final isSelected = _selectedGender == gender;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = gender);
        // Otomatik olarak sonraki sayfaya geç
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _currentPage == 0) {
            _nextPage();
          }
        });
      },
      child: Container(
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Yaş ve Şehir
  Widget _buildAgeCityPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Biraz Detay Ver',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yaşın',
                prefixIcon: const Icon(Icons.cake_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showCityPicker(cs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _cityController.text.isEmpty
                            ? 'Şehrin'
                            : _cityController.text,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _cityController.text.isEmpty
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityPicker(ColorScheme cs) {
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
            final filteredCities =
                _cities
                    .where(
                      (c) =>
                          c.toLowerCase().contains(searchQuery.toLowerCase()),
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
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = filteredCities[index];
                          final isSelected = city == _cityController.text;
                          return ListTile(
                            title: Text(
                              city,
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
                              setState(() {
                                _cityController.text = city;
                              });
                              Navigator.pop(context); // Şehir seçiciyi kapat

                              // Hem Yaş Hem Şehir seçildiyse otomatik 3. sayfaya geç
                              if (_ageController.text.isNotEmpty &&
                                  _cityController.text.isNotEmpty) {
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (mounted && _currentPage == 1) {
                                      _nextPage();
                                    }
                                  },
                                );
                              }
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

  // 3. Hakkımda
  Widget _buildBioPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Kendinden Bahset',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'İnsanların seni daha iyi tanımasını sağla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Hobilerin, sevdiğin şeyler...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Fotoğraf Yükleme
  Widget _buildPhotoPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Harika Görünüyorsun!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Profilini tamamlamak için harika bir fotoğraf seç.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  image:
                      _profileImage != null
                          ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                          : null,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child:
                    _profileImage == null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 48,
                              color: cs.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fotoğraf Seç',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
