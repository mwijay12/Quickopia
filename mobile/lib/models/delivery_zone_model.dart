class DeliveryZone {
  final String id;
  final String name;
  final String code;
  final String description;
  final double baseDeliveryFeeTzs;
  final double fuelSurchargeTzs;
  final String estimatedMinutes;
  final List<String> popularNeighborhoods;

  const DeliveryZone({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.baseDeliveryFeeTzs,
    required this.fuelSurchargeTzs,
    required this.estimatedMinutes,
    required this.popularNeighborhoods,
  });

  double get totalDeliveryFeeTzs => baseDeliveryFeeTzs + fuelSurchargeTzs;

  static const List<DeliveryZone> defaultZones = [
    DeliveryZone(
      id: 'zone-1',
      name: 'Zone 1: Central & Nearby',
      code: 'ZONE_1',
      description: 'Sinza, Mwenge, Kijitonyama, Kinondoni, Mwananyamala, Magomeni',
      baseDeliveryFeeTzs: 2500,
      fuelSurchargeTzs: 500,
      estimatedMinutes: '20 - 30 mins',
      popularNeighborhoods: ['Sinza', 'Mwenge', 'Kijitonyama', 'Kinondoni', 'Mwananyamala', 'Magomeni'],
    ),
    DeliveryZone(
      id: 'zone-2',
      name: 'Zone 2: Mid-Distance & Coast',
      code: 'ZONE_2',
      description: 'Mikocheni, Oysterbay, Masaki, Kariakoo, Upanga, Ilala, Kawe',
      baseDeliveryFeeTzs: 4500,
      fuelSurchargeTzs: 1000,
      estimatedMinutes: '30 - 45 mins',
      popularNeighborhoods: ['Mikocheni', 'Oysterbay', 'Masaki', 'Kariakoo', 'Upanga', 'Ilala', 'Kawe'],
    ),
    DeliveryZone(
      id: 'zone-3',
      name: 'Zone 3: Outer Residential Wards',
      code: 'ZONE_3',
      description: 'Mbezi Beach, Tegeta, Kunduchi, Kimara, Tabata, Ubungo, Segerea',
      baseDeliveryFeeTzs: 7000,
      fuelSurchargeTzs: 1500,
      estimatedMinutes: '45 - 60 mins',
      popularNeighborhoods: ['Mbezi Beach', 'Tegeta', 'Kunduchi', 'Kimara', 'Tabata', 'Ubungo', 'Segerea'],
    ),
    DeliveryZone(
      id: 'zone-4',
      name: 'Zone 4: Extended Metropolitan',
      code: 'ZONE_4',
      description: 'Bunju, Kigamboni, Mbagala, Pugu, Goba, Mbweni',
      baseDeliveryFeeTzs: 10000,
      fuelSurchargeTzs: 2500,
      estimatedMinutes: '60 - 90 mins',
      popularNeighborhoods: ['Bunju', 'Kigamboni', 'Mbagala', 'Pugu', 'Goba', 'Mbweni'],
    ),
  ];

  static DeliveryZone findByWard(String wardName) {
    final lower = wardName.toLowerCase().trim();
    for (final zone in defaultZones) {
      if (zone.popularNeighborhoods.any((nh) => nh.toLowerCase() == lower)) {
        return zone;
      }
    }
    // Default fallback to Zone 2
    return defaultZones[1];
  }
}
