import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/heartbeat_tap.dart';
import 'adhkaar_duas_screen.dart';
import 'haddad_screen.dart';
import 'moulid_reader_screen.dart';
import 'names_screen.dart';
import 'quranic_duas_screen.dart';
import 'dua_detail_screen.dart';

class AuradItemModel {
  final String id;
  final String titleEn;
  final String titleMl;
  final String? subtitleEn;
  final String? subtitleMl;
  final int? subCategoryId;
  final int? duaId;
  final String? assetPath;
  final Widget Function(BuildContext)? customRouteBuilder;

  const AuradItemModel({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    this.subtitleEn,
    this.subtitleMl,
    this.subCategoryId,
    this.duaId,
    this.assetPath,
    this.customRouteBuilder,
  });
}

class AuradCategoryScreen extends StatefulWidget {
  final String categoryKey;
  final String categoryTitleEn;
  final String categoryTitleMl;
  final IconData icon;

  const AuradCategoryScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitleEn,
    required this.categoryTitleMl,
    required this.icon,
  });

  @override
  State<AuradCategoryScreen> createState() => _AuradCategoryScreenState();
}

class _AuradCategoryScreenState extends State<AuradCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _favoriteIds = {'haddad', 'manqoos', 'morning', 'evening'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AuradItemModel> _getItemsForCategory() {
    switch (widget.categoryKey) {
      case 'dikr':
        return const [
          AuradItemModel(
            id: 'morning',
            titleEn: 'Adkar Sabah (Morning Adhkaar)',
            titleMl: 'രാവിലെയുള്ള ദിക്റുകൾ (അദ്കാറുസ്സബാഹ്)',
            subtitleEn: 'Authentic morning litanies from Fajr to sunrise',
            subtitleMl: 'സുബ്ഹിക്ക് ശേഷമുള്ള ദിക്റുകളും പ്രാർത്ഥനകളും',
            subCategoryId: 26,
          ),
          AuradItemModel(
            id: 'evening',
            titleEn: 'Adkar Masa (Evening Adhkaar)',
            titleMl: 'വൈകുന്നേരമുള്ള ദിക്റുകൾ (അദ്കാറുൽ മസാഹ്)',
            subtitleEn: 'Authentic evening fortress from Asr to sunset',
            subtitleMl: 'അസറിന് ശേഷമുള്ള സുരക്ഷാ ദിക്റുകൾ',
            subCategoryId: 27,
          ),
          AuradItemModel(
            id: 'daily_routines',
            titleEn: 'Dikr for Daily Routines',
            titleMl: 'ദിനചര്യകളിലെ ദിക്റുകൾ',
            subtitleEn: 'Waking up, entering home, mosque & daily actions',
            subtitleMl: 'ഉണരുമ്പോഴും യാത്രകളിലും ഭവനത്തിലും ചൊല്ലേണ്ടവ',
            subCategoryId: 1,
          ),
          AuradItemModel(
            id: 'after_salah',
            titleEn: 'Adhkaar After Salah',
            titleMl: 'നമസ്കാര ശേഷമുള്ള ദിക്റുകൾ',
            subtitleEn: 'Tasbeeh, Tahmeed, Takbeer & Tasleem litanies',
            subtitleMl: 'ഫർള് നമസ്കാരങ്ങൾ പൂർത്തിയാക്കിയ ശേഷമുള്ളവ',
            subCategoryId: 24,
          ),
          AuradItemModel(
            id: 'sleep_adhkaar',
            titleEn: 'Adhkaar Before Sleep',
            titleMl: 'ഉറക്കത്തിന് മുമ്പുള്ള ദിക്റുകൾ',
            subtitleEn: 'Ayatul Kursi, 3 Quls & protections before rest',
            subtitleMl: 'ഉറങ്ങാൻ കിടക്കുമ്പോഴുള്ള സുരക്ഷാ പ്രാർത്ഥനകൾ',
            subCategoryId: 28,
          ),
          AuradItemModel(
            id: 'vird_lateef',
            titleEn: 'Vird Al-Lateef',
            titleMl: 'വിർദുല്ലത്വീഫ് (ഇമാം ഹദ്ദാദ്)',
            subtitleEn: 'Litany of divine protection by Imam al-Haddad',
            subtitleMl: 'ഇമാം ഹദ്ദാദ് (റ) തങ്ങളുടെ സുരക്ഷാ ഔറാദ്',
            assetPath: 'assets/data/haddad_ratheeb.json.gz',
          ),
        ];

      case 'dua':
        return [
          AuradItemModel(
            id: 'rabbana',
            titleEn: '40 Rabbana Quranic Duas',
            titleMl: 'വിശുദ്ധ ഖുർആനിലെ 40 റബ്ബനാ പ്രാർത്ഥനകൾ',
            subtitleEn: 'Sacred supplications directly revealed in the Quran',
            subtitleMl: 'ഖുർആനിലെ റബ്ബനാ എന്ന് തുടങ്ങുന്ന സമ്പൂർണ്ണ പ്രാർത്ഥനകൾ',
            customRouteBuilder: (_) => const QuranicDuasScreen(),
          ),
          const AuradItemModel(
            id: 'dua_after_salah',
            titleEn: 'Dua After Obligatory Salah',
            titleMl: 'ഫർള് നമസ്കാര ശേഷമുള്ള പ്രാർത്ഥന',
            subtitleEn: 'Comprehensive supplication after every Salah',
            subtitleMl: 'നമസ്കാര ശേഷമുള്ള പ്രധാന ദുആകൾ',
            subCategoryId: 24,
          ),
          const AuradItemModel(
            id: 'distress_relief',
            titleEn: 'Duas for Distress & Anxiety (Al-Karb)',
            titleMl: 'പ്രയാസങ്ങളും വിഷമങ്ങളും അകലാനുള്ള ദുആ',
            subtitleEn: 'Supplications in times of hardship and anxiety',
            subtitleMl: 'മനഃക്ലേശങ്ങളും സങ്കടങ്ങളും മാറുവാൻ',
            subCategoryId: 34,
          ),
          const AuradItemModel(
            id: 'debt_relief',
            titleEn: 'Dua for Debt Relief & Wealth',
            titleMl: 'കടബാധ്യതകൾ തീരുവാനുള്ള പ്രാർത്ഥന',
            subtitleEn: 'Prophetic supplications for paying debts',
            subtitleMl: 'സാമ്പത്തിക പ്രതിസന്ധികൾ മാറാനുള്ള പ്രാർത്ഥന',
            subCategoryId: 41,
          ),
          const AuradItemModel(
            id: 'sayyidul_istighfar',
            titleEn: 'Sayyidul Istighfar',
            titleMl: 'സയ്യിദുൽ ഇസ്തിഗ്ഫാർ (പാപമോചന പ്രാർത്ഥന)',
            subtitleEn: 'The supreme supplication for seeking forgiveness',
            subtitleMl: 'പാപങ്ങൾ പൊറുക്കപ്പെടാനുള്ള ഉത്തമ പ്രാർത്ഥന',
            subCategoryId: 1,
          ),
          const AuradItemModel(
            id: 'parent_family',
            titleEn: 'Duas for Parents & Family',
            titleMl: 'മാതാപിതാക്കൾക്കും കുടുംബത്തിനും വേണ്ടിയുള്ള പ്രാർത്ഥന',
            subtitleEn: 'Supplications for blessed family and parents',
            subtitleMl: 'മാതാപിതാക്കളുടെ കാരുണ്യത്തിനും കുടുംബ ക്ഷേമത്തിനും',
            subCategoryId: 47,
          ),
        ];

      case 'swalath':
        return const [
          AuradItemModel(
            id: 'swalath_fatih',
            titleEn: 'Swalathul Fatih',
            titleMl: 'സ്വലാത്തുൽ ഫാത്തിഹ്',
            subtitleEn: 'The Opener of what was closed',
            subtitleMl: 'വിജയങ്ങളുടെ താക്കോലായ വിശുദ്ധ സ്വലാത്ത്',
            subCategoryId: 22,
          ),
          AuradItemModel(
            id: 'swalath_tibbiyya',
            titleEn: 'Swalathut-Tibbiyya (Munaajath)',
            titleMl: 'സ്വലാത്തുത്തിബ്ബിയ്യ (ശിഫാ സ്വലാത്ത്)',
            subtitleEn: 'The prayer of healing and physical restoration',
            subtitleMl: 'ശാരീരികവും മാനസികവുമായ രോഗശമനത്തിന്',
            subCategoryId: 22,
          ),
          AuradItemModel(
            id: 'swalath_nariyyah',
            titleEn: 'Swalathun-Nariyyah (Tafrijiyyah)',
            titleMl: 'സ്വലാത്തുന്നാരിയ്യ (തഫ്രീജിയ്യ)',
            subtitleEn: 'The supplication for resolving difficult affairs',
            subtitleMl: 'ബുദ്ധിമുട്ടുകൾ ദൂരീകരിക്കപ്പെടാനുള്ള സ്വലാത്ത്',
            subCategoryId: 22,
          ),
          AuradItemModel(
            id: 'swalath_ibrahimiyya',
            titleEn: 'Swalathul Ibrahimiyya',
            titleMl: 'സ്വലാത്തുൽ ഇബ്രാഹീമിയ്യ (നമസ്കാരത്തിലെ സ്വലാത്ത്)',
            subtitleEn: 'The beloved Salah recited in every Tashahhud',
            subtitleMl: 'അത്തഹിയ്യാത്തിന് ശേഷമുള്ള വിശുദ്ധ സ്വലാത്ത്',
            subCategoryId: 22,
          ),
          AuradItemModel(
            id: 'swalath_friday',
            titleEn: 'Salawat on Jumua (Friday)',
            titleMl: 'വെള്ളിയാഴ്ചയിലെ സ്വലാത്തുകൾ',
            subtitleEn: 'Blessed litanies for Jumua day and night',
            subtitleMl: 'വെള്ളിയാഴ്ച രാവിലും പകലിലും ചൊല്ലേണ്ടവ',
            subCategoryId: 22,
          ),
          AuradItemModel(
            id: 'swalath_munjiya',
            titleEn: 'Swalathul Munjiya',
            titleMl: 'സ്വലാത്തുൽ മുൻജിയ',
            subtitleEn: 'The prayer of deliverance from all afflictions',
            subtitleMl: 'വിപത്തുകളിൽ നിന്നുള്ള മോചന പ്രാർത്ഥന',
            subCategoryId: 22,
          ),
        ];

      case 'moulid':
        return [
          AuradItemModel(
            id: 'manqoos',
            titleEn: 'Manqoos Moulid (Complete Text)',
            titleMl: 'മങ്കൂസ് മൗലിദ് (സമ്പൂർണ്ണ പാഠം)',
            subtitleEn: 'By Sheikh Zainuddin Makhdoom I (Ponnani)',
            subtitleMl: 'ശൈഖ് സൈനുദ്ദീൻ മഖ്ദൂം ഒന്നാമൻ (റ) - പൊന്നാനി',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'badr_moulid',
            titleEn: 'Badr Moulid',
            titleMl: 'ബദർ മൗലിദ്',
            subtitleEn: 'Sacred litany commemorating Martyrs of Badr',
            subtitleMl: 'ബദരീങ്ങളുടെ അപദാനങ്ങളും പ്രാർത്ഥനകളും',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'sharafal_anam',
            titleEn: 'Sharafal Anam Moulid',
            titleMl: 'ശറഫുൽ അനാം മൗലിദ്',
            subtitleEn: 'Celebrated classical panegyric on the Prophet ﷺ',
            subtitleMl: 'മുത്തുനബി ﷺ യുടെ ജന്മദിന പ്രകീർത്തനം',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'muhiyudheen_moulid',
            titleEn: 'Muhiyudheen Moulid',
            titleMl: 'മുഹ്‌യിദ്ദീൻ മൗലിദ്',
            subtitleEn: 'Litany commemorating Sheikh Abdul Qadir Jilani (RA)',
            subtitleMl: 'ശൈഖ് അബ്ദുൽ ഖാദിർ ജീലാനി (റ) തങ്ങളുടെ അപദാനം',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'rifae_moulid',
            titleEn: 'Rifae Moulid',
            titleMl: 'രിഫാഈ മൗലിദ്',
            subtitleEn: 'Litany commemorating Sheikh Ahmad al-Rifai (RA)',
            subtitleMl: 'ശൈഖ് അഹ്മദ് കബീർ രിഫാഈ (റ) തങ്ങളുടെ ചരിത്രം',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
        ];

      case 'baith':
        return [
          AuradItemModel(
            id: 'qasida_burda',
            titleEn: 'Qasida Burda (The Mantle Poem)',
            titleMl: 'ഖസീദത്തുൽ ബുർദ (ഇമാം ബൂസ്വീരി റ)',
            subtitleEn: 'The master panegyric poem of Imam al-Busiri',
            subtitleMl: 'ലോകപ്രശസ്ത കാവ്യ സമാഹാരം',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/haddad_ratheeb.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'asmaul_husna_baith',
            titleEn: 'Asmaul Husna Poetic Litany',
            titleMl: 'അസ്മാഉൽ ഹുസ്ന ബൈത്ത്',
            subtitleEn: 'Rhyming invocations with 99 Sacred Names',
            subtitleMl: 'അല്ലാഹുവിന്റെ 99 തിരുനാമങ്ങൾ കോർത്തിണക്കിയ ബൈത്ത്',
            customRouteBuilder: (_) => const NamesScreen(),
          ),
          AuradItemModel(
            id: 'tala_al_badru',
            titleEn: 'Thala al-Badru Alayna',
            titleMl: 'ത്വലഅൽ ബദ്‌റു അലൈനാ',
            subtitleEn: 'Historic anthem welcoming the Prophet ﷺ to Madinah',
            subtitleMl: 'മദീനയിലെ സ്വാഗത ഗാനം',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'ashraqa_baith',
            titleEn: 'Ashraqa Baith (Qiyam Litany)',
            titleMl: 'അശ്റഖ ബൈത്ത് (ഖിയാം ബൈത്ത്)',
            subtitleEn: 'Recited standing in reverent celebration',
            subtitleMl: 'മൗലിദുകളിലെ പ്രധാന ഖിയാം വരികൾ',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'salam_baith',
            titleEn: 'As-Salamu Alayka Ya Nabi',
            titleMl: 'സലാം ബൈത്ത്',
            subtitleEn: 'Peace and salutations unto the Messenger of Allah ﷺ',
            subtitleMl: 'മുത്തുനബി ﷺ യുടെ സന്നിധിയിലെ സലാം',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
        ];

      case 'malappatt':
        return [
          AuradItemModel(
            id: 'muhiyudheen_mala',
            titleEn: 'Muhiyudheen Mala',
            titleMl: 'മുഹ്‌യിദ്ദീൻ മാല (ഖാളി മുഹമ്മദ് റ)',
            subtitleEn: 'Historic 16th-century ode by Qazi Muhammad of Kozhikode',
            subtitleMl: 'ഖാളി മുഹമ്മദ് (റ) രചിച്ച വിശ്വോത്തര മാലപ്പാട്ട്',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/haddad_ratheeb.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'rifai_mala',
            titleEn: 'Rifa\'i Mala',
            titleMl: 'രിഫാഈ മാല',
            subtitleEn: 'Traditional spiritual ode of Sheikh Rifai (RA)',
            subtitleMl: 'രിഫാഈ ശൈഖിന്റെ അപദാന മാലപ്പാട്ട്',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/haddad_ratheeb.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'nafeesath_mala',
            titleEn: 'Nafeesath Mala',
            titleMl: 'നഫീസത്ത് മാല',
            subtitleEn: 'Ode praising Sayyida Nafeesa al-Tahira (RA)',
            subtitleMl: 'സയ്യിദത്തുനാ നഫീസത്തുൽ മിസ്‌രിയ്യ (റ) മാല',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/haddad_ratheeb.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'badriyath_mala',
            titleEn: 'Badriyath Mala',
            titleMl: 'ബദ്‌രിയ്യത്ത് മാല',
            subtitleEn: 'Ode commemorating the 313 Sahaba of Badr',
            subtitleMl: '313 ബദ്‌രീങ്ങളുടെ ചരിത്ര മാലപ്പാട്ട്',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/manqoos_moulid.json.gz',
            ),
          ),
        ];

      case 'ratheeb':
        return [
          AuradItemModel(
            id: 'haddad_ratheeb',
            titleEn: 'Ratib al-Haddad (Complete Litany)',
            titleMl: 'റാതീബുൽ ഹദ്ദാദ് (സമ്പൂർണ്ണ പാഠം)',
            subtitleEn: 'By Imam Abdullah bin Alawi al-Haddad (RA)',
            subtitleMl: 'ഇമാം ഹദ്ദാദ് (റ) തങ്ങളുടെ സമ്പൂർണ്ണ റാത്തീബ്',
            customRouteBuilder: (_) => const HaddadScreen(),
          ),
          AuradItemModel(
            id: 'haddad_dua',
            titleEn: 'Haddad Ratheeb Dua',
            titleMl: 'ഹദ്ദാദ് റാത്തീബ് ദുആ',
            subtitleEn: 'The supplication recited upon concluding Ratib al-Haddad',
            subtitleMl: 'റാത്തീബ് പൂർത്തിയായ ശേഷമുള്ള പ്രാർത്ഥന',
            customRouteBuilder: (_) => const HaddadScreen(),
          ),
          AuradItemModel(
            id: 'ratib_attas',
            titleEn: 'Ratib al-Attas',
            titleMl: 'റാതീബുൽ അത്താസ്',
            subtitleEn: 'By Imam Umar bin Abdur Rahman al-Attas (RA)',
            subtitleMl: 'ഇമാം അത്താസ് (റ) തങ്ങളുടെ പ്രസിദ്ധമായ റാത്തീബ്',
            customRouteBuilder: (_) => const HaddadScreen(),
          ),
          AuradItemModel(
            id: 'ratib_jilani',
            titleEn: 'Ratib al-Jilani',
            titleMl: 'റാതീബുൽ ജീലാനി',
            subtitleEn: 'Litany attributed to Sheikh Abdul Qadir Jilani (RA)',
            subtitleMl: 'ഗൗസുൽ അഅ്ളം ജീലാനി (റ) തങ്ങളുടെ റാത്തീബ്',
            customRouteBuilder: (_) => const HaddadScreen(),
          ),
        ];

      case 'majlisunnoor':
        return [
          AuradItemModel(
            id: 'majlisunnoor_duas',
            titleEn: 'Majlisunnoor (Complete Litany)',
            titleMl: 'മജ്‌ലിസുന്നൂർ ഔറാദ് (സമ്പൂർണ്ണം)',
            subtitleEn: 'Full 5 parts: Fatiha, Asmaul Badr, Yaseen & Dua',
            subtitleMl: 'ഫാത്തിഹ, 313 ബദ്‌രിയ്യീങ്ങൾ, യാസീൻ, ഖത്മ് ദുആ',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/majlisunnoor.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'asmaul_badriyyin',
            titleEn: 'Asmaul Badriyyin (313 Badr Sahaba)',
            titleMl: 'അസ്മാഉൽ ബദ്‌രിയ്യീൻ (313 ശുഹദാക്കൾ)',
            subtitleEn: 'Alphabetical poetic meter with spiritual refrains',
            subtitleMl: 'അക്ഷരമാലാ ക്രമത്തിലുള്ള ബദ്‌രീങ്ങളുടെ ബൈത്ത്',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/majlisunnoor.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'yaseen_majlis',
            titleEn: 'Surah Yaseen (Assembly Recitation)',
            titleMl: 'സൂറത്തു യാസീൻ (മജ്‌ലിസുന്നൂർ പാരായണം)',
            subtitleEn: 'Complete 83 verses recited during the assembly',
            subtitleMl: 'സംഗമത്തിൽ ചൊല്ലുന്ന സമ്പൂർണ്ണ യാസീൻ സൂറത്ത്',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/majlisunnoor.json.gz',
            ),
          ),
          AuradItemModel(
            id: 'munjiya_khatm',
            titleEn: 'Swalathul Munjiya & Khatm Dua',
            titleMl: 'സ്വലാത്തുൽ മുൻജിയ & സമാപന ദുആ',
            subtitleEn: 'Closing prayers for protection from afflictions',
            subtitleMl: 'വിപത്തുകളിൽ നിന്നും ശമനത്തിനായുള്ള പ്രാർത്ഥനകൾ',
            customRouteBuilder: (_) => const MoulidReaderScreen(
              assetPath: 'assets/data/majlisunnoor.json.gz',
            ),
          ),
        ];

      default:
        // 'more' or fallback
        return [
          const AuradItemModel(
            id: 'ruqyah',
            titleEn: 'Ruqyah Shariah (Divine Healing)',
            titleMl: 'റുഖ്‌യ ശരീഅ (ശമന പ്രാർത്ഥനകൾ)',
            subtitleEn: 'Cure from evil eye, envy & afflictions',
            subtitleMl: 'കണ്ണേറും രോഗങ്ങളും അകലുവാനുള്ള ഖുർആൻ ആയത്തുകൾ',
            subCategoryId: 41,
          ),
          const AuradItemModel(
            id: 'janazah',
            titleEn: 'Janazah (Funeral) Prayers & Duas',
            titleMl: 'മയ്യിത്ത് നിസ്കാരവും ദുആയും',
            subtitleEn: 'Supplications for the deceased in funeral prayer',
            subtitleMl: 'മയ്യിത്ത് നിസ്കാരത്തിലെ തക്ബീറുകളും പ്രാർത്ഥനകളും',
            subCategoryId: 55,
          ),
          const AuradItemModel(
            id: 'hajj_umrah',
            titleEn: 'Hajj & Umrah Supplications',
            titleMl: 'ഹജ്ജ്, ഉംറ പ്രാർത്ഥനകൾ',
            subtitleEn: 'Tawaf, Sa\'i, Arafah & Talbiyah prayers',
            subtitleMl: 'തവാഫിലും സഈയിലും അറഫയിലും ചൊല്ലേണ്ടവ',
            subCategoryId: 10,
          ),
          AuradItemModel(
            id: '40_rabbana',
            titleEn: '40 Rabbana Duas from Holy Quran',
            titleMl: 'വിശുദ്ധ ഖുർആനിലെ 40 റബ്ബനാ പ്രാർത്ഥനകൾ',
            subtitleEn: 'Prophetic Quranic prayers with translation',
            subtitleMl: 'ഖുർആനിക റബ്ബനാ പ്രാർത്ഥനകൾ',
            customRouteBuilder: (_) => const QuranicDuasScreen(),
          ),
        ];
    }
  }

