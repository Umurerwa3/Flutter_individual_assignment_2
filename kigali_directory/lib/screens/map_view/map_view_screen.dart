import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/listing.dart';
import '../../providers/listing_provider.dart';
import '../detail/listing_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  Listing? _selected;
  GoogleMapController? _mapController;

  // Track how many listings we last fitted so we re-fit when data arrives
  int _fittedForCount = -1;

  static const _kigali = CameraPosition(
    target: LatLng(-1.9441, 30.0619),
    zoom: 12,
  );

  // ── Markers ────────────────────────────────────────────────────────────────
  Set<Marker> _buildMarkers(List<Listing> listings) {
    return listings.map((l) => Marker(
      markerId: MarkerId(l.id ?? l.name),
      position: LatLng(l.latitude, l.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(title: l.name, snippet: l.category),
      onTap: () => setState(() => _selected = l),
    )).toSet();
  }

  // ── Fit camera so EVERY marker is visible ─────────────────────────────────
  Future<void> _fitAll(List<Listing> listings) async {
    if (_mapController == null || listings.isEmpty) return;

    if (listings.length == 1) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(listings[0].latitude, listings[0].longitude), 15));
      return;
    }

    final lats = listings.map((l) => l.latitude);
    final lngs = listings.map((l) => l.longitude);
    const pad = 0.025;

    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(lats.reduce(min) - pad, lngs.reduce(min) - pad),
        northeast: LatLng(lats.reduce(max) + pad, lngs.reduce(max) + pad),
      ),
      64,
    ));
  }

  Future<void> _launchDirections(Listing l) async {
    final candidates = <Uri>[
      Uri.parse(
          'google.navigation:q=${l.latitude},${l.longitude}&mode=d'),
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${l.latitude},${l.longitude}&travelmode=driving'),
    ];
    for (final url in candidates) {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = context.watch<ListingProvider>().rawAllListings;

    // Re-fit whenever the listing count changes and the controller is ready
    if (_mapController != null &&
        listings.isNotEmpty &&
        listings.length != _fittedForCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _fitAll(listings);
        if (mounted) setState(() => _fittedForCount = listings.length);
      });
    }

    final cardVisible = _selected != null;

    return Stack(
      children: [
        // ── Full-screen Google Map ──────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: _kigali,
          markers: _buildMarkers(listings),
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          onTap: (_) => setState(() => _selected = null),
          onMapCreated: (controller) {
            _mapController = controller;
            // Delay slightly so the map has rendered before animating
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted && listings.isNotEmpty) {
                _fitAll(listings);
                setState(() => _fittedForCount = listings.length);
              }
            });
          },
        ),

        // ── Title bar overlay ───────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(225, 13, 27, 42),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded,
                              color: Color(0xFFF5A623), size: 18),
                          const SizedBox(width: 10),
                          const Text(
                            'Map View',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A623).withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${listings.length} place${listings.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Color(0xFFF5A623),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Orange zoom + fit controls ──────────────────────────────────────
        Positioned(
          right: 16,
          bottom: cardVisible ? 220 : 24,
          child: Column(
            children: [
              _mapBtn(Icons.add,
                  () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
              const SizedBox(height: 8),
              _mapBtn(Icons.remove,
                  () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
              const SizedBox(height: 8),
              _mapBtn(Icons.fit_screen_rounded, () => _fitAll(listings),
                  tooltip: 'Show all listings'),
            ],
          ),
        ),

        // ── Selected listing card ─────────────────────────────────────────
        if (_selected != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 72,
            child: _ListingCard(
              listing: _selected!,
              onClose: () => setState(() => _selected = null),
              onDirections: () => _launchDirections(_selected!),
              onView: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(listing: _selected!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ── Extracted card widget ────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback onView;

  const _ListingCard({
    required this.listing,
    required this.onClose,
    required this.onDirections,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name row
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon(listing.category),
                    color: const Color(0xFFF5A623), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(listing.category,
                        style: const TextStyle(
                            color: Color(0xFFF5A623), fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  listing.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),

          // Stars
          if (listing.rating > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                ..._stars(listing.rating),
                const SizedBox(width: 4),
                Text(listing.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Color(0xFFF5A623),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons side by side
          Row(
            children: [
              // Get Directions — launches turn-by-turn navigation
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onDirections,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Directions',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // View Details
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onView,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF5A623)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('View Details',
                        style: TextStyle(
                            color: Color(0xFFF5A623),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _stars(double rating) => List.generate(5, (i) {
        final icon = i < rating.floor()
            ? Icons.star_rounded
            : (i < rating && rating - i >= 0.5)
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, color: const Color(0xFFF5A623), size: 13);
      });

  IconData _icon(String cat) {
    switch (cat) {
      case 'Hospital':           return Icons.local_hospital_outlined;
      case 'Police Station':     return Icons.local_police_outlined;
      case 'Library':            return Icons.local_library_outlined;
      case 'Restaurant':         return Icons.restaurant_outlined;
      case 'Café':               return Icons.coffee_outlined;
      case 'Park':               return Icons.park_outlined;
      case 'Tourist Attraction': return Icons.attractions_outlined;
      case 'Pharmacy':           return Icons.medication_outlined;
      case 'Bank':               return Icons.account_balance_outlined;
      case 'Hotel':              return Icons.hotel_outlined;
      case 'Utility Office':     return Icons.electrical_services_outlined;
      default:                   return Icons.place_outlined;
    }
  }
}
