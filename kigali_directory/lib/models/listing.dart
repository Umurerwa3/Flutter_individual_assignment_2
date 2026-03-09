import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String? id;
  final String name;
  final String category;
  final String address;
  final String contact;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final DateTime timestamp;
  final double rating;
  final int ratingCount;

  Listing({
    this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contact,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.timestamp,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  static const List<String> categories = [
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
    'Pharmacy',
    'Bank',
    'Hotel',
    'Utility Office',
  ];

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'address': address,
    'contact': contact,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'createdBy': createdBy,
    'timestamp': Timestamp.fromDate(timestamp),
    'rating': rating,
    'ratingCount': ratingCount,
  };

  factory Listing.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      address: d['address'] ?? '',
      contact: d['contact'] ?? '',
      description: d['description'] ?? '',
      latitude: (d['latitude'] ?? -1.9441).toDouble(),
      longitude: (d['longitude'] ?? 30.0619).toDouble(),
      createdBy: d['createdBy'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (d['rating'] ?? 0.0).toDouble(),
      ratingCount: (d['ratingCount'] ?? 0) as int,
    );
  }

  Listing copyWith({
    String? id, String? name, String? category, String? address,
    String? contact, String? description, double? latitude,
    double? longitude, String? createdBy, DateTime? timestamp,
    double? rating, int? ratingCount,
  }) => Listing(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    address: address ?? this.address,
    contact: contact ?? this.contact,
    description: description ?? this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    createdBy: createdBy ?? this.createdBy,
    timestamp: timestamp ?? this.timestamp,
    rating: rating ?? this.rating,
    ratingCount: ratingCount ?? this.ratingCount,
  );
}
