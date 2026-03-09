import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing.dart';

class ListingService {
  final _col = FirebaseFirestore.instance.collection('listings');

  // Real-time stream of ALL listings
  Stream<List<Listing>> listingsStream() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Listing.fromDoc).toList());
  }

  // Real-time stream of listings by current user
  Stream<List<Listing>> myListingsStream(String uid) {
    return _col
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map(Listing.fromDoc).toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  Future<void> createListing(Listing l) async {
    await _col.add(l.toMap());
  }

  Future<void> updateListing(Listing l) async {
    await _col.doc(l.id).update(l.toMap());
  }

  Future<void> deleteListing(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> rateListing(String id, double newAvgRating, int newCount) async {
    await _col.doc(id).update({
      'rating': newAvgRating,
      'ratingCount': newCount,
    });
  }
}