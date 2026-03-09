import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../detail/listing_detail_screen.dart';
import 'listing_form_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final provider = ctx.watch<ListingProvider>();
    final uid = ctx.read<AuthProvider>().user?.uid ?? '';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text('My Listings',
                    style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => ListingFormScreen(uid: uid),
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.myListings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_location_alt_outlined,
                          size: 60, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text("You haven't added any listings yet",
                          style: TextStyle(color: Colors.white38)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => ListingFormScreen(uid: uid),
                          )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                          ),
                          child: const Text('Create First Listing',
                            style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.myListings.length,
                    itemBuilder: (_, i) {
                      final l = provider.myListings[i];
                      return Stack(
                        children: [
                          ListingCard(
                            listing: l,
                            distance: provider.distanceTo(l),
                            onTap: () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(listing: l),
                            )),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: Row(
                              children: [
                                _actionBtn(Icons.edit_outlined, const Color(0xFF1A8FE3), () {
                                  Navigator.push(ctx, MaterialPageRoute(
                                    builder: (_) => ListingFormScreen(uid: uid, existing: l),
                                  ));
                                }),
                                const SizedBox(width: 4),
                                _actionBtn(Icons.delete_outline, Colors.red, () async {
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A2D42),
                                      title: const Text('Delete Listing',
                                        style: TextStyle(color: Colors.white)),
                                      content: Text('Delete "${l.name}"?',
                                        style: const TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    // ignore: use_build_context_synchronously
                                    ctx.read<ListingProvider>().deleteListing(l.id!);
                                  }
                                }),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withAlpha(38),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}