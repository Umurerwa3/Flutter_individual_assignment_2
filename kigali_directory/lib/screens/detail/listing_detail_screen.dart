import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/listing.dart';
import '../../providers/listing_provider.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Listing _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  Future<void> _launchNavigation() async {
    final lat = _listing.latitude;
    final lng = _listing.longitude;
    final label = Uri.encodeComponent(_listing.name);
    final candidates = <Uri>[
      Uri.parse('google.navigation:q=$lat,$lng&mode=d'),
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'),
    ];
    try {
      for (final url in candidates) {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (mounted) _snack('No map app found. Try on a physical device.', Colors.orange);
    } catch (_) {
      if (mounted) _snack('Navigation failed. Try on a physical device.', Colors.orange);
    }
  }

  Future<void> _callNumber() async {
    final url = Uri.parse('tel:${_listing.contact}');
    if (await canLaunchUrl(url)) launchUrl(url);
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  // ── Rating bottom-sheet ─────────────────────────────────────────────────────
  void _showRatingSheet() {
    int selected = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2D42),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Rate this Service',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_listing.name,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheet(() => selected = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < selected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF5A623),
                      size: 40,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Text(
                selected == 0 ? 'Tap a star to rate' : _ratingLabel(selected),
                style: TextStyle(
                    color: selected == 0
                        ? Colors.white38
                        : const Color(0xFFF5A623),
                    fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selected == 0
                      ? null
                      : () async {
                          Navigator.pop(sheetCtx);
                          await context
                              .read<ListingProvider>()
                              .rateListing(_listing, selected.toDouble());
                          if (mounted) {
                            _snack('Thank you for rating!',
                                const Color(0xFFF5A623));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Submit Rating',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    const labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent!'];
    return r < labels.length ? labels[r] : '';
  }

  @override
  Widget build(BuildContext context) {
    // Keep listing in sync with real-time Firestore updates
    final live = context
        .watch<ListingProvider>()
        .rawAllListings
        .where((l) => l.id == _listing.id)
        .firstOrNull;
    if (live != null) _listing = live;

    final pos = LatLng(_listing.latitude, _listing.longitude);
    final dist = context.read<ListingProvider>().distanceTo(_listing);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      // ── Transparent AppBar floats over the map ────────────────────────────
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.navigation_rounded,
                    color: Color(0xFFF5A623), size: 18),
                onPressed: _launchNavigation,
                tooltip: 'Get Directions',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map label ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF0D1B2A),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
            child: const Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: Color(0xFFF5A623), size: 16),
                SizedBox(width: 6),
                Text('Location on Map',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // ── Map — always fully visible, never collapses ───────────────────
          SizedBox(
            height: 230,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('place'),
                  position: pos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange),
                  infoWindow: InfoWindow(
                    title: _listing.name,
                    snippet: _listing.address,
                  ),
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),

          // ── Scrollable info card ──────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D1B2A),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category + rating row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_listing.category,
                              style: const TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        const Spacer(),
                        if (_listing.rating > 0) ...[
                          ..._buildStars(_listing.rating, size: 14),
                          const SizedBox(width: 5),
                          Text(_listing.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          if (_listing.ratingCount > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              '(${_listing.ratingCount} review${_listing.ratingCount == 1 ? '' : 's'})',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ] else
                          const Text('Not yet rated',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Name
                    Text(
                      _listing.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),

                    const SizedBox(height: 16),

                    // Location card — shows coordinates + distance
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2D42),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _infoRow(Icons.location_on_outlined, _listing.address),
                          const Divider(color: Colors.white12, height: 20),
                          _infoRow(
                            Icons.my_location_rounded,
                            '${_listing.latitude.toStringAsFixed(5)}, '
                                '${_listing.longitude.toStringAsFixed(5)}'
                                '${dist != null ? '  ·  ${dist < 1 ? '${(dist * 1000).round()} m' : '${dist.toStringAsFixed(1)} km'} away' : ''}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Contact
                    GestureDetector(
                      onTap: _callNumber,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2D42),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _infoRow(
                            Icons.phone_outlined, _listing.contact,
                            tappable: true),
                      ),
                    ),

                    const Divider(color: Colors.white12, height: 28),

                    // About
                    const Text('About',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(_listing.description,
                        style: const TextStyle(
                            color: Colors.white70, height: 1.65, fontSize: 14)),

                    const Divider(color: Colors.white12, height: 28),

                    // Date added
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Added on '
                          '${_listing.timestamp.day}/'
                          '${_listing.timestamp.month}/'
                          '${_listing.timestamp.year}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Get Directions (primary)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _launchNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.navigation_rounded,
                            color: Colors.white),
                        label: const Text('Get Directions',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Rate this Service (secondary)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _showRatingSheet,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFF5A623), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.star_outline_rounded,
                            color: Color(0xFFF5A623)),
                        label: const Text('Rate this Service',
                            style: TextStyle(
                                color: Color(0xFFF5A623),
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars(double rating, {double size = 13}) {
    return List.generate(5, (i) {
      final icon = i < rating.floor()
          ? Icons.star_rounded
          : (i < rating && rating - i >= 0.5)
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded;
      return Icon(icon, color: const Color(0xFFF5A623), size: size);
    });
  }

  Widget _infoRow(IconData icon, String text, {bool tappable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFF5A623), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                color: tappable ? const Color(0xFF1A8FE3) : Colors.white70,
                decoration: tappable
                    ? TextDecoration.underline
                    : TextDecoration.none,
                fontSize: 14,
                height: 1.4,
              )),
        ),
      ],
    );
  }
}
