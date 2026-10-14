import csv
import json
import re

def clean_title(s):
    if not s:
        return ""
    s = s.replace("’", "'").replace("‘", "'").replace("`", "'").replace("\ufffd", "'").replace("?", "'")
    s = re.sub(r'["\\]', '', s)
    words = s.strip().split()
    cleaned = []
    for w in words:
        if w.upper() in ["CBD", "II", "III", "IV", "A", "B", "C", "D"]:
            cleaned.append(w.upper())
        elif w.lower() == "la":
            cleaned.append("la")
        elif w.lower() == "wa":
            cleaned.append("wa")
        elif w.lower() == "ya":
            cleaned.append("ya")
        elif "'" in w:
            parts = w.split("'")
            cleaned.append(parts[0].capitalize() + "'" + parts[1].lower())
        else:
            cleaned.append(w.capitalize())
    return " ".join(cleaned)

# Precise coordinates for Dar es Salaam wards
WARD_COORDS = {
    # Kinondoni
    "Mikocheni": (-6.7725, 39.2450),
    "Msasani": (-6.7580, 39.2710),
    "Kijitonyama": (-6.7780, 39.2390),
    "Kawe": (-6.7320, 39.2310),
    "Kunduchi": (-6.6780, 39.2150),
    "Mbezi Juu": (-6.7150, 39.2050),
    "Makumbusho": (-6.7780, 39.2500),
    "Mwananyamala": (-6.7900, 39.2550),
    "Bunju": (-6.6200, 39.1550),
    "Mbweni": (-6.6050, 39.1450),
    "Hananasif": (-6.7950, 39.2620),
    "Kigogo": (-6.8080, 39.2450),
    "Kinondoni": (-6.7860, 39.2650),
    "Mabwepande": (-6.6500, 39.1100),
    "Magomeni": (-6.8020, 39.2580),
    "Makongo": (-6.7650, 39.2050),
    "Mzimuni": (-6.8010, 39.2500),
    "Ndugumbi": (-6.7980, 39.2520),
    "Tandale": (-6.7950, 39.2400),
    "Wazo": (-6.6750, 39.1750),

    # Ilala
    "Kariakoo": (-6.8200, 39.2780),
    "Kivukoni": (-6.8160, 39.2960),
    "Upanga Mashariki": (-6.8100, 39.2880),
    "Upanga Magharibi": (-6.8080, 39.2790),
    "Kisutu": (-6.8170, 39.2840),
    "Mchafukoge": (-6.8190, 39.2830),
    "Gerezani": (-6.8250, 39.2820),
    "Jangwani": (-6.8150, 39.2700),
    "Mchikichini": (-6.8180, 39.2620),
    "Ilala": (-6.8280, 39.2650),
    "Buguruni": (-6.8320, 39.2520),
    "Tabata": (-6.8320, 39.2310),
    "Kimanga": (-6.8380, 39.2050),
    "Segerea": (-6.8520, 39.1910),
    "Kipawa": (-6.8580, 39.2150),
    "Ukonga": (-6.8790, 39.1820),
    "Gongo la Mboto": (-6.8850, 39.1620),
    "Kitunda": (-6.8920, 39.1950),
    "Kipunguni": (-6.8820, 39.1450),
    "Kivule": (-6.9150, 39.1650),
    "Chanika": (-6.9650, 39.0950),
    "Pugu": (-6.8950, 39.1150),
    "Pugu Station": (-6.9020, 39.1250),
    "Kinyerezi": (-6.8450, 39.1750),
    "Bonyokwa": (-6.8350, 39.1650),
    "Kisukulu": (-6.8400, 39.1850),
    "Liwiti": (-6.8350, 39.2200),
    "Minazi Mirefu": (-6.8650, 39.2250),
    "Mnyamani": (-6.8420, 39.2450),
    "Vingunguti": (-6.8480, 39.2420),
    "Kiwalani": (-6.8550, 39.2350),
    "Majohe": (-6.9350, 39.1350),
    "Msongola": (-7.0250, 39.2250),
    "Mzinga": (-6.9200, 39.2850),
    "Buyuni": (-6.9850, 39.0850),
    "Zingiziwa": (-6.9750, 39.1250),

    # Ubungo
    "Sinza": (-6.7860, 39.2220),
    "Ubungo": (-6.7850, 39.2100),
    "Kimara": (-6.7950, 39.1750),
    "Mbezi": (-6.7890, 39.1450),
    "Goba": (-6.7350, 39.1650),
    "Mabibo": (-6.8080, 39.2250),
    "Manzese": (-6.7980, 39.2320),
    "Makurumla": (-6.7920, 39.2380),
    "Mburahati": (-6.8050, 39.2400),
    "Makuburi": (-6.7990, 39.2150),
    "Msigani": (-6.7820, 39.1550),
    "Saranga": (-6.8050, 39.1650),
    "Kibamba": (-6.8050, 39.1150),
    "Kwembe": (-6.8150, 39.0850),

    # Temeke
    "Chang'ombe": (-6.8450, 39.2720),
    "Kurasini": (-6.8520, 39.2890),
    "Keko": (-6.8390, 39.2780),
    "Temeke": (-6.8550, 39.2650),
    "Tandika": (-6.8620, 39.2600),
    "Mbagala": (-6.9030, 39.2630),
    "Mbagala Kuu": (-6.8950, 39.2750),
    "Kijichi": (-6.8850, 39.2850),
    "Mtoni": (-6.8680, 39.2750),
    "Miburani": (-6.8580, 39.2720),
    "Sandali": (-6.8650, 39.2550),
    "Azimio": (-6.8750, 39.2650),
    "Makangarawe": (-6.8820, 39.2550),
    "Kibondemaji": (-6.9250, 39.2650),
    "Charambe": (-6.9350, 39.2550),
    "Chamazi": (-6.9450, 39.2850),
    "Toangoma": (-6.9250, 39.3350),
    "Buza": (-6.8950, 39.2500),
    "Kilakala": (-6.8680, 39.2580),
    "Kilungule": (-6.8880, 39.2480),
    "Mianzini": (-6.8920, 39.2620),
    "Kiburugwa": (-6.9050, 39.2450),
    "Yombo Vituka": (-6.8780, 39.2480),

    # Kigamboni
    "Kigamboni": (-6.8290, 39.3140),
    "Vijibweni": (-6.8510, 39.3180),
    "Kibada": (-6.8790, 39.3320),
    "Mjimwema": (-6.8580, 39.3550),
    "Somangila": (-6.9150, 39.4120),
    "Tungi": (-6.8420, 39.3250),
    "Kisarawe II": (-6.9450, 39.3650),
    "Kimbiji": (-6.9850, 39.5250),
    "Pembamnazi": (-7.0550, 39.5650),
}

