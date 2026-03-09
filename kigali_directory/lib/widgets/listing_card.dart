import 'package:flutter/material.dart';
import '../models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final double? distance;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2D42),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForCategory(listing.category),
                  color: const Color(0xFFF5A623),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stars + rating
                    Row(
                      children: [
                        ..._stars(listing.rating),
                        const SizedBox(width: 5),
                        Text(
                          listing.rating > 0
                              ? listing.rating.toStringAsFixed(1)
                              : 'New',
                          style: const TextStyle(
                            color: Color(0xFFF5A623),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (listing.ratingCount > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${listing.ratingCount})',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Address + distance
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white38,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${distance!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _stars(double rating) {
    return List.generate(5, (i) {
      IconData icon;
      if (i < rating.floor()) {
        icon = Icons.star_rounded;
      } else if (i < rating && rating - i >= 0.5) {
        icon = Icons.star_half_rounded;
      } else {
        icon = Icons.star_outline_rounded;
      }
      return Icon(icon, color: const Color(0xFFF5A623), size: 13);
    });
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Hospital':          return Icons.local_hospital_outlined;
      case 'Police Station':    return Icons.local_police_outlined;
      case 'Library':           return Icons.local_library_outlined;
      case 'Restaurant':        return Icons.restaurant_outlined;
      case 'Café':              return Icons.coffee_outlined;
      case 'Park':              return Icons.park_outlined;
      case 'Tourist Attraction':return Icons.attractions_outlined;
      case 'Pharmacy':          return Icons.medication_outlined;
      case 'Bank':              return Icons.account_balance_outlined;
      case 'Hotel':             return Icons.hotel_outlined;
      case 'Utility Office':    return Icons.electrical_services_outlined;
      default:                  return Icons.place_outlined;
    }
  }
}
