import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supermarket_settings_model.dart';
import '../../providers/supermarket_provider.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  static Future<void> showModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PrivacyPolicyModalSheet(),
    );
  }

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isSwahili = false;

  @override
  Widget build(BuildContext context) {
    final settings =
        Provider.of<SupermarketProvider?>(context)?.settings ?? const SupermarketSettings();
    final storeName = settings.supermarketName.isNotEmpty ? settings.supermarketName : 'Quickopia';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isSwahili ? 'Sera ya Faragha' : 'Privacy Policy',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isSwahili = !_isSwahili),
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
            _buildHeroCard(storeName, settings),
            const SizedBox(height: 20),
            _buildClausesList(storeName, settings),
            const SizedBox(height: 24),
            _buildDataRightsCard(storeName),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: Text(
                _isSwahili ? 'Nimeelewa na Kukubaliana' : 'I Understand & Agree',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(String storeName, SupermarketSettings settings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.25),
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
                child: const Icon(Icons.shield_outlined, color: AppTheme.accentAmber, size: 22),
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
                      _isSwahili ? 'Ulinzi wa Taarifa Binafsi (PDPA)' : 'Data Privacy & Protection',
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
                ? 'Quickopia inathamini ufaragha wako na inalinda taarifa zako kwa mujibu wa Sheria ya Ulinzi wa Taarifa Binafsi ya Tanzania (Personal Data Protection Act 2022).'
                : 'Quickopia is dedicated to safeguarding your personal data and privacy in full compliance with the Tanzania Personal Data Protection Act (PDPA 2022) and international security best practices.',
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
                      ? 'Toleo: 2026 • Sheria Na. 11 (Tanzania)'
                      : 'Version: 2026 • Act No. 11 (Tanzania)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (settings.email.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'dpo@quickopia.app',
                    style: TextStyle(
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
    );
  }

  Widget _buildClausesList(String storeName, SupermarketSettings settings) {
    final clauses = _isSwahili ? _swahiliClauses : _englishClauses;

    return Column(
      children: clauses.map((clause) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            initiallyExpanded: clause.initiallyExpanded,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(clause.icon, color: AppTheme.primaryOrange, size: 20),
            ),
            title: Text(
              clause.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.neutralDark,
              ),
            ),
            subtitle: Text(
              clause.summary,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Divider(),
              const SizedBox(height: 6),
              Text(
                clause.detail,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataRightsCard(String storeName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.primaryNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                _isSwahili ? 'Haki Zako Kama Mtumiaji' : 'Your Data Subject Rights',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isSwahili
                ? '• Haki ya kufikia taarifa zako wakati wowote.\n'
                  '• Haki ya kurekebisha taarifa zilizokosewa.\n'
                  '• Haki ya kufuta akaunti na taarifa zako zote (Right to Erasure) moja kwa moja kupitia ukurasa wa Akaunti.\n'
                  '• Haki ya kupinga matumizi ya taarifa kwa ajili ya matangazo au masoko.'
                : '• Right to access your stored personal information at any time.\n'
                  '• Right to rectify and correct inaccurate data.\n'
                  '• Right to delete your account and associated personal data (Right to Erasure) directly in the Account tab.\n'
                  '• Right to opt out of marketing notifications and analytical profiling.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static final List<_PrivacyClause> _englishClauses = [
    const _PrivacyClause(
      icon: Icons.person_search_outlined,
      title: '1. Information We Collect',
      summary: 'Identity, phone number, delivery address & credentials',
      detail:
          'We collect information required to create your customer account, verify your identity, and deliver supermarket orders. This includes your full name, mobile phone number (Tanzanian format), email address, and saved physical delivery addresses with landmarks.',
      initiallyExpanded: true,
    ),
    const _PrivacyClause(
      icon: Icons.my_location_outlined,
      title: '2. Location & GPS Data',
      summary: 'Used solely for live delivery routing & driver dispatch',
      detail:
          'When using doorstep delivery, we collect your latitude and longitude coordinates to calculate delivery fees, locate your doorstep on OpenStreetMap, and provide real-time tracking of the delivery driver. Location data is accessed only with your permission and is never sold to third parties.',
    ),
    const _PrivacyClause(
      icon: Icons.mic_none_outlined,
      title: '3. Microphone & Voice Assistant Access',
      summary: 'On-device speech recognition for AI voice shopping',
      detail:
          'When you interact with the Quickopia AI Voice Shopping Assistant, the app requests microphone permission to convert your spoken Swahili or English words into grocery search items. Audio streams are processed in real-time and are never stored or used for acoustic surveillance.',
    ),
    const _PrivacyClause(
      icon: Icons.payments_outlined,
      title: '4. Financial & Payment Data',
      summary: 'Lipa Namba references and cash payment logs',
      detail:
          'We do not store your mobile money PINs or debit card security codes. For Lipa Namba payments (M-Pesa, Tigo Pesa, Airtel Money), we record the transaction reference code provided by you to reconcile order settlements with supermarket accounts.',
    ),
    const _PrivacyClause(
      icon: Icons.cloud_done_outlined,
      title: '5. Third-Party Infrastructure & Security',
      summary: 'Supabase PostgreSQL, Sentry Flutter, and SSL encryption',
      detail:
          'Your data is transmitted using modern TLS/HTTPS encryption and stored in PostgreSQL databases protected by strict Row-Level Security (RLS) policies. Crash diagnostics and performance telemetry are logged via Sentry to maintain platform reliability.',
    ),
    const _PrivacyClause(
      icon: Icons.auto_delete_outlined,
      title: '6. Data Retention & Account Deletion',
      summary: 'Full control to delete your account and personal records',
      detail:
          'You may request complete account deletion at any time via the "Delete Account" button in your Account profile. Upon confirmation, your profile, authentication credentials, and saved addresses are permanently purged or anonymized in compliance with the Tanzania Personal Data Protection Act.',
    ),
  ];

  static final List<_PrivacyClause> _swahiliClauses = [
    const _PrivacyClause(
      icon: Icons.person_search_outlined,
      title: '1. Taarifa Tunazokusanya',
      summary: 'Jina kamili, nambari ya simu, anwani ya kufikishiwa na barua pepe',
      detail:
          'Tunakusanya taarifa muhimu zinazowezesha kufungua akaunti yako, kuthibitisha utambulisho wako, na kukuletea mzigo wa supermarket mpaka mlangoni. Hizi ni pamoja na jina lako kamili, namba ya simu ya Tanzania, barua pepe, na maelezo ya eneo (neighborhood/alama maarufu).',
      initiallyExpanded: true,
    ),
    const _PrivacyClause(
      icon: Icons.my_location_outlined,
      title: '2. Taarifa za Eneo na GPS',
      summary: 'Inatumika tu kuelekeza dereva na kuonyesha ramani ya oda yako',
      detail:
          'Unapochagua kuletewa mzigo nyumbani au ofisini, mfumo unachukua coordinates za GPS ili kukokotoa nauli sahihi na kumuongoza dereva wa bodaboda au gari kufika mahali ulipo. Hatushiriki taarifa za eneo lako na kampuni za matangazo.',
    ),
    const _PrivacyClause(
      icon: Icons.mic_none_outlined,
      title: '3. Matumizi ya Kipaza Sauti (Microphone)',
      summary: 'Kutambua sauti unapoagiza bidhaa kupitia AI Assistant',
      detail:
          'Unapotumia msaidizi wa sauti wa AI kuagiza mahitaji ya jikoni kwa kuongea, app inaomba ruhusa ya kipaza sauti ili kubadili maneno yako ya Kiswahili au Kiingereza kuwa orodha ya manunuzi. Hatuhifadhi wala kurekodi maongezi yako binafsi.',
    ),
    const _PrivacyClause(
      icon: Icons.payments_outlined,
      title: '4. Taarifa za Malipo na Miamala',
      summary: 'Kumbukumbu ya namba ya muamala ya Lipa Namba',
      detail:
          'Hatuhifadhi PIN ya namba yako ya simu au namba za siri za kadi. Kwa malipo ya Lipa Namba (M-Pesa, Tigo Pesa, Airtel Money), tunahifadhi tu namba ya kumbukumbu ya muamala (Transaction ID) ili kuthibitisha malipo na supermarket.',
    ),
    const _PrivacyClause(
      icon: Icons.cloud_done_outlined,
      title: '5. Usalama na Seva za Uhifadhi',
      summary: 'Ulinzi wa mfumo wa Supabase na usimbaji fiche (SSL)',
      detail:
          'Taarifa zote zinalindwa kwa usimbaji fiche wa hali ya juu (TLS/HTTPS). Data zimehifadhiwa kwenye kanzidata ya PostgreSQL yenye sera kali za usalama (Row-Level Security) kuzuia mtu asiyehusika kusoma taarifa zako.',
    ),
    const _PrivacyClause(
      icon: Icons.auto_delete_outlined,
      title: '6. Kufuta Akaunti na Haki Zako',
      summary: 'Uhuru wa kufuta akaunti na maelezo yako wakati wowote',
      detail:
          'Una uwezo wa kufuta akaunti yako na maelezo yote wakati wowote kupitia kitufe cha "Futa Akaunti" kwenye ukurasa wa Akaunti. Baada ya kuthibitisha, taarifa zako zote zinafutwa kabisa kwa mujibu wa Sheria ya Ulinzi wa Taarifa Binafsi ya Tanzania.',
    ),
  ];
}

class _PrivacyClause {
  final IconData icon;
  final String title;
  final String summary;
  final String detail;
  final bool initiallyExpanded;

  const _PrivacyClause({
    required this.icon,
    required this.title,
    required this.summary,
    required this.detail,
    this.initiallyExpanded = false,
  });
}

class _PrivacyPolicyModalSheet extends StatelessWidget {
  const _PrivacyPolicyModalSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              child: PrivacyPolicyScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