# District fallback centroids
DISTRICT_CENTROIDS = {
    "Kinondoni": (-6.7725, 39.2350),
    "Ilala": (-6.8320, 39.2500),
    "Ubungo": (-6.7880, 39.1950),
    "Temeke": (-6.8750, 39.2650),
    "Kigamboni": (-6.8750, 39.3550),
}

# Famous landmark streets in Dar es Salaam to complement official DB
ENRICHED_STREETS = {
    "Mikocheni": ["Mwai Kibaki Road", "Old Bagamoyo Rd", "Regent Estate", "Mikocheni A", "Mikocheni B"],
    "Msasani": ["Toure Drive", "Haile Selassie Rd", "Chole Rd", "Kimweri Ave", "Oysterbay", "Masaki"],
    "Kariakoo": ["Msimbazi St", "Congo St", "Uhuru St", "Swahili St", "Tandamti St"],
    "Kivukoni": ["Sokoine Drive", "Samora Ave", "Azikiwe St", "Sea View", "Posta"],
    "Sinza": ["Shekilango Rd", "Sinza Mori", "Sinza Palestina", "Sinza Kwaremi", "Sinza Afrika Sana"],
    "Kijitonyama": ["Ali Hassan Mwinyi Rd", "Sayansi", "Bwawani", "Mpakani"],
    "Kawe": ["Kawe Beach", "Mzimuni", "Ukwamani"],
    "Tabata": ["Tabata Bima", "Mawenzi", "Mandela Rd"],
    "Mbagala": ["Mbagala Rangi Tatu", "Mbagala Zakhem", "Mbagala Kuu"],
    "Goba": ["Goba Centre", "Goba Njia Nne", "Kulangwa"],
    "Kimara": ["Kimara Mwisho", "Kimara Temboni", "Kimara Korogwe", "Kimara Stopover"],
    "Ubungo": ["Ubungo Maji", "Mwenge ITV", "Mlalakuwa", "Kibo"],
    "Upanga Mashariki": ["United Nations Rd", "Ali Hassan Mwinyi Rd", "Kitonga"],
    "Upanga Magharibi": ["Fire", "Charambe", "Mfaume"],
}

csv_path = r"C:\Users\MWIJAY TECH\Desktop\PROJECTS\tanzania-locations-db-main\location-files\dar-es-salaam.csv"