  void _openItem(BuildContext context, AuradItemModel item) {
    HapticFeedback.selectionClick();
    if (item.customRouteBuilder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => item.customRouteBuilder!(c)),
      );
      return;
    }

    if (item.assetPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoulidReaderScreen(assetPath: item.assetPath!),
        ),
      );
      return;
    }

    final bundle = context.read<AdhkaarProvider>().bundle;
    if (item.subCategoryId != null && bundle != null) {
      final sub = bundle.subCategoryById(item.subCategoryId!);
      if (sub != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdhkaarDuasScreen(sub: sub)),
        );
        return;
      }
    }

    if (item.duaId != null && bundle != null) {
      final dua = bundle.duas[item.duaId!];
      if (dua != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DuaDetailScreen(dua: dua)),
        );
        return;
      }
    }

    // Default fallback: open category 1
    if (bundle != null && bundle.subCategories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdhkaarDuasScreen(sub: bundle.subCategories.first),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;
    final isMl = tp.isMalayalam;

    final allItems = _getItemsForCategory();
    final query = _searchQuery.trim().toLowerCase();
    final items = allItems.where((it) {
      if (query.isEmpty) return true;
      return it.titleEn.toLowerCase().contains(query) ||
          it.titleMl.toLowerCase().contains(query) ||
          (it.subtitleEn?.toLowerCase().contains(query) ?? false) ||
          (it.subtitleMl?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: tp.surfaceColor,
      appBar: AppBar(
        backgroundColor: tp.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: HeartbeatTap(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? context.cardTop : context.cardBottom,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? context.hairline : context.cardBorder,
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: tp.textPrimary,
              size: 26,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tp.primaryAccent.withValues(alpha: isDark ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, size: 18, color: tp.primaryAccent),
            ),
            const SizedBox(width: 10),
            Text(
              isMl ? widget.categoryTitleMl : widget.categoryTitleEn,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tp.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search box inside category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? context.cardTop : context.cardBottom,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? context.hairline : context.cardBorder,
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: tp.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: isMl ? 'തിരയുക...' : 'Search in this collection...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: tp.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: tp.primaryAccent,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Items List (Exact Aurad wal Manaqib Style)
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      isMl
                          ? 'ഫലങ്ങളൊന്നും കണ്ടെത്തിയില്ല'
                          : 'No litanies found in this collection',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: tp.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, idx) => Container(
                      height: 0.8,
                      margin: const EdgeInsets.only(left: 48),
                      color: isDark ? context.hairline : context.cardBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isFav = _favoriteIds.contains(item.id);

                      return HeartbeatTap(
                        onTap: () => _openItem(context, item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              // Islamic 8-pointed star icon (Rub el Hizb)
                              Icon(
                                Icons.brightness_7_outlined,
                                size: 22,
                                color: tp.primaryAccent.withValues(
                                  alpha: isDark ? 0.8 : 0.9,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Item Title and Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMl ? item.titleMl : item.titleEn,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: tp.textPrimary,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (item.subtitleEn != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        isMl
                                            ? (item.subtitleMl ??
                                                item.subtitleEn!)
                                            : item.subtitleEn!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: tp.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Favorite Heart Icon
                              HeartbeatTap(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isFav) {
                                      _favoriteIds.remove(item.id);
                                    } else {
                                      _favoriteIds.add(item.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: isFav
                                        ? Colors.redAccent
                                        : tp.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
