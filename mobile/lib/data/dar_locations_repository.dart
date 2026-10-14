import 'package:latlong2/latlong.dart';

class DarWardInfo {
  final String wardName;
  final LatLng center;
  final List<String> popularStreets;

  const DarWardInfo({
    required this.wardName,
    required this.center,
    this.popularStreets = const [],
  });
}

class DarLocationsRepository {
  static const LatLng darEsSalaamCenter = LatLng(-6.7924, 39.2083);

  // Grouped Districts and their official Wards from Tanzania Locations DB
  static const Map<String, List<DarWardInfo>> districts = {
    'Kinondoni': [
      DarWardInfo(
        wardName: 'Bunju',
        center: LatLng(-6.6200, 39.1550),
        popularStreets: ['Boko', 'Bunju A', 'Kilungule', 'Busihaya', 'Dovya', 'Mkoani'],
      ),
      DarWardInfo(
        wardName: 'Hananasif',
        center: LatLng(-6.7950, 39.2620),
        popularStreets: ['Hananasif', 'Kisutu', 'Mkunguni A', 'Mkunguni B', 'Kawawa'],
      ),
      DarWardInfo(
        wardName: 'Kawe',
        center: LatLng(-6.7320, 39.2310),
        popularStreets: ['Kawe Beach', 'Mzimuni', 'Ukwamani', 'Mbezi Beach A', 'Mbezi Beach B'],
      ),
      DarWardInfo(
        wardName: 'Kigogo',
        center: LatLng(-6.8080, 39.2450),
        popularStreets: ['Kigogo Kati', 'Kigogo Mkwajuni', 'Kigogo Mbuyuni'],
      ),
      DarWardInfo(
        wardName: 'Kijitonyama',
        center: LatLng(-6.7780, 39.2390),
        popularStreets: ['Ali Hassan Mwinyi Rd', 'Sayansi', 'Bwawani', 'Mpakani', 'Kijitonyama', 'Alimaua A', 'Alimaua B', 'Mpakani A', 'Mpakani B', 'Mwenge', 'Nzasa'],
      ),
      DarWardInfo(
        wardName: 'Kinondoni',
        center: LatLng(-6.7860, 39.2650),
        popularStreets: ['Kumbukumbu', 'Kinondoni Mjini', 'Kinondoni Shamba', 'Ada Estate'],
      ),
      DarWardInfo(
        wardName: 'Kunduchi',
        center: LatLng(-6.6780, 39.2150),
        popularStreets: ['Pwani', 'Kilongawima', 'Mtongani', 'Tegeta', 'Ununio', 'Kondo'],
      ),
      DarWardInfo(
        wardName: 'Mabwepande',
        center: LatLng(-6.6500, 39.1100),
        popularStreets: ['Bunju B\'', 'Mabwe Pande', 'Mjimpya', 'Kihonzile', 'Mbopo'],
      ),
      DarWardInfo(
        wardName: 'Magomeni',
        center: LatLng(-6.8020, 39.2580),
        popularStreets: ['Suna', 'Makuti A', 'Makuti B', 'Dossi', 'Idrisa'],
      ),
      DarWardInfo(
        wardName: 'Makongo',
        center: LatLng(-6.7650, 39.2050),
        popularStreets: ['Changanyikeni', 'Mbuyuni', 'Mlalakuwa', 'Makongo'],
      ),
      DarWardInfo(
        wardName: 'Makumbusho',
        center: LatLng(-6.7780, 39.2500),
        popularStreets: ['Makumbusho', 'Minazini', 'Mchangani', 'Kisiwani', 'Mbuyuni', 'Singano'],
      ),
      DarWardInfo(
        wardName: 'Mbezi Juu',
        center: LatLng(-6.7150, 39.2050),
        popularStreets: ['Jogoo', 'Ndumbwi', 'Mbezi Mtoni', 'Mbezi Kati', 'Mbezi Juu'],
      ),
      DarWardInfo(
        wardName: 'Mbweni',
        center: LatLng(-6.6050, 39.1450),
        popularStreets: ['Maputo', 'Mbweni', 'Teta', 'Malindi Estate', 'Mpiji Mbweni'],
      ),
      DarWardInfo(
        wardName: 'Mikocheni',
        center: LatLng(-6.7725, 39.2450),
        popularStreets: ['Mwai Kibaki Road', 'Old Bagamoyo Rd', 'Regent Estate', 'Mikocheni A', 'Mikocheni B', 'Ally H. Mwinyi', 'Tpdc', 'Darajani'],
      ),
      DarWardInfo(
        wardName: 'Msasani',
        center: LatLng(-6.7580, 39.2710),
        popularStreets: ['Toure Drive', 'Haile Selassie Rd', 'Chole Rd', 'Kimweri Ave', 'Oysterbay', 'Masaki', 'Mikoroshoni', 'Bonde la Mpunga', 'Makangira'],
      ),
      DarWardInfo(
        wardName: 'Mwananyamala',
        center: LatLng(-6.7900, 39.2550),
        popularStreets: ['Kambangwa', 'Msisiri B', 'Msisiri A', 'Bwawani', 'Mwinjuma', 'Kwa Kopa', 'Msolomi'],
      ),
      DarWardInfo(
        wardName: 'Mzimuni',
        center: LatLng(-6.8010, 39.2500),
        popularStreets: ['Idrisa', 'Makumbusho', 'Mtambani', 'Mwinyimkuu'],
      ),
      DarWardInfo(
        wardName: 'Ndugumbi',
        center: LatLng(-6.7980, 39.2520),
        popularStreets: ['Mpakani', 'Mikoroshini', 'Makanya', 'Vigaeni'],
      ),
      DarWardInfo(
        wardName: 'Tandale',
        center: LatLng(-6.7950, 39.2400),
        popularStreets: ['Mtogole', 'Kwa Tumbo', 'Pakacha', 'Sokoni', 'Mkunduge', 'Muhaltani'],
      ),
      DarWardInfo(
        wardName: 'Wazo',
        center: LatLng(-6.6750, 39.1750),
        popularStreets: ['Wazo', 'Salasala', 'Kilimahewa', 'Madale', 'Mivumoni', 'Kisanga', 'Kilimahewa Juu', 'Nakasangwe'],
      ),
    ],
    'Ilala': [
      DarWardInfo(
        wardName: 'Bonyokwa',
        center: LatLng(-6.8350, 39.1650),
        popularStreets: ['Bonyokwa', 'Kisiwani', 'Msingwa'],
      ),
      DarWardInfo(
        wardName: 'Buguruni',
        center: LatLng(-6.8320, 39.2520),
        popularStreets: ['Malapa', 'Madenge', 'Kisiwani', 'Mvinjeni'],
      ),
      DarWardInfo(
        wardName: 'Buyuni',
        center: LatLng(-6.9850, 39.0850),
        popularStreets: ['Zavala', 'Mgeule', 'Nyeburu', 'Kigezi', 'Kigezi Chini', 'Mgeule Juu', 'Taliani'],
      ),
      DarWardInfo(
        wardName: 'Chanika',
        center: LatLng(-6.9650, 39.0950),
        popularStreets: ['Tungini', 'Yongwe', 'Lukomi', 'Vikongoro', 'Nguvu Mpya', 'Virobo', 'Kidugalo', 'Ngwale', 'Lukooni'],
      ),
      DarWardInfo(
        wardName: 'Gerezani',
        center: LatLng(-6.8250, 39.2820),
        popularStreets: ['Gerezani Mashariki', 'Gerezani Magharibi'],
      ),
      DarWardInfo(
        wardName: 'Gongo la Mboto',
        center: LatLng(-6.8850, 39.1620),
        popularStreets: ['Guluka Kwalala', 'Gongo la Mboto', 'Ulongoni A', 'Ulongoni B'],
      ),
      DarWardInfo(
        wardName: 'Ilala',
        center: LatLng(-6.8280, 39.2650),
        popularStreets: ['Mafuriko', 'Kasulu', 'Karume', 'Shariff Shamba', 'Amana'],
      ),
      DarWardInfo(
        wardName: 'Jangwani',
        center: LatLng(-6.8150, 39.2700),
        popularStreets: ['Ukombozi', 'Mnazi Mmoja', 'Mtambani A', 'Mtambani B'],
      ),
      DarWardInfo(
        wardName: 'Kariakoo',
        center: LatLng(-6.8200, 39.2780),
        popularStreets: ['Msimbazi St', 'Congo St', 'Uhuru St', 'Swahili St', 'Tandamti St', 'Kariakoo Magharibi', 'Kariakoo Kaskazini', 'Kariakoo Mashariki'],
      ),
      DarWardInfo(
        wardName: 'Kimanga',
        center: LatLng(-6.8380, 39.2050),
        popularStreets: ['Tembomgwaza', 'Kimanga', 'Kimanga Darajani', 'Banebane', 'Kihimbwa', 'Sokoine', 'Twiga'],
      ),
      DarWardInfo(
        wardName: 'Kinyerezi',
        center: LatLng(-6.8450, 39.1750),
        popularStreets: ['Kinyerezi', 'Kifuru', 'Kwalimbaga', 'Kanga', 'Kichangani', 'Kibaga'],
      ),
      DarWardInfo(
        wardName: 'Kipawa',
        center: LatLng(-6.8580, 39.2150),
        popularStreets: ['Mogo', 'Karakata', 'Kipunguni', 'Stakishari', 'Uwanja wa Ndege', 'Mjimpya'],
      ),
      DarWardInfo(
        wardName: 'Kipunguni',
        center: LatLng(-6.8820, 39.1450),
        popularStreets: ['Kipunguni B', 'Kitinye', 'Machimbo', 'Amani'],
      ),
      DarWardInfo(
        wardName: 'Kisukulu',
        center: LatLng(-6.8400, 39.1850),
        popularStreets: ['Luhanga', 'Kisukulu', 'Mianzini'],
      ),
      DarWardInfo(
        wardName: 'Kisutu',
        center: LatLng(-6.8170, 39.2840),
        popularStreets: ['Kisutu', 'Mtendeni'],
      ),
      DarWardInfo(
        wardName: 'Kitunda',
        center: LatLng(-6.8920, 39.1950),
        popularStreets: ['Kipera', 'Kitunda', 'Relini', 'Kiyombo'],
      ),
      DarWardInfo(
        wardName: 'Kivukoni',
        center: LatLng(-6.8160, 39.2960),
        popularStreets: ['Sokoine Drive', 'Samora Ave', 'Azikiwe St', 'Sea View', 'Posta', 'Kivukoni'],
      ),
      DarWardInfo(
        wardName: 'Kivule',
        center: LatLng(-6.9150, 39.1650),
        popularStreets: ['Kivule', 'Bombambili', 'Karezange', 'Magore A'],
      ),
      DarWardInfo(
        wardName: 'Kiwalani',
        center: LatLng(-6.8550, 39.2350),
        popularStreets: ['Kigilagila', 'Yombo', 'Kiwalani'],
      ),
      DarWardInfo(
        wardName: 'Liwiti',
        center: LatLng(-6.8350, 39.2200),
        popularStreets: ['Machimbo', 'Liwiti', 'Misewe', 'Amani'],
      ),
      DarWardInfo(
        wardName: 'Majohe',
        center: LatLng(-6.9350, 39.1350),
        popularStreets: ['Mji Mpya', 'Kichangani', 'Kivule', 'Rada', 'Viwege'],
      ),
      DarWardInfo(
        wardName: 'Mchafukoge',
        center: LatLng(-6.8190, 39.2830),
        popularStreets: ['Kitumbini', 'Mchafukoge'],
      ),
      DarWardInfo(
        wardName: 'Mchikichini',
        center: LatLng(-6.8180, 39.2620),
        popularStreets: ['Mission Quarter', 'Ilala Kota', 'Msimbazi Bondeni'],
      ),
      DarWardInfo(
        wardName: 'Minazi Mirefu',
        center: LatLng(-6.8650, 39.2250),
        popularStreets: ['Mwale', 'Migombani', 'Minazi Mirefu'],
      ),
      DarWardInfo(
        wardName: 'Mnyamani',
        center: LatLng(-6.8420, 39.2450),
        popularStreets: ['Maluzuku', 'Mji Mpya', 'Faru', 'Mnyamani'],
      ),
      DarWardInfo(
        wardName: 'Msongola',
        center: LatLng(-7.0250, 39.2250),
        popularStreets: ['Kitonga', 'Yangeyange', 'Mbondole', 'Mvuleni', 'Kiboga', 'Kidole', 'Mkera', 'Sangara', 'Uwanja wa Nyani'],
      ),
      DarWardInfo(
        wardName: 'Mzinga',
        center: LatLng(-6.9200, 39.2850),
        popularStreets: ['Mwanagati', 'Magole', 'Mzinga'],
      ),
      DarWardInfo(
        wardName: 'Pugu',
        center: LatLng(-6.8950, 39.1150),
        popularStreets: ['Kinyamwezi', 'Bombani', 'Kigogo Fresh \'a', 'Kigogo Fresh \'b', 'Mustapha'],
      ),
      DarWardInfo(
        wardName: 'Pugu Station',
        center: LatLng(-6.9020, 39.1250),
        popularStreets: ['Bangulo', 'Pugu Station', 'Kichangani'],
      ),
      DarWardInfo(
        wardName: 'Segerea',
        center: LatLng(-6.8520, 39.1910),
        popularStreets: ['Mgombani', 'Ugombolwa', 'Segerea', 'Mfaume'],
      ),
      DarWardInfo(
        wardName: 'Tabata',
        center: LatLng(-6.8320, 39.2310),
        popularStreets: ['Tabata Bima', 'Mawenzi', 'Mandela Rd', 'Mandela', 'Tabata', 'Matumbi', 'Msimbazi', 'Kisiwani', 'Tenge', 'Mtambani', 'Msimbazi Magharibi'],
      ),
      DarWardInfo(
        wardName: 'Ukonga',
        center: LatLng(-6.8790, 39.1820),
        popularStreets: ['Mwembe Madafu', 'Mazizini', 'Markaz', 'Mongo la Ndege', 'Sabasaba'],
      ),
      DarWardInfo(
        wardName: 'Upanga Magharibi',
        center: LatLng(-6.8080, 39.2790),
        popularStreets: ['Fire', 'Charambe', 'Mfaume'],
      ),
      DarWardInfo(
        wardName: 'Upanga Mashariki',
        center: LatLng(-6.8100, 39.2880),
        popularStreets: ['United Nations Rd', 'Ali Hassan Mwinyi Rd', 'Kitonga', 'Kibasila'],
      ),
      DarWardInfo(
        wardName: 'Vingunguti',
        center: LatLng(-6.8480, 39.2420),
        popularStreets: ['Kombo', 'Miembeni', 'Mtakuja', 'Mtambani', 'Butiama', 'Majengo'],
      ),
      DarWardInfo(
        wardName: 'Zingiziwa',
        center: LatLng(-6.9750, 39.1250),
        popularStreets: ['Nzasa', 'Zogoali', 'Zingiziwa', 'Lubakaya', 'Kimwani', 'Ngobedi', 'Somelo', 'Gogo'],
      ),
    ],
    'Ubungo': [
      DarWardInfo(
        wardName: 'Goba',
        center: LatLng(-6.7350, 39.1650),
        popularStreets: ['Goba Centre', 'Goba Njia Nne', 'Kulangwa', 'Goba', 'Matosa', 'Kinzudi', 'Kunguru', 'Kibululu', 'Tegeta A', 'Muungano'],
      ),
      DarWardInfo(
        wardName: 'Kibamba',
        center: LatLng(-6.8050, 39.1150),
        popularStreets: ['Kibwegere', 'Kibamba', 'Hondogo', 'Gogoni', 'Kiluvya'],
      ),
      DarWardInfo(
        wardName: 'Kimara',
        center: LatLng(-6.7950, 39.1750),
        popularStreets: ['Kimara Mwisho', 'Kimara Temboni', 'Kimara Korogwe', 'Kimara Stopover', 'Baruti', 'Kimara Baruti', 'Mavurunza', 'Kilungule A', 'Kilungule B', 'Golani'],
      ),
      DarWardInfo(
        wardName: 'Kwembe',
        center: LatLng(-6.8150, 39.0850),
        popularStreets: ['Kwembe', 'Mpakani', 'King\'azi', 'Luguruni', 'Kisopwa', 'Njeteni', 'King\'azi B', 'Mjimpya', 'Msakuzi', 'Mlongazila'],
      ),
      DarWardInfo(
        wardName: 'Mabibo',
        center: LatLng(-6.8080, 39.2250),
        popularStreets: ['Mabibo', 'Jitegemee', 'Azimio', 'Kanuni', 'Matokeo', 'Mabibo Farasi'],
      ),
      DarWardInfo(
        wardName: 'Makuburi',
        center: LatLng(-6.7990, 39.2150),
        popularStreets: ['Mwongozo', 'Makoka', 'Kibangu', 'Makuburi Kibangu', 'Kajima'],
      ),
      DarWardInfo(
        wardName: 'Makurumla',
        center: LatLng(-6.7920, 39.2380),
        popularStreets: ['Kwa Jongo', 'Kimamba', 'Kilimahewa', 'Kagera', 'Mianzini', 'Sisi Kwa Sisi'],
      ),
      DarWardInfo(
        wardName: 'Manzese',
        center: LatLng(-6.7980, 39.2320),
        popularStreets: ['Midizini', 'Kilimani', 'Mnazi Mmoja', 'Muungano', 'Uzuri', 'Mvuleni', 'Mwembeni', 'Chakula Bora', 'Tupendane', 'Mferejini'],
      ),
      DarWardInfo(
        wardName: 'Mbezi',
        center: LatLng(-6.7890, 39.1450),
        popularStreets: ['Msakuzi', 'Msumi', 'Mbezi Luis', 'Mpiji Magohe', 'Makabe', 'Mshikamano', 'Msakuzi Kusini', 'Luis'],
      ),
      DarWardInfo(
        wardName: 'Mburahati',
        center: LatLng(-6.8050, 39.2400),
        popularStreets: ['Kisiwani', 'National Housing Corp', 'Barafu'],
      ),
      DarWardInfo(
        wardName: 'Msigani',
        center: LatLng(-6.7820, 39.1550),
        popularStreets: ['Temboni', 'Malamba Mawili', 'Kwa Yusuph', 'Msigani', 'Msingwa'],
      ),
      DarWardInfo(
        wardName: 'Saranga',
        center: LatLng(-6.8050, 39.1650),
        popularStreets: ['Saranga', 'Upendo', 'Kimarab', 'Matangini', 'Stop Over', 'King\'ongo', 'Michungwani', 'Ukombozi', 'Mji Mpya'],
      ),
      DarWardInfo(
        wardName: 'Sinza',
        center: LatLng(-6.7860, 39.2220),
        popularStreets: ['Shekilango Rd', 'Sinza Mori', 'Sinza Palestina', 'Sinza Kwaremi', 'Sinza Afrika Sana', 'Sinza A', 'Sinza B', 'Sinza C', 'Sinza D', 'Sinza E'],
      ),
      DarWardInfo(
        wardName: 'Ubungo',
        center: LatLng(-6.7850, 39.2100),
        popularStreets: ['Ubungo Maji', 'Mwenge ITV', 'Mlalakuwa', 'Kibo', 'Chuo Kikuu', 'Kisiwani', 'Msewe', 'National Housing Corp.'],
      ),
    ],
    'Temeke': [
      DarWardInfo(
        wardName: 'Azimio',
        center: LatLng(-6.8750, 39.2650),
        popularStreets: ['Azimio Kaskazini', 'Azimio Kusini', 'Kichangani', 'Tambukareli', 'Mji Mpya', 'Mtongani', 'Mtoni Unguja', 'Mbuyuni'],
      ),
      DarWardInfo(
        wardName: 'Buza',
        center: LatLng(-6.8950, 39.2500),
        popularStreets: ['Buza', 'Mji Mpya', 'Mashine ya Maji', 'Kidagaa', 'Amani'],
      ),
      DarWardInfo(
        wardName: 'Chamazi',
        center: LatLng(-6.9450, 39.2850),
        popularStreets: ['Magengeni', 'Mwembebamia', 'Kiponza', 'Kisewe', 'Rufu', 'Msufini', 'Vigoa', 'Dovya', 'Mkondogwa'],
      ),
      DarWardInfo(
        wardName: 'Chang\'ombe',
        center: LatLng(-6.8450, 39.2720),
        popularStreets: ['Bora', 'Toroli', 'Chang\'ombe A', 'Chang\'ombe B'],
      ),
      DarWardInfo(
        wardName: 'Charambe',
        center: LatLng(-6.9350, 39.2550),
        popularStreets: ['Kurasini Mji Mpya', 'Nzasa B', 'Rangi Tatu', 'Machinjioni A'],
      ),
      DarWardInfo(
        wardName: 'Keko',
        center: LatLng(-6.8390, 39.2780),
        popularStreets: ['Keko B', 'Keko Mwanga A', 'Keko Mwanga B', 'Keko Magurumbasi A', 'Keko Magurumbasi B'],
      ),
      DarWardInfo(
        wardName: 'Kibondemaji',
        center: LatLng(-6.9250, 39.2650),
        popularStreets: ['Majimatitu', 'Kibondemaji A', 'Mchikichini', 'Kimbangulile'],
      ),
      DarWardInfo(
        wardName: 'Kiburugwa',
        center: LatLng(-6.9050, 39.2450),
        popularStreets: ['Juhudi', 'Kiburugwa Namba3', 'Kwanyoka', 'Kingugi', 'Barabara ya Mwinyi', 'Kiburugwa'],
      ),
      DarWardInfo(
        wardName: 'Kijichi',
        center: LatLng(-6.8850, 39.2850),
        popularStreets: ['Mgeni Nani', 'Misheni', 'Mtoni Kijichi', 'Butiama', 'Mwanamtoti'],
      ),
      DarWardInfo(
        wardName: 'Kilakala',
        center: LatLng(-6.8680, 39.2580),
        popularStreets: ['Barabara ya Mwinyi', 'Kilakala', 'Kigunga', 'Kiembesamaki', 'Yombo Reli'],
      ),
      DarWardInfo(
        wardName: 'Kilungule',
        center: LatLng(-6.8880, 39.2480),
        popularStreets: ['Kilungule', 'Nzasa A', 'Majimatitu B', 'Kwa Mzungu', 'Uzombokoni'],
      ),
      DarWardInfo(
        wardName: 'Kurasini',
        center: LatLng(-6.8520, 39.2890),
        popularStreets: ['Shimo la Udongo', 'Mivinjeni', 'Minazini', 'Kurasini', 'Kiungani'],
      ),
      DarWardInfo(
        wardName: 'Makangarawe',
        center: LatLng(-6.8820, 39.2550),
        popularStreets: ['Makangarawe', 'Yombo Dovya', 'Msakala', 'Uwazi', 'Mbonde'],
      ),
      DarWardInfo(
        wardName: 'Mbagala',
        center: LatLng(-6.9030, 39.2630),
        popularStreets: ['Mbagala Rangi Tatu', 'Mbagala Zakhem', 'Mbagala Kuu', 'Mbagala', 'Kizinga', 'Mangaya', 'Moringe', 'Bughudadi', 'Serenge'],
      ),
      DarWardInfo(
        wardName: 'Mbagala Kuu',
        center: LatLng(-6.8950, 39.2750),
        popularStreets: ['Kizuiani', 'Kibonde Maji B', 'Kichemchem', 'Jeshi la Wokovu', 'Mbagala Kuu Mashariki', 'Mbagala Kuu Magharibi', 'Mbagala Kuu Kaskazini', 'Makuka Kusini', 'Makuka Kaskazini', 'Mpakani'],
      ),
      DarWardInfo(
        wardName: 'Mianzini',
        center: LatLng(-6.8920, 39.2620),
        popularStreets: ['Majimatitu A', 'Machinjioni', 'Mponda', 'Mianzini'],
      ),
      DarWardInfo(
        wardName: 'Miburani',
        center: LatLng(-6.8580, 39.2720),
        popularStreets: ['Miburani', 'Uwanja wa Taifa', 'Wailes', 'Keko Machungwa', 'Mgulani (keko Juu)'],
      ),
      DarWardInfo(
        wardName: 'Mtoni',
        center: LatLng(-6.8680, 39.2750),
        popularStreets: ['Mtoni', 'Sabasaba', 'Bustani', 'Relini', 'Chaurembo', 'Bokorani'],
      ),
      DarWardInfo(
        wardName: 'Sandali',
        center: LatLng(-6.8650, 39.2550),
        popularStreets: ['Mamboleo A', 'Sandali', 'Mamboleo B', 'Mpogo', 'Mwembeladu', 'Tindwa', 'Mkwida', 'Veterinary', 'Usalama', 'Kimbunga', 'Mwembemnofu', 'Kisiwani'],
      ),
      DarWardInfo(
        wardName: 'Tandika',
        center: LatLng(-6.8620, 39.2600),
        popularStreets: ['Tamla', 'Maguruwe', 'Kilimahewa', 'Tandika', 'Nyambwera', 'Mabatini'],
      ),
      DarWardInfo(
        wardName: 'Temeke',
        center: LatLng(-6.8550, 39.2650),
        popularStreets: ['Maganga', 'Matumbi', 'Njaro', 'Temeke'],
      ),
      DarWardInfo(
        wardName: 'Toangoma',
        center: LatLng(-6.9250, 39.3350),
        popularStreets: ['Toangoma', 'Malela', 'Vikunai', 'Masuliza', 'Masaki', 'Mikwambe', 'Changanyikeni', 'Mwapemba', 'Ponde', 'Kongowe', 'Goroka \'a', 'Goroka \'b', 'Mzinga \'a', 'Mzinga \'b'],
      ),
      DarWardInfo(
        wardName: 'Yombo Vituka',
        center: LatLng(-6.8780, 39.2480),
        popularStreets: ['Yombo Vituka', 'Sigara', 'Machimbo', 'Magogoni', 'Mzambarauni'],
      ),
    ],
    'Kigamboni': [
      DarWardInfo(
        wardName: 'Kibada',
        center: LatLng(-6.8790, 39.3320),
        popularStreets: ['Nyakwale', 'Kichangani', 'Sokoni', 'Kiziza', 'Uvumba', 'Kifurukwe'],
      ),
      DarWardInfo(
        wardName: 'Kigamboni',
        center: LatLng(-6.8290, 39.3140),
        popularStreets: ['Kigamboni', 'Ferry', 'Tuamoyo'],
      ),
      DarWardInfo(
        wardName: 'Kimbiji',
        center: LatLng(-6.9850, 39.5250),
        popularStreets: ['Golani', 'Kwa Chale', 'Mikenge', 'Ngobanya', 'Kizito Huonjwa', 'Kijaka'],
      ),
      DarWardInfo(
        wardName: 'Kisarawe II',
        center: LatLng(-6.9450, 39.3650),
        popularStreets: ['Tumaini', 'Kigogo', 'Mwasonga', 'Sharifu', 'Vumilia Ukooni', 'Ngoma Mapinduzi', 'Mwaninga', 'Mkamba', 'Lingato', 'Madege', 'Kichangani'],
      ),
      DarWardInfo(
        wardName: 'Mjimwema',
        center: LatLng(-6.8580, 39.3550),
        popularStreets: ['Maweni', 'Ungindoni', 'Mjimwema', 'Kibugumo'],
      ),
      DarWardInfo(
        wardName: 'Pembamnazi',
        center: LatLng(-7.0550, 39.5650),
        popularStreets: ['Potea', 'Pu Centre', 'Kwa Morisi', 'Gulubwida', 'Mahenge', 'Tundwi Centre', 'Songani Centre', 'Pemba Centre', 'Buyuni Centre', 'Kibungo', 'Kichangani', 'Muhimbili', 'Nyange', 'Chambewa', 'Mtimweupe'],
      ),
      DarWardInfo(
        wardName: 'Somangila',
        center: LatLng(-6.9150, 39.4120),
        popularStreets: ['Kizani', 'Mbwamaji', 'Mwera', 'Dege', 'Malimbika', 'Visikini', 'Bamba', 'Mwanzo Mgumu', 'Shirikisho', 'Minondo', 'Sara', 'Mkwajuni', 'Kichangani'],
      ),
      DarWardInfo(
        wardName: 'Tungi',
        center: LatLng(-6.8420, 39.3250),
        popularStreets: ['Tungi', 'Magogoni', 'Muungano'],
      ),
      DarWardInfo(
        wardName: 'Vijibweni',
        center: LatLng(-6.8510, 39.3180),
        popularStreets: ['Vijibweni', 'Kibene', 'Mkwajuni', 'Kisiwani', 'Upendo', 'Majengo'],
      ),
    ],
  };

  static List<String> get districtNames => districts.keys.toList();

  static List<String> getDistrictNames() => districts.keys.toList();

  static List<DarWardInfo> getWards(String districtName) {
    return districts[districtName] ?? [];
  }

  static List<DarWardInfo> getWardsForDistrict(String districtName) {
    return getWards(districtName);
  }

  static DarWardInfo? findWard(String wardName, [String? districtName]) {
    if (districtName != null) {
      final wards = getWards(districtName);
      for (final w in wards) {
        if (w.wardName.toLowerCase() == wardName.toLowerCase() ||
            w.wardName.toLowerCase().contains(wardName.toLowerCase())) {
          return w;
        }
      }
      return null;
    }

    final lower = wardName.toLowerCase();
    for (final list in districts.values) {
      for (final w in list) {
        if (w.wardName.toLowerCase() == lower ||
            w.wardName.toLowerCase().contains(lower) ||
            lower.contains(w.wardName.toLowerCase())) {
          return w;
        }
      }
    }
    return null;
  }
}