districts_data = {
    "Kinondoni": {},
    "Ilala": {},
    "Ubungo": {},
    "Temeke": {},
    "Kigamboni": {},
}

with open(csv_path, encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        raw_dist = row["DISTRICT"].strip()
        raw_ward = row["WARD"].strip()
        raw_street = row["STREET"].strip()

        if raw_dist == "ILALA CBD":
            dist = "Ilala"
        else:
            dist = clean_title(raw_dist)

        ward = clean_title(raw_ward)
        street = clean_title(raw_street)

        if dist not in districts_data:
            continue

        if ward not in districts_data[dist]:
            districts_data[dist][ward] = []

        if street and street not in districts_data[dist][ward]:
            districts_data[dist][ward].append(street)

# Generate Dart code
out = []
out.append("import 'package:latlong2/latlong.dart';")
out.append("")
out.append("class DarWardInfo {")
out.append("  final String wardName;")
out.append("  final LatLng center;")
out.append("  final List<String> popularStreets;")
out.append("")
out.append("  const DarWardInfo({")
out.append("    required this.wardName,")
out.append("    required this.center,")
out.append("    this.popularStreets = const [],")
out.append("  });")
out.append("}")
out.append("")
out.append("class DarLocationsRepository {")
out.append("  static const LatLng darEsSalaamCenter = LatLng(-6.7924, 39.2083);")
out.append("")
out.append("  // Grouped Districts and their official Wards from Tanzania Locations DB")
out.append("  static const Map<String, List<DarWardInfo>> districts = {")

for dist_name in ["Kinondoni", "Ilala", "Ubungo", "Temeke", "Kigamboni"]:
    wards = districts_data[dist_name]
    out.append(f"    '{dist_name}': [")
    for ward_name in sorted(wards.keys()):
        raw_streets = wards[ward_name]
        extra = ENRICHED_STREETS.get(ward_name, [])
        all_streets = []
        for s in extra + raw_streets:
            if s not in all_streets:
                all_streets.append(s)
        coords = WARD_COORDS.get(ward_name, DISTRICT_CENTROIDS[dist_name])
        ward_escaped = ward_name.replace("'", "\\'")
        streets_escaped = [s.replace("'", "\\'") for s in all_streets]
        streets_str = ", ".join([f"'{s}'" for s in streets_escaped])
        
        out.append(f"      DarWardInfo(")
        out.append(f"        wardName: '{ward_escaped}',")
        out.append(f"        center: LatLng({coords[0]:.4f}, {coords[1]:.4f}),")
        out.append(f"        popularStreets: [{streets_str}],")
        out.append(f"      ),")
    out.append("    ],")

out.append("  };")
out.append("")
out.append("  static List<String> get districtNames => districts.keys.toList();")
out.append("")
out.append("  static List<String> getDistrictNames() => districts.keys.toList();")
out.append("")
out.append("  static List<DarWardInfo> getWards(String districtName) {")
out.append("    return districts[districtName] ?? [];")
out.append("  }")
out.append("")
out.append("  static List<DarWardInfo> getWardsForDistrict(String districtName) {")
out.append("    return getWards(districtName);")
out.append("  }")
out.append("")
out.append("  static DarWardInfo? findWard(String wardName, [String? districtName]) {")
out.append("    if (districtName != null) {")
out.append("      final wards = getWards(districtName);")
out.append("      for (final w in wards) {")
out.append("        if (w.wardName.toLowerCase() == wardName.toLowerCase() ||")
out.append("            w.wardName.toLowerCase().contains(wardName.toLowerCase())) {")
out.append("          return w;")
out.append("        }")
out.append("      }")
out.append("      return null;")
out.append("    }")
out.append("")
out.append("    final lower = wardName.toLowerCase();")
out.append("    for (final list in districts.values) {")
out.append("      for (final w in list) {")
out.append("        if (w.wardName.toLowerCase() == lower ||")
out.append("            w.wardName.toLowerCase().contains(lower) ||")
out.append("            lower.contains(w.wardName.toLowerCase())) {")
out.append("          return w;")
out.append("        }")
out.append("      }")
out.append("    }")
out.append("    return null;")
out.append("  }")
out.append("}")
out.append("")

content = "\n".join(out)
target_file = r"c:\Users\MWIJAY TECH\Desktop\PROJECTS\E-commerce-App-UI-Flutter-master\mobile\lib\data\dar_locations_repository.dart"
with open(target_file, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Generated {len(content)} bytes to {target_file}")
