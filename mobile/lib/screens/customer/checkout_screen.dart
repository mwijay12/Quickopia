import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/dar_locations_repository.dart';
import '../../models/address_model.dart';
import '../../models/branch_model.dart';
import '../../models/checkout_data_model.dart';
import '../../models/delivery_zone_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_history_provider.dart';
import '../../services/address_service.dart';
import '../../services/branch_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/fulfillment_toggle.dart';
import '../../widgets/map_pin_picker.dart';
import '../../widgets/payment_method_selector.dart';
import 'order_success_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  String _fulfillmentType = 'delivery';
  String _paymentMethod = 'cod';

  final _cityCtrl = TextEditingController(text: 'Dar es Salaam');
  final _neighborhoodCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _houseDetailsCtrl = TextEditingController();
  final _driverNotesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _addressLabelCtrl = TextEditingController(text: 'Home');

  String _substitutionPreference = 'call_first';
  String? _selectedDistrict = 'Kinondoni';
  DarWardInfo? _selectedWard;
  LatLng? _pinPosition;
  bool _saveAddress = false;
  bool _isPlacingOrder = false;

  Branch? _branch;
  List<Address> _savedAddresses = [];
  String? _selectedSavedAddressId;
  bool _loadingContext = true;

  DeliveryZone _selectedZone = DeliveryZone.defaultZones[1];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final auth = context.read<AuthProvider>();
    if (auth.profile?.phone != null && auth.profile!.phone!.isNotEmpty) {
      _phoneCtrl.text = auth.profile!.phone!;
    }

    try {
      final branch = await BranchService().fetchPrimaryBranch();
      final addresses = auth.profile != null
          ? await AddressService().fetchSavedAddresses(auth.profile!.id)
          : <Address>[];
      if (mounted) {
        setState(() {
          _branch = branch;
          _savedAddresses = addresses;
          _loadingContext = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingContext = false);
      }
    }
  }

  void _applySavedAddress(Address address) {
    final matchedWard = DarLocationsRepository.findWard(address.neighborhood);
    setState(() {
      _selectedSavedAddressId = address.id;
      _cityCtrl.text = address.city;
      _neighborhoodCtrl.text = address.neighborhood;
      _landmarkCtrl.text = address.landmark;
      _houseDetailsCtrl.text = address.houseDetails ?? '';
      if (address.phone != null && address.phone!.isNotEmpty) {
        _phoneCtrl.text = address.phone!;
      }
      if (matchedWard != null) {
        _selectedWard = matchedWard;
        _selectedZone = DeliveryZone.findByWard(matchedWard.wardName);
        for (final entry in DarLocationsRepository.districts.entries) {
          if (entry.value.any((w) => w.wardName == matchedWard.wardName)) {
            _selectedDistrict = entry.key;
            break;
          }
        }
      }
      if (address.latitude != null && address.longitude != null) {
        _pinPosition = LatLng(address.latitude!, address.longitude!);
      } else if (matchedWard != null) {
        _pinPosition = matchedWard.center;
      }
    });
  }

  double get _deliveryFee =>
      _fulfillmentType == 'delivery' ? _selectedZone.totalDeliveryFeeTzs : 0.0;

  Future<void> _placeOrder() async {
    if (_fulfillmentType == 'delivery' && !_formKey.currentState!.validate()) return;
    if (_fulfillmentType == 'pickup' && !Validators.isValidTzPhone(_phoneCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number for pickup contact.'),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    if (auth.profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again before placing an order.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      if (_saveAddress && _fulfillmentType == 'delivery') {
        final label = _addressLabelCtrl.text.trim().isNotEmpty
            ? _addressLabelCtrl.text.trim()
            : (_landmarkCtrl.text.isNotEmpty ? _landmarkCtrl.text.trim() : 'Saved Address');

        await AddressService().saveAddress(
          profileId: auth.profile!.id,
          label: label,
          city: _cityCtrl.text.trim(),
          neighborhood: _neighborhoodCtrl.text.trim(),
          landmark: _landmarkCtrl.text.trim(),
          houseDetails: _houseDetailsCtrl.text.trim(),
          latitude: _pinPosition?.latitude,
          longitude: _pinPosition?.longitude,
          phone: Validators.normalizeTzPhone(_phoneCtrl.text.trim()),
        );
      }

      final checkoutData = CheckoutData(
        fulfillmentType: _fulfillmentType,
        city: _fulfillmentType == 'delivery' ? _cityCtrl.text.trim() : null,
        neighborhood:
            _fulfillmentType == 'delivery' ? _neighborhoodCtrl.text.trim() : null,
        landmark:
            _fulfillmentType == 'delivery' ? _landmarkCtrl.text.trim() : null,
        houseDetails: _fulfillmentType == 'delivery'
            ? [
                if (_houseDetailsCtrl.text.trim().isNotEmpty) _houseDetailsCtrl.text.trim(),
                if (_driverNotesCtrl.text.trim().isNotEmpty)
                  'Maagizo: ${_driverNotesCtrl.text.trim()}',
                'Upendeleo: ${_substitutionPreference == "substitute" ? "Weka inayofanana" : _substitutionPreference == "refund" ? "Rudisha pesa" : "Piga simu kwanza"}',
              ].where((s) => s.isNotEmpty).join(' • ')
            : null,
        latitude: _pinPosition?.latitude,
        longitude: _pinPosition?.longitude,
        customerPhone: Validators.normalizeTzPhone(_phoneCtrl.text.trim()),
        paymentMethod: _paymentMethod,
        paymentReference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        subtotalTzs: cart.subtotalTzs,
        deliveryFeeTzs: _deliveryFee,
        totalTzs: cart.subtotalTzs + _deliveryFee,
      );

      // Resilient branch resolution
      if (_branch == null) {
        try {
          _branch = await BranchService().fetchPrimaryBranch();
        } catch (_) {}
      }
      final branchId = _branch?.id ?? '';
      final order = await OrderService().placeOrder(
        customerId: auth.profile!.id,
        branchId: branchId,
        checkoutData: checkoutData,
        cartItems: cart.items,
      );

      // Refresh order history in background so My Orders tab has the new order immediately
      if (mounted) {
        context.read<OrderHistoryProvider>().load(auth.profile!.id);

        // Trigger native notification (seen on Lock Screen) and In-App top banner ("ziwe juu")
        NotificationService().showOrderNotification(
          title: 'Order Confirmed! #${order.orderNumber}',
          body: 'Your supermarket order of ${CurrencyFormatter.formatTzs(order.totalAmountTzs)} has been placed successfully.',
          payload: order.id,
          context: context,
        );
      }

      // Only clear cart on confirmed success
      cart.clearCart();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } on OrderPlacementException catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order Could Not Be Placed'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _landmarkCtrl.dispose();
    _houseDetailsCtrl.dispose();
    _driverNotesCtrl.dispose();
    _phoneCtrl.dispose();
    _referenceCtrl.dispose();
    _addressLabelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (_loadingContext) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FulfillmentToggle(
              selected: _fulfillmentType,
              onChanged: (v) => setState(() => _fulfillmentType = v),
            ),
            const SizedBox(height: 20),

            // Store Pickup Section
            if (_fulfillmentType == 'pickup') ...[
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: AppTheme.primaryNavy),
                          const SizedBox(width: 8),
                          Text(
                            _branch?.name ?? 'Quickopia Pilot Store',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_branch?.neighborhood ?? "Mikocheni"}, ${_branch?.city ?? "Dar es Salaam"}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_branch?.landmark != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _branch!.landmark!,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Store Pickup: FREE (TZS 0)',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Prep: ~20 mins',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Contact Phone Number',
                  hintText: '0712345678 or +255712345678',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || !Validators.isValidTzPhone(v))
                    ? 'Enter a valid Tanzanian phone number'
                    : null,
              ),
            ],

            // Doorstep Delivery Section
            if (_fulfillmentType == 'delivery') ...[
              if (_savedAddresses.isNotEmpty) ...[
                const Text(
                  'Saved Delivery Locations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _selectedSavedAddressId,
                  onChanged: (id) {
                    if (id != null) {
                      final addr = _savedAddresses.firstWhere((a) => a.id == id);
                      _applySavedAddress(addr);
                    }
                  },
                  child: Column(
                    children: _savedAddresses
                        .map((a) => RadioListTile<String>(
                              value: a.id,
                              activeColor: AppTheme.primaryNavy,
                              title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${a.neighborhood}, ${a.landmark}'),
                            ))
                        .toList(),
                  ),
                ),
                const Divider(height: 24),
              ],
              const Text(
                'Delivery Address (Dar es Salaam)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.near_me, size: 20, color: Colors.blue.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select your District and Ward below to auto-position the map, then tap to mark your exact gate or doorstep.',
                        style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // District Dropdown
              DropdownButtonFormField<String>(
                key: ValueKey('district_$_selectedDistrict'),
                initialValue: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: 'District (Wilaya)',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                items: DarLocationsRepository.districtNames
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDistrict = val;
                      _selectedWard = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Ward Dropdown
              DropdownButtonFormField<DarWardInfo>(
                key: ValueKey('ward_${_selectedWard?.wardName}'),
                initialValue: _selectedWard,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Ward / Area (Kata)',
                  hintText: 'Select Ward (e.g. Mikocheni, Sinza, Masaki...)',
                  prefixIcon: const Icon(Icons.pin_drop_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                items: (_selectedDistrict != null
                        ? DarLocationsRepository.getWardsForDistrict(_selectedDistrict!)
                        : <DarWardInfo>[])
                    .map((w) => DropdownMenuItem(
                          value: w,
                          child: Text(w.wardName, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (ward) {
                  if (ward != null) {
                    setState(() {
                      _selectedWard = ward;
                      _neighborhoodCtrl.text = ward.wardName;
                      _pinPosition = ward.center;
                      _selectedZone = DeliveryZone.findByWard(ward.wardName);
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              // Dynamic Delivery Zone & Fuel Surcharge Tier Card
              Card(
                elevation: 0,
                color: Colors.amber.shade50.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.two_wheeler, size: 18, color: AppTheme.primaryNavy),
                              const SizedBox(width: 8),
                              Text(
                                _selectedZone.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              CurrencyFormatter.formatTzs(_selectedZone.totalDeliveryFeeTzs),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Base fee: ${CurrencyFormatter.formatTzs(_selectedZone.baseDeliveryFeeTzs)} • Rider fuel stipend: ${CurrencyFormatter.formatTzs(_selectedZone.fuelSurchargeTzs)} • Est: ${_selectedZone.estimatedMinutes}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),

              // Popular Streets / Mitaa Quick Chips
              if (_selectedWard != null && _selectedWard!.popularStreets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Streets & subwards in ${_selectedWard!.wardName} (tap to set as landmark):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedWard!.popularStreets.map((street) {
                    return ActionChip(
                      label: Text(street, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.add_location_alt_outlined, size: 14),
                      backgroundColor: Colors.blue.shade50,
                      onPressed: () {
                        setState(() {
                          _landmarkCtrl.text = street;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),

              TextFormField(
                controller: _neighborhoodCtrl,
                decoration: InputDecoration(
                  labelText: 'Area / Neighborhood',
                  hintText: 'e.g. Mikocheni B, Sinza Kumekucha',
                  prefixIcon: const Icon(Icons.holiday_village_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Neighborhood'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _landmarkCtrl,
                decoration: InputDecoration(
                  labelText: 'Nearby Landmark / Alama Iliyo Karibu',
                  hintText: 'e.g. Opposite TotalEnergies, Karibu na Msikiti / Kanisa',
                  helperText: 'Alama kuu dereva atakayotumia kufika haraka',
                  prefixIcon: const Icon(Icons.signpost_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Landmark'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _houseDetailsCtrl,
                decoration: InputDecoration(
                  labelText: 'Maelezo ya Nyumba / Geti (House Description)',
                  hintText: 'e.g. Geti jeusi la pili kushoto, ukuta mweupe',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _driverNotesCtrl,
                decoration: InputDecoration(
                  labelText: 'Delivery Instructions / Maagizo kwa Dereva',
                  hintText: 'e.g. Piga hodi geti la pili, mpe mlinzi',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  'Piga simu ukifika',
                  'Acha getini / kwa mlinzi',
                  'Piga hodi / kengele',
                  'Niko ghorofani',
                ].map((hint) => ActionChip(
                  label: Text(hint, style: const TextStyle(fontSize: 11)),
                  avatar: const Icon(Icons.add, size: 12),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final current = _driverNotesCtrl.text.trim();
                    setState(() {
                      _driverNotesCtrl.text = current.isEmpty ? hint : '$current, $hint';
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 0,
                color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  side: BorderSide(color: Colors.blueGrey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.primaryNavy),
                          SizedBox(width: 8),
                          Text(
                            'Iwapo Bidhaa Imeisha / Item Substitution',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Piga simu kwanza', style: TextStyle(fontSize: 12)),
                            selected: _substitutionPreference == 'call_first',
                            onSelected: (s) => setState(() => _substitutionPreference = 'call_first'),
                          ),
                          ChoiceChip(
                            label: const Text('Weka inayofanana', style: TextStyle(fontSize: 12)),
                            selected: _substitutionPreference == 'substitute',
                            onSelected: (s) => setState(() => _substitutionPreference = 'substitute'),
                          ),
                          ChoiceChip(
                            label: const Text('Rudisha pesa', style: TextStyle(fontSize: 12)),
                            selected: _substitutionPreference == 'refund',
                            onSelected: (s) => setState(() => _substitutionPreference = 'refund'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number',
                  hintText: '0712345678 or +255712345678',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || !Validators.isValidTzPhone(v))
                    ? 'Enter a valid Tanzanian phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pin location on Map (optional, helps driver)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              MapPinPicker(
                initialPosition: _pinPosition,
                onPositionSelected: (pos) => setState(() => _pinPosition = pos),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _saveAddress,
                onChanged: (v) => setState(() => _saveAddress = v ?? false),
                title: const Text('Save this address for future orders'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_saveAddress) ...[
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressLabelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Address Label (e.g. Home, Office, Parents)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            PaymentMethodSelector(
              selected: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v),
              branch: _branch,
              referenceController: _referenceCtrl,
            ),

            const SizedBox(height: 20),
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('Cart Subtotal', cart.subtotalTzs),
                    _summaryRow(
                      'Delivery Fee',
                      _deliveryFee,
                      subtitle: _fulfillmentType == 'pickup'
                          ? 'Store Pickup — FREE (TZS 0)'
                          : '${_selectedZone.name.split(':')[0]} (${CurrencyFormatter.formatTzs(_selectedZone.baseDeliveryFeeTzs)} + ${CurrencyFormatter.formatTzs(_selectedZone.fuelSurchargeTzs)} fuel)',
                    ),
                    const Divider(height: 20),
                    _summaryRow(
                      'Total Amount',
                      cart.subtotalTzs + _deliveryFee,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18, color: AppTheme.primaryOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      children: [
                        Text(
                          'By placing this order, you agree to our ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        InkWell(
                          onTap: () => TermsAndConditionsScreen.showModal(context),
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' and ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        InkWell(
                          onTap: () => PrivacyPolicyScreen.showModal(context),
                          child: const Text(
                            'Privacy Policy / Sera ya Faragha',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Place Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false, String? subtitle}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
      color: bold ? AppTheme.primaryNavy : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: style),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          Text(CurrencyFormatter.formatTzs(amount), style: style),
        ],
      ),
    );
  }
}
