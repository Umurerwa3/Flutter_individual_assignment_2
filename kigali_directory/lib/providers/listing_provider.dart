import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';

enum ListingStatus { idle, loading, error }

class ListingProvider extends ChangeNotifier {
  final _service = ListingService();
  StreamSubscription<List<Listing>>? _allSub;
  StreamSubscription<List<Listing>>? _mineSub;

  List<Listing> _all = [];
  List<Listing> _mine = [];
  ListingStatus _status = ListingStatus.idle;
  String _errorMsg = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Position? _position;

  List<Listing> get allListings => _filtered(_all);
  List<Listing> get rawAllListings => _all;
  List<Listing> get myListings => _mine;
  bool get isLoading => _status == ListingStatus.loading;
  String get errorMsg => _errorMsg;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get hasLocation => _position != null;

  List<Listing> _filtered(List<Listing> src) {
    return src.where((l) {
      final matchSearch = _searchQuery.isEmpty ||
          l.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'All' ||
          l.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  /// Returns distance in km from current position to [l], or null if unknown.
  double? distanceTo(Listing l) {
    if (_position == null) return null;
    final metres = Geolocator.distanceBetween(
      _position!.latitude, _position!.longitude,
      l.latitude, l.longitude,
    );
    return metres / 1000;
  }

  /// Attempts to get the device's current location (silent – no crash on failure).
  Future<void> fetchLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      _position = pos;
      notifyListeners();
    } catch (_) {
      // Location unavailable (emulator / permission denied) – silent.
    }
  }

  void listenAll() {
    _allSub?.cancel();
    _allSub = _service.listingsStream().listen((list) {
      _all = list;
      notifyListeners();
    }, onError: (_) {});
  }

  void listenMine(String uid) {
    _mineSub?.cancel();
    _mineSub = _service.myListingsStream(uid).listen((list) {
      _mine = list;
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _allSub?.cancel();
    _mineSub?.cancel();
    super.dispose();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  Future<void> createListing(Listing l) async {
    _status = ListingStatus.loading;
    _errorMsg = '';
    notifyListeners();
    try {
      await _service.createListing(l).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Save took too long'),
      );
      _status = ListingStatus.idle;
      _errorMsg = '';
    } on TimeoutException {
      _errorMsg = 'Save timed out. Check internet and Firestore rules.';
      _status = ListingStatus.error;
    } on FirebaseException catch (e) {
      _errorMsg = 'Firestore error (${e.code}): ${e.message ?? 'Unable to save'}';
      _status = ListingStatus.error;
    } catch (e) {
      _errorMsg = e.toString();
      _status = ListingStatus.error;
    }
    notifyListeners();
  }

  Future<void> updateListing(Listing l) async {
    _status = ListingStatus.loading;
    _errorMsg = '';
    notifyListeners();
    try {
      await _service.updateListing(l).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Update timed out'),
      );
      _status = ListingStatus.idle;
      _errorMsg = '';
    } on FirebaseException catch (e) {
      _errorMsg = 'Update failed (${e.code}): ${e.message ?? 'Check permissions'}';
      _status = ListingStatus.error;
    } on TimeoutException catch (e) {
      _errorMsg = 'Update timeout: ${e.message}';
      _status = ListingStatus.error;
    } catch (e) {
      _errorMsg = 'Update error: ${e.toString()}';
      _status = ListingStatus.error;
    }
    notifyListeners();
  }

  Future<void> deleteListing(String id) async {
    _status = ListingStatus.loading;
    _errorMsg = '';
    notifyListeners();
    try {
      await _service.deleteListing(id).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Delete took too long'),
      );
      _status = ListingStatus.idle;
      _errorMsg = '';
    } on TimeoutException {
      _errorMsg = 'Delete timed out. Check internet and Firestore rules.';
      _status = ListingStatus.error;
    } on FirebaseException catch (e) {
      _errorMsg = 'Firestore error (${e.code}): ${e.message ?? 'Unable to delete'}';
      _status = ListingStatus.error;
    } catch (e) {
      _errorMsg = e.toString();
      _status = ListingStatus.error;
    }
    notifyListeners();
  }

  /// Computes a running average and persists the new rating to Firestore.
  Future<void> rateListing(Listing listing, double userRating) async {
    if (listing.id == null) return;
    try {
      final newCount = listing.ratingCount + 1;
      final newAvg = ((listing.rating * listing.ratingCount) + userRating) / newCount;
      await _service.rateListing(
        listing.id!,
        double.parse(newAvg.toStringAsFixed(1)),
        newCount,
      );
    } catch (_) {
      // Fail silently – rating is a bonus feature
    }
  }
}
