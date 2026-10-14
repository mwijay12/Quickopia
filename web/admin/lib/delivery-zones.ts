export interface DeliveryZone {
  id: string;
  name: string;
  code: string;
  description: string;
  baseDeliveryFeeTzs: number;
  fuelSurchargeTzs: number;
  driverPayoutTzs: number;
  estimatedMinutes: string;
  popularNeighborhoods: string[];
  isActive: boolean;
}

export interface DeliverySettings {
  freeDeliveryThresholdTzs: number;
  rainPeakTrafficSurchargeActive: boolean;
  rainPeakTrafficSurchargeTzs: number;
  storePickupFeeTzs: number; // Always 0 TZS
  storePickupEstimatedMinutes: number; // ~20 minutes
}

export const DEFAULT_DELIVERY_ZONES: DeliveryZone[] = [
  {
    id: 'zone-1',
    name: 'Zone 1: Central & Nearby Wards',
    code: 'ZONE_1',
    description: 'Direct vicinity to supermarket hub. Low fuel consumption and quickest turnaround.',
    baseDeliveryFeeTzs: 2500,
    fuelSurchargeTzs: 500,
    driverPayoutTzs: 2200,
    estimatedMinutes: '20 - 30 mins',
    popularNeighborhoods: ['Sinza', 'Mwenge', 'Kijitonyama', 'Kinondoni', 'Mwananyamala', 'Magomeni'],
    isActive: true,
  },
  {
    id: 'zone-2',
    name: 'Zone 2: Mid-Distance & Coast',
    code: 'ZONE_2',
    description: 'Mid-range transit across Dar es Salaam arterial corridors.',
    baseDeliveryFeeTzs: 4500,
    fuelSurchargeTzs: 1000,
    driverPayoutTzs: 3800,
    estimatedMinutes: '30 - 45 mins',
    popularNeighborhoods: ['Mikocheni', 'Oysterbay', 'Masaki', 'Kariakoo', 'Upanga', 'Ilala', 'Kawe'],
    isActive: true,
  },
  {
    id: 'zone-3',
    name: 'Zone 3: Outer Suburban Wards',
    code: 'ZONE_3',
    description: 'Longer distance delivery requiring higher fuel stipend for riders.',
    baseDeliveryFeeTzs: 7000,
    fuelSurchargeTzs: 1500,
    driverPayoutTzs: 6000,
    estimatedMinutes: '45 - 60 mins',
    popularNeighborhoods: ['Mbezi Beach', 'Tegeta', 'Kunduchi', 'Kimara', 'Tabata', 'Ubungo', 'Segerea'],
    isActive: true,
  },
  {
    id: 'zone-4',
    name: 'Zone 4: Extended Metropolitan',
    code: 'ZONE_4',
    description: 'Far boundary delivery (Bridge crossings, high fuel & distance).',
    baseDeliveryFeeTzs: 10000,
    fuelSurchargeTzs: 2500,
    driverPayoutTzs: 8500,
    estimatedMinutes: '60 - 90 mins',
    popularNeighborhoods: ['Bunju', 'Kigamboni', 'Mbagala', 'Pugu', 'Goba', 'Mbweni'],
    isActive: true,
  },
];

export const DEFAULT_DELIVERY_SETTINGS: DeliverySettings = {
  freeDeliveryThresholdTzs: 80000,
  rainPeakTrafficSurchargeActive: false,
  rainPeakTrafficSurchargeTzs: 1000,
  storePickupFeeTzs: 0,
  storePickupEstimatedMinutes: 20,
};
