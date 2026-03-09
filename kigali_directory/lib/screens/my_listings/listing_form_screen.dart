import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/listing.dart';
import '../../providers/listing_provider.dart';

class ListingFormScreen extends StatefulWidget {
  final String uid;
  final Listing? existing;
  const ListingFormScreen({super.key, required this.uid, this.existing});
  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _contact, _desc, _lat, _lng;
  late String _category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _contact = TextEditingController(text: e?.contact ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _lat = TextEditingController(text: e?.latitude.toString() ?? '-1.9441');
    _lng = TextEditingController(text: e?.longitude.toString() ?? '30.0619');
    _category = e?.category ?? Listing.categories.first;
  }

  @override
  void dispose() {
    _name.dispose(); _address.dispose(); _contact.dispose();
    _desc.dispose(); _lat.dispose(); _lng.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final listing = Listing(
      id: widget.existing?.id,
      name: _name.text.trim(),
      category: _category,
      address: _address.text.trim(),
      contact: _contact.text.trim(),
      description: _desc.text.trim(),
      latitude: double.tryParse(_lat.text) ?? -1.9441,
      longitude: double.tryParse(_lng.text) ?? 30.0619,
      createdBy: widget.uid,
      timestamp: widget.existing?.timestamp ?? DateTime.now(), // Preserve original timestamp on edit
    );
    final prov = context.read<ListingProvider>();
    if (widget.existing == null) {
      await prov.createListing(listing);
    } else {
      await prov.updateListing(listing);
    }
    if (mounted) {
      if (prov.errorMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${prov.errorMsg}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing == null ? 'Listing created!' : 'Listing updated!'),
            backgroundColor: const Color(0xFFF5A623),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final loading = ctx.watch<ListingProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Listing' : 'Edit Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_name, 'Place / Service Name', Icons.place_outlined),
              const SizedBox(height: 14),
              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2D42),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF1A2D42),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
                    style: const TextStyle(color: Colors.white),
                    items: Listing.categories.map((c) => DropdownMenuItem(
                      value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _field(_address, 'Address', Icons.location_on_outlined),
              const SizedBox(height: 14),
              _field(_contact, 'Contact Number', Icons.phone_outlined,
                type: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_desc, 'Description', Icons.description_outlined, maxLines: 3),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _field(_lat, 'Latitude', Icons.gps_fixed,
                    type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lng, 'Longitude', Icons.gps_not_fixed,
                    type: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.existing == null ? 'Create Listing' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white38),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}