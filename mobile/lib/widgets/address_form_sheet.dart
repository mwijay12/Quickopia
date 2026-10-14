import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../data/dar_locations_repository.dart';
import '../providers/auth_provider.dart';
import '../services/address_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'map_pin_picker.dart';

class AddressFormSheet extends StatefulWidget {
  final String profileId;

  const AddressFormSheet({super.key, required this.profileId});

  static Future<bool?> show(BuildContext context, {required String profileId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddressFormSheet(profileId: profileId),
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController(text: 'Home');
  final _landmarkCtrl = TextEditingController();
  final _houseDetailsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Cascading Location State
  String _selectedDistrict = 'Kinondoni';
  late List<DarWardInfo> _availableWards;
  DarWardInfo? _selectedWard;

  LatLng? _pinPosition;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _availableWards = DarLocationsRepository.getWards(_selectedDistrict);
    if (_availableWards.isNotEmpty) {
      _selectedWard = _availableWards.first;
      _pinPosition = _selectedWard!.center;
    }

    // Prepopulate phone number from authenticated profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profilePhone = context.read<AuthProvider>().profile?.phone;
      if (profilePhone != null && profilePhone.isNotEmpty && _phoneCtrl.text.isEmpty) {
        setState(() {
          _phoneCtrl.text = profilePhone;
        });
      }
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _landmarkCtrl.dispose();
    _houseDetailsCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onDistrictChanged(String? newDistrict) {
    if (newDistrict == null || newDistrict == _selectedDistrict) return;
    setState(() {
      _selectedDistrict = newDistrict;
      _availableWards = DarLocationsRepository.getWards(newDistrict);
      _selectedWard = _availableWards.isNotEmpty ? _availableWards.first : null;
      if (_selectedWard != null) {
        _pinPosition = _selectedWard!.center;
      }
    });
  }

  void _onWardChanged(DarWardInfo? newWard) {
    if (newWard == null) return;
    setState(() {
      _selectedWard = newWard;
      _pinPosition = newWard.center;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final addressService = AddressService();
      final wardName = _selectedWard?.wardName ?? 'Mikocheni';
      final formattedNeighborhood = '$wardName, $_selectedDistrict';
      final cleanPhone = Validators.normalizeTzPhone(_phoneCtrl.text.trim());

      final newAddressId = await addressService.saveAddress(
        profileId: widget.profileId,
        label: _labelCtrl.text.trim(),
        city: 'Dar es Salaam',
        neighborhood: formattedNeighborhood,
        landmark: _landmarkCtrl.text.trim(),
        houseDetails: _houseDetailsCtrl.text.trim().isEmpty
            ? null
            : _houseDetailsCtrl.text.trim(),
        latitude: _pinPosition?.latitude ?? _selectedWard?.center.latitude,
        longitude: _pinPosition?.longitude ?? _selectedWard?.center.longitude,
        isDefault: _isDefault,
        phone: cleanPhone,
      );

      if (_isDefault) {
        await addressService.setDefaultAddress(
          profileId: widget.profileId,
          addressId: newAddressId,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Add Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address Label Field & Quick Chips
              TextFormField(
                controller: _labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Address Label',
                  hintText: 'e.g. Home, Office, Parents',
                  prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Label'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Home', 'Office', 'Parents', 'Gym'].map((lbl) {
                  final isSelected = _labelCtrl.text == lbl;
                  return ChoiceChip(
                    label: Text(lbl),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryOrange : Colors.black87,
                    ),
                    onSelected: (_) => setState(() => _labelCtrl.text = lbl),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // SECTION: Cascading Dar es Salaam Locations
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'DAR ES SALAAM CASCADING LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // District Dropdown (Kinondoni, Ilala, Ubungo, Temeke, Kigamboni)
                    DropdownButtonFormField<String>(
                      key: ValueKey('sheet_dist_$_selectedDistrict'),
                      initialValue: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'District (Wilaya)',
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      items: DarLocationsRepository.districtNames.map((dist) {
                        return DropdownMenuItem(
                          value: dist,
                          child: Text(
                            dist,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: _onDistrictChanged,
                    ),
                    const SizedBox(height: 12),

                    // Ward Dropdown (Cascades based on selected district)
                    DropdownButtonFormField<DarWardInfo>(
                      key: ValueKey('sheet_ward_${_selectedWard?.wardName}'),
                      initialValue: _selectedWard,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Ward (Kata)',
                        prefixIcon: const Icon(Icons.holiday_village_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      items: _availableWards.map((w) {
                        return DropdownMenuItem(
                          value: w,
                          child: Text(
                            w.wardName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onWardChanged,
                    ),

                    // Popular Streets / Sub-wards chips
                    if (_selectedWard != null &&
                        _selectedWard!.popularStreets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Streets / Subwards in ${_selectedWard!.wardName}:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _selectedWard!.popularStreets.take(8).map((st) {
                          return ActionChip(
                            label: Text(
                              st,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                            onPressed: () {
                              setState(() {
                                if (_landmarkCtrl.text.isEmpty) {
                                  _landmarkCtrl.text = st;
                                } else if (!_landmarkCtrl.text.contains(st)) {
                                  _landmarkCtrl.text =
                                      '${_landmarkCtrl.text}, $st';
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Landmark / Street Field
              TextFormField(
                controller: _landmarkCtrl,
                decoration: InputDecoration(
                  labelText: 'Street / Landmark (e.g. Near Mwai Kibaki Rd)',
                  helperText: 'Primary navigation reference for delivery drivers',
                  prefixIcon: const Icon(Icons.signpost_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Landmark / Street'),
              ),
              const SizedBox(height: 12),

              // House / Gate Description Field
              TextFormField(
                controller: _houseDetailsCtrl,
                decoration: InputDecoration(
                  labelText: 'House / Gate / Floor Details (optional)',
                  hintText: 'e.g. Black gate opposite the pharmacy, 2nd floor',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Customer Phone Number Field (SAVED WITH ADDRESS)
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Namba ya Simu)',
                  hintText: 'e.g. 0712345678 or 255712345678',
                  helperText: 'Saved with address for courier arrival calls & SMS updates',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required for delivery';
                  }
                  if (!Validators.isValidTzPhone(v.trim())) {
                    return 'Please enter a valid TZ phone number (e.g. 0712345678)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interactive Map Pin Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pin location on Map',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    'Auto-centered on ${_selectedWard?.wardName ?? 'Ward'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MapPinPicker(
                initialPosition: _pinPosition,
                onPositionSelected: (pos) => setState(() => _pinPosition = pos),
              ),
              const SizedBox(height: 12),

              // Set as default switch
              SwitchListTile(
                value: _isDefault,
                activeThumbColor: AppTheme.primaryOrange,
                activeTrackColor: AppTheme.primaryOrange.withValues(alpha: 0.3),
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Set as default delivery address'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Address & Phone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
