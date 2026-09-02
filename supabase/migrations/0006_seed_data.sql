-- 0006_seed_data.sql
-- Quickopia Initial Seed Data: Pilot Branch & Multi-Category Supermarket Taxonomy

-- 1. Pilot Supermarket Branch (Dar es Salaam)
insert into branches (name, city, neighborhood, landmark, phone, commission_rate)
values (
  'Quickopia Pilot Branch',
  'Dar es Salaam',
  'Mikocheni',
  'Near Shoppers Plaza, Mwai Kibaki Road',
  '+255700000000',
  10.00
);

-- 2. Core Supermarket Categories (Bilingual: English + Swahili)
insert into categories (name, name_sw, display_order) values
('Fresh Produce', 'Mboga na Matunda', 1),
('Dairy & Eggs', 'Maziwa na Mayai', 2),
('Bakery', 'Mikate', 3),
('Beverages', 'Vinywaji', 4),
('Household & Cleaning', 'Bidhaa za Nyumbani', 5),
('Personal Care', 'Vipodozi na Usafi', 6),
('Electronics & Accessories', 'Vifaa vya Elektroniki', 7),
('Baby Products', 'Bidhaa za Watoto', 8),
('Pantry & Staples', 'Vyakula vya Ghala', 9);
