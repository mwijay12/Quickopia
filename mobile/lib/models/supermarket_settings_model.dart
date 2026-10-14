class SupermarketSettings {
  final String id;
  final String supermarketName;
  final String tagline;
  final String logoUrl;
  final String branchAddress;
  final String city;
  final String phone;
  final String email;
  final String operatingHours;
  final String currencySymbol;
  final int returnWindowHours;
  final String returnPolicyNotes;
  final bool isActive;

  const SupermarketSettings({
    this.id = 'branch_settings',
    this.supermarketName = 'Quickopia',
    this.tagline = 'Fresh groceries & daily essentials at your doorstep',
    this.logoUrl = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300',
    this.branchAddress = 'Dar es Salaam',
    this.city = 'Dar es Salaam',
    this.phone = '+255 712 345 678',
    this.email = 'support@shoppers.co.tz',
    this.operatingHours = 'Mon - Sun: 07:30 AM - 10:30 PM',
    this.currencySymbol = 'TZS',
    this.returnWindowHours = 2,
    this.returnPolicyNotes = 'Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours.',
    this.isActive = true,
  });

  factory SupermarketSettings.fromMap(Map<String, dynamic> map) {
    return SupermarketSettings(
      id: (map['id'] as String?) ?? 'branch_settings',
      supermarketName: (map['supermarket_name'] as String?)?.trim().isNotEmpty == true
          ? (map['supermarket_name'] as String)
          : (map['restaurant_name'] as String?)?.trim().isNotEmpty == true
              ? (map['restaurant_name'] as String)
              : 'Quickopia',
      tagline: (map['tagline'] as String?) ?? 'Fresh groceries & daily essentials at your doorstep',
      logoUrl: (map['logo_url'] as String?) ?? (map['logo'] as String?) ?? '',
      branchAddress: (map['branch_address'] as String?) ?? 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam',
      city: (map['city'] as String?) ?? 'Dar es Salaam',
      phone: (map['phone'] as String?) ?? '+255 712 345 678',
      email: (map['email'] as String?) ?? 'support@shoppers.co.tz',
      operatingHours: (map['operating_hours'] as String?) ?? 'Mon - Sun: 07:30 AM - 10:30 PM',
      currencySymbol: (map['currency_symbol'] as String?) ?? 'TZS',
      returnWindowHours: (map['return_window_hours'] as num?)?.toInt() ?? 2,
      returnPolicyNotes: (map['return_policy_notes'] as String?) ??
          'Perishable goods must be reported within 2 hours of delivery. Non-perishables within 24 hours.',
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supermarket_name': supermarketName,
      'restaurant_name': supermarketName,
      'tagline': tagline,
      'logo_url': logoUrl,
      'branch_address': branchAddress,
      'city': city,
      'phone': phone,
      'email': email,
      'operating_hours': operatingHours,
      'currency_symbol': currencySymbol,
      'return_window_hours': returnWindowHours,
      'return_policy_notes': returnPolicyNotes,
      'is_active': isActive,
    };
  }
}
