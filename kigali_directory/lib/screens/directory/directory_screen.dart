import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/category_chip.dart';
import '../detail/listing_detail_screen.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListingProvider>();
    final authProfile = context.watch<AuthProvider>().profile;
    final firstName = authProfile?.displayName.split(' ').first ?? '';
    final cats = ['All', ...Listing.categories];
    final listings = provider.allListings;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName.isNotEmpty
                            ? '$_greeting, $firstName!'
                            : '$_greeting!',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kigali Directory',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        provider.hasLocation
                            ? 'Services & places near you'
                            : 'Find services & places in Kigali',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2D42),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: provider.setSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a service...',
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: true,
                fillColor: const Color(0xFF1A2D42),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Category chips (horizontal scroll) ──────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = cats[i];
                final count = cat == 'All'
                    ? null
                    : provider.rawAllListings
                        .where((l) => l.category == cat)
                        .length;
                return CategoryChip(
                  label: cat,
                  count: count,
                  selected: provider.selectedCategory == cat,
                  onTap: () => provider.setCategory(cat),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Section label ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.hasLocation ? 'Near You' : 'All Services',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${listings.length} result${listings.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Listings ─────────────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFF5A623)),
                  )
                : listings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 56, color: Colors.white24),
                            const SizedBox(height: 14),
                            const Text(
                              'No listings found',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 15),
                            ),
                            if (provider.searchQuery.isNotEmpty ||
                                provider.selectedCategory != 'All') ...[
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  provider.setSearch('');
                                  provider.setCategory('All');
                                },
                                child: const Text(
                                  'Clear filters',
                                  style: TextStyle(
                                      color: Color(0xFFF5A623)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        itemCount: listings.length,
                        itemBuilder: (_, i) {
                          final l = listings[i];
                          return ListingCard(
                            listing: l,
                            distance: provider.distanceTo(l),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ListingDetailScreen(listing: l),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
