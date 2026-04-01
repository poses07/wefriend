import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/venue_service.dart';
import '../utils/custom_snackbar.dart';

class CheckInBottomSheet extends StatefulWidget {
  final VoidCallback onCheckInSuccess;

  const CheckInBottomSheet({super.key, required this.onCheckInSuccess});

  @override
  State<CheckInBottomSheet> createState() => _CheckInBottomSheetState();
}

class _CheckInBottomSheetState extends State<CheckInBottomSheet> {
  final VenueService _venueService = VenueService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;
  bool _isCheckingIn = false;
  String? _error;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchNearbyVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNearbyVenues({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentPosition ??= await _determinePosition();

      final results = await _venueService.searchFoursquareVenues(
        query,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      if (mounted) {
        setState(() {
          _venues = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri kapalı. Lütfen açın.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı olarak reddedildi.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _performCheckIn(Map<String, dynamic> venue) async {
    if (_isCheckingIn) return;

    setState(() {
      _isCheckingIn = true;
    });

    final result = await _venueService.checkIn(
      venue['name'],
      fsqId: venue['fsq_id'],
    );

    if (!mounted) return;

    setState(() {
      _isCheckingIn = false;
    });

    if (result['success']) {
      CustomSnackBar.show(
        context: context,
        message: '${venue['name']} mekanında check-in yapıldı!',
        type: NotificationType.success,
      );
      widget.onCheckInSuccess();
      Navigator.of(context).pop();
    } else {
      CustomSnackBar.show(
        context: context,
        message: result['message'] ?? 'Check-in başarısız oldu.',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Şu an neredesin?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (val) => _fetchNearbyVenues(query: val),
              decoration: InputDecoration(
                hintText: 'Mekan ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    _searchController.clear();
                    _fetchNearbyVenues();
                  },
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Body
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorState(cs)
                    : _venues.isEmpty
                    ? _buildEmptyState(cs)
                    : _buildVenuesList(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Konum alınamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Bilinmeyen bir hata oluştu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchNearbyVenues(),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place_outlined, size: 64, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Yakınlarda mekan bulunamadı.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  _isCheckingIn
                      ? null
                      : () => _performCheckIn({
                        'name': _searchController.text,
                        'fsq_id':
                            'custom_${DateTime.now().millisecondsSinceEpoch}',
                      }),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text('"${_searchController.text}" olarak ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVenuesList(ColorScheme cs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _venues.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final venue = _venues[index];
        final iconUrl = venue['icon_url'] as String?;
        final distance = venue['distance'] as int?; // metre cinsinden

        String distanceStr = '';
        if (distance != null) {
          if (distance < 1000) {
            distanceStr = '${distance}m';
          } else {
            distanceStr = '${(distance / 1000).toStringAsFixed(1)}km';
          }
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                iconUrl != null && iconUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: iconUrl,
                      color:
                          cs.primary, // Foursquare ikonları genelde beyaz/siyah bg'lidir, renklendirilebilir
                      placeholder: (context, url) => const Icon(Icons.place),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.place),
                    )
                    : Icon(Icons.place, color: cs.primary),
          ),
          title: Text(
            venue['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${venue['type']} ${distanceStr.isNotEmpty ? '• $distanceStr uzakta' : ''}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ElevatedButton(
            onPressed: _isCheckingIn ? null : () => _performCheckIn(venue),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'Buradayım',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          onTap: _isCheckingIn ? null : () => _performCheckIn(venue),
        );
      },
    );
  }
}
