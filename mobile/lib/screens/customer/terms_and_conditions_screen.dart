import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supermarket_settings_model.dart';
import '../../providers/supermarket_provider.dart';
import '../../theme/app_theme.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  final int initialTabIndex;

  const TermsAndConditionsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsAndConditionsScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  static Future<void> showModal(BuildContext context, {int initialTabIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TermsModalSheet(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isSwahili = false;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        Provider.of<SupermarketProvider?>(context)?.settings ?? const SupermarketSettings();
    final storeName = settings.supermarketName.isNotEmpty ? settings.supermarketName : 'Quickopia';
    final storeBranch = settings.branchAddress.isNotEmpty ? settings.branchAddress : 'Dar es Salaam';
    final returnHours = settings.returnWindowHours;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isSwahili ? 'Vigezo na Masharti' : 'Terms & Conditions',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _isSwahili = !_isSwahili);
            },
            icon: const Icon(Icons.language_rounded, color: Colors.white, size: 18),
            label: Text(
              _isSwahili ? 'English' : 'Kiswahili',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store Identity & Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryOrange, Color(0xFFE64A19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.gavel_rounded, color: AppTheme.accentAmber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _isSwahili ? 'Mkataba Rasmi wa Huduma' : 'Official Service Agreement',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.accentAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSwahili
                        ? 'Karibu $storeName ($storeBranch). Kwa kutumia mfumo huu kuagiza mboga, nafaka, na bidhaa za nyumbani, au kutoa huduma ya usafirishaji, unakubaliana na sera na masharti yafuatayo.'
                        : 'Welcome to $storeName ($storeBranch). By ordering groceries, fresh foods, and essentials, or providing delivery services, you agree to these operational and legal policies.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isSwahili
                              ? 'Marekebisho: Septemba 2026 • Toleo 2.5'
                              : 'Last Updated: Sept 2026 • Version 2.5',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (settings.phone.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📞 ${settings.phone}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Segmented Audience Control (Customer vs Driver)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _isSwahili ? 'Vigezo vya Wateja' : 'Customer Terms',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0
                                  ? AppTheme.primaryOrange
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _isSwahili ? 'Kanuni za Dereva' : 'Driver Guidelines',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1
                                  ? AppTheme.primaryOrange
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 20),

            // Clauses Content based on Tab
            if (_selectedTab == 0) ...[
              // Customer Clauses
              _buildClause(
                index: '1',
                titleEn: 'Supermarket Inventory & Freshness Guarantee',
                titleSw: 'Upatikanaji wa Bidhaa na Ubora wa Vyakula',
                bodyEn:
                    'All items, including fresh fruits, vegetables, butchery meats, and pantry grains (sugar, rice, flour), are sourced directly from verified $storeName shelves. If any item is out of stock at packing, our staff contacts you immediately to provide a fresh alternative or instant refund.',
                bodySw:
                    'Bidhaa zote za vyakula zikiwemo mboga, matunda, nyama, maziwa, na vyakula vya nafaka vinatolewa moja kwa moja kutoka kwenye stoo za $storeName. Bidhaa ikikosekana, wafanyakazi wetu watakupigia simu kuchagua mbadala safi au kukurudishia pesa zako.',
                icon: Icons.inventory_2_outlined,
              ),

              _buildClause(
                index: '2',
                titleEn: '30-Minute Express Delivery & Click & Collect',
                titleSw: 'Uwasilishaji wa Haraka (30 Mins) na Kuchukua Dukani',
                bodyEn:
                    'Express deliveries are dispatched across Dar es Salaam (Kinondoni, Ilala, Ubungo, Kigamboni, and Temeke). Estimated transit times are typically 30 to 45 minutes. For Click & Collect orders, collect your bagged groceries from the supermarket customer desk with your order ID.',
                bodySw:
                    'Uwasilishaji wa haraka unafanyika katika wilaya zote za Dar es Salaam (Kinondoni, Ilala, Ubungo, Kigamboni, na Temeke). Muda unaokadiriwa ni dakika 30 hadi 45. Kwa agizo la kuchukua dukani (Click & Collect), chukua mzigo wako kaunta ya huduma ya duka.',
                icon: Icons.delivery_dining_outlined,
              ),

              _buildClause(
                index: '3',
                titleEn: 'Official Lipa Namba & Mobile Money Payments',
                titleSw: 'Usalama wa Malipo kupitia Mitandao ya Simu na Benki',
                bodyEn:
                    'Payments are processed via official Lipa Namba numbers for M-Pesa, Tigo Pesa, Airtel Money, HaloPesa, and direct NMB/CRDB bank transfers shown in-app. Cash on Delivery is available for verified accounts. Never send payments to private courier phone numbers.',
                bodySw:
                    'Malipo yote yanafanyika kwa Lipa Namba rasmi za M-Pesa, Tigo Pesa, Airtel Money, HaloPesa na benki (NMB/CRDB). Lipa Baada ya Kupokea (Cash on Delivery) inapatikana kwa wateja waliothibitishwa. Kamwe usilipe fedha kwenye namba binafsi ya dereva.',
                icon: Icons.payments_outlined,
              ),

              _buildClause(
                index: '4',
                titleEn: 'Pickup Verification Code (6-Digit OTP)',
                titleSw: 'Msimbo wa Usalama wa Mteja (Tarakimu 6)',
                bodyEn:
                    'For your safety, every order generates a unique 6-digit confirmation code. Only provide this code to the courier after you have physically received and inspected your grocery packages.',
                bodySw:
                    'Kila agizo linatengeneza msimbo maalum wa tarakimu 6. Mpe dereva msimbo huu pale tu utakapokuwa umekabidhiwa mzigo wako na kuridhika na bidhaa zote.',
                icon: Icons.verified_user_outlined,
              ),

              _buildClause(
                index: '5',
                titleEn: 'Returns, Damage Claims & Refunds ($returnHours Hours Window)',
                titleSw: 'Bidhaa Zilizoharibika na Kurudishiwa Pesa (Masaa $returnHours)',
                bodyEn:
                    'Perishable food items must be inspected upon arrival and any damage reported within $returnHours hours via in-app Live Support. Non-perishable packaged items may be claimed within 24 hours. Valid claims receive an immediate replacement dispatch or 100% refund.',
                bodySw:
                    'Vyakula vibichi vinapaswa kukaguliwa vikifika, na hitilafu yoyote itolewe taarifa ndani ya masaa $returnHours kupitia Live Support yetu ya ndani ya app. Bidhaa kavu za vifungashio zinaweza kuripotiwa ndani ya masaa 24. Pesa zitarudishwa mara moja au mzigo mpya kutumwa.',
                icon: Icons.assignment_return_outlined,
              ),

              _buildClause(
                index: '6',
                titleEn: 'Customer Privacy & Data Protection',
                titleSw: 'Faragha ya Wateja na Usalama wa Mawasiliano',
                bodyEn:
                    'Your phone number, saved Dar es Salaam delivery address, and order records are encrypted and strictly used for order dispatch, driver routing, and transaction receipts.',
                bodySw:
                    'Namba yako ya simu na anwani yako ya Dar es Salaam zinalindwa kwa usiri mkubwa na zinatumika tu kuongoza dereva kukuletea mzigo wako na kukutumia risiti.',
                icon: Icons.privacy_tip_outlined,
              ),
            ] else ...[
              // Driver Guidelines & Safety
              _buildClause(
                index: '1',
                titleEn: 'Hygiene & Cold-Chain Grocery Transport',
                titleSw: 'Usafi wa Sanduku la Usafirishaji na Vyakula',
                bodyEn:
                    'Drivers must keep delivery thermal boxes sanitized and clean. Perishable chilled items (dairy, butchery meats) must be separated from household cleaners and hot items at all times to prevent contamination.',
                bodySw:
                    'Madereva wote wanatakiwa kusafisha maboksi yao ya pikipiki kila siku. Vyakula baridi na vya freshi (maziwa, nyama) visitanganywe kamwe na sabuni au vitu vya moto ili kuzuia uchafuzi.',
                icon: Icons.kitchen_outlined,
              ),

              _buildClause(
                index: '2',
                titleEn: 'Mandatory 6-Digit OTP Delivery Confirmation',
                titleSw: 'Uthibitisho wa Msimbo wa OTP (Tarakimu 6)',
                bodyEn:
                    'Drivers must never mark an order as "Delivered" without entering the valid 6-digit confirmation code provided by the customer at their doorstep. Forcing completion without the code constitutes a violation of delivery agreement.',
                bodySw:
                    'Dereva haruhusiwi kukamilisha agizo bila kuingiza msimbo sahihi wa tarakimu 6 atakaopewa na mteja mlangoni. Kukamilisha agizo bila msimbo ni uvunjifu wa mkataba wa kazi.',
                icon: Icons.pin_outlined,
              ),

              _buildClause(
                index: '3',
                titleEn: 'Professional Conduct & Dar es Salaam Delivery Decorum',
                titleSw: 'Nidhamu ya Kazi na Maadili kwa Wateja',
                bodyEn:
                    'Always greet customers politely, call ahead if navigating complex Dar es Salaam streets or gated neighborhoods, and present orders carefully in supermarket bags without mishandling.',
                bodySw:
                    'Msalimie mteja kwa heshima, piga simu mapema unapokaribia mtaa au geti lake, na mkabidhi mifuko ya $storeName kwa uangalifu bila kuibamiza.',
                icon: Icons.handshake_outlined,
              ),

              _buildClause(
                index: '4',
                titleEn: 'Strict Customer Privacy & Zero Harassment Policy',
                titleSw: 'Faragha ya Wateja na Marufuku ya Kero Baada ya Kazi',
                bodyEn:
                    'Customer phone numbers and location pins are strictly for active order navigation. Drivers are forbidden from contacting customers, texting, or messaging after delivery has ended. Violations result in immediate account termination.',
                bodySw:
                    'Namba ya mteja inatumika tu wakati wa kumpelekea mzigo. Ni marufuku kabisa kumpigia simu, kumtumia meseji za WhatsApp, au kumsumbua mteja baada ya mzigo kukabidhiwa. Ukiukaji utasababisha kufungiwa akaunti mara moja.',
                icon: Icons.shield_outlined,
              ),

              _buildClause(
                index: '5',
                titleEn: 'Road Safety & Traffic Laws Compliance',
                titleSw: 'Usalama Barabarani na Sheria za Trafiki',
                bodyEn:
                    'Wear an approved safety helmet, maintain valid driving license and motorcycle insurance, and obey all traffic lights and speed limits across Dar es Salaam roads.',
                bodySw:
                    'Vaa kofia ngumu (helmet) safi kila safari, hakikisha leseni yako na bima ya chombo viko hai, na tii taa zote za barabarani na sheria za usalama.',
                icon: Icons.two_wheeler_outlined,
              ),
            ],

            const SizedBox(height: 24),

            // Accept / Dismiss Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _isSwahili ? 'Nimeelewa na Kukubaliana' : 'I Understand & Agree',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildClause({
    required String index,
    required String titleEn,
    required String titleSw,
    required String bodyEn,
    required String bodySw,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == '1' || index == '2',
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
            ),
          ),
          title: Text(
            _isSwahili ? '$index. $titleSw' : '$index. $titleEn',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                _isSwahili ? bodySw : bodyEn,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsModalSheet extends StatelessWidget {
  final int initialTabIndex;

  const _TermsModalSheet({this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: TermsAndConditionsScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }
}
