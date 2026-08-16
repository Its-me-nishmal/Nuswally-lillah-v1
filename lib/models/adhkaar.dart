import 'dart:convert';

const Map<int, String> kSubCategoryEnglishTitles = {
  1: 'Upon Waking Up',
  2: 'When Wearing Clothes',
  3: 'Supplication for Someone Wearing New Clothes',
  4: 'When Undressing',
  5: 'When Entering the Restroom',
  6: 'When Leaving the Restroom',
  7: 'Before Performing Wudu (Ablution)',
  8: 'Upon Completing Wudu (Ablution)',
  9: 'When Leaving the Home',
  10: 'When Entering the Home',
  11: 'When Walking to the Mosque',
  12: 'When Entering the Mosque',
  13: 'When Leaving the Mosque',
  14: 'Upon Hearing the Adhan (Call to Prayer)',
  15: 'Opening Supplications for Prayer (Istiftah)',
  16: 'Supplications During Ruku (Bowing)',
  17: 'Upon Rising From Ruku',
  18: 'Supplications During Sujood (Prostration)',
  19: 'Supplications Between the Two Prostrations',
  20: 'Supplication During Sujood Tilawat (Recitation Prostration)',
  21: 'Tashahhud (Testimony of Faith)',
  22: 'Salawat After Tashahhud',
  23: 'Supplications Before Tasleem (Ending Prayer)',
  24: 'Adhkaar After Completing Prayer',
  25: 'Supplication for Istikhara (Seeking Guidance) Prayer',
  26: 'Morning Adhkaar',
  27: 'Evening Adhkaar',
  28: 'Adhkaar Before Sleep',
  29: 'When Turning Over During the Night',
  30: 'Upon Fear or Restlessness During Sleep',
  31: 'Upon Having a Bad Dream',
  32: 'Qunut Supplication in Witr Prayer',
  33: 'Adhkaar After Completing Witr Prayer',
  34: 'Supplications for Anxiety and Distress',
  35: 'Supplications During Hardship',
  36: 'When Fearing an Enemy or Ruler',
  37: 'When Fearing Injustice from Enemies',
  38: 'Supplication Against Enemies',
  39: 'When Fearing People',
  40: 'When Doubt Arises in Faith (Imaan)',
  41: 'Supplication for Debt Relief',
  42: 'When Distracted by Shaytan During Prayer',
  43: 'When Matters Become Difficult',
  44: 'Supplication After Committing a Sin',
  45: 'To Repel Shaytan and Whispers',
  46: 'When Something Unpleasant Happens',
  47: 'Congratulations Upon a Newborn Child',
  48: 'Supplication to Protect Children',
  49: 'Supplication When Visiting the Sick',
  50: 'Virtues of Visiting the Sick',
  51: 'Supplication for the Terminally Ill',
  52: 'Prompting the Dying Person (La ilaha illallah)',
  53: 'Supplication When Afflicted by Calamity',
  54: 'Upon Closing the Eyes of the Deceased',
  55: 'Supplications in Janazah (Funeral) Prayer',
  56: 'Funeral Supplication for a Child',
  57: 'Supplication of Condolence',
  58: 'When Placing the Deceased in the Grave',
  59: 'Supplication After Burial',
  60: 'Supplication When Visiting Graves',
  61: 'Supplication When Strong Winds Blow',
  62: 'Supplication During Thunder and Lightning',
  63: 'Supplication for Rain (Istisqa)',
  64: 'Supplication When it Rains',
  65: 'Supplication After Rain Stops',
  66: 'Supplication to Halt Harmful Rain',
  67: 'Supplication Upon Sight of the Crescent Moon',
  68: 'Supplication When Breaking Fast (Iftar)',
  69: 'Supplication Before Eating',
  70: 'Supplication After Finishing Meals',
  71: 'Supplication for the Host Providing Food',
  72: 'Supplication for Someone Providing Water',
  73: "Supplication When Breaking Fast at Someone's House",
  74: 'Response of a Fasting Person When Insulted',
  75: 'Supplication Upon Seeing Early Harvested Fruit',
  76: 'Etiquette and Supplication Upon Sneezing',
  77: 'Response to One Who Sneezes',
  78: 'Supplication for a Newly Married Couple',
  79: 'Supplication for the Groom on the Wedding Night',
  80: 'Supplication Before Marital Intimacy',
  81: 'Supplication When Feeling Angry',
  82: 'Supplication Upon Seeing an Afflicted Person',
  83: 'Supplication Recited During a Gathering',
  84: 'Kaffaratul Majlis (Expiation for a Gathering)',
  85: "Response to 'May Allah Forgive You'",
  86: 'Response to Someone Who Does You a Favor',
  87: 'Protection Against Dajjal (The Antichrist)',
  88: "Supplication for One Who Spends in Allah's Cause",
  89: 'Supplication for a Lender Upon Repayment',
  90: 'Protection Against Shirk (Polytheism)',
  91: 'Supplication Upon Bad Omens or Superstition',
  92: 'Supplication When Boarding a Transport',
  93: 'Supplication for Travelling',
  94: 'Supplication When Setting Out on a Journey',
  95: 'Supplication Upon Stopping at a Location',
  96: 'Supplication Upon Returning from a Journey',
  97: 'Supplication Upon Receiving Good or Bad News',
  98: 'Virtues of Sending Salawat Upon the Prophet ﷺ',
  99: 'Spreading the Greeting of Peace (Salam)',
  100: 'Response When a Non-Muslim Greets With Salam',
  101: 'Upon Hearing the Crow of a Rooster',
  102: 'Upon Hearing Barking Dogs or Braying Donkeys',
  103: 'Response to Someone Who Insults You',
  104: 'When Praising a Fellow Muslim',
  105: 'Response of One Who Has Been Praised',
  106: 'Talbiyah (Labbayk Allahumma Labbayk)',
  107: 'When Touching the Black Stone (Hajar al-Aswad)',
  108: 'Supplication Between Rukn al-Yamani & Black Stone',
  109: 'Supplication When Standing at Safa & Marwah',
  110: 'Supplication on the Day of Arafah',
  111: "Supplication at Muzdalifah (Mash'ar al-Haram)",
  112: 'Supplication When Pelting Jamarat',
  113: 'Supplication Upon Witnessing Something Amazing',
  114: 'Supplication Upon Receiving Glad Tidings',
  115: 'Supplication When Feeling Pain in the Body',
  116: 'Supplication to Protect Against Evil Eye',
  117: 'Supplication Upon Feeling Sudden Fright',
  118: 'Supplication When Slaughtering an Animal',
  119: 'Supplication to Thwart the Plots of Shaytan',
  120: 'Seeking Forgiveness and Repentance (Istighfar & Tawbah)',
  121: 'Virtues of Tasbeeh, Tahmeed, Tahleel & Takbeer',
  122: 'How the Prophet ﷺ Counted Adhkaar',
  123: 'Comprehensive Supplications for All Goodness',
  124: 'Supplication for Protection From Trials',
  125: 'Supplication for Guidance and Steadfastness',
  126: 'Supplication for Gratitude to Allah',
  127: 'Supplication for Good Character',
  128: 'Supplication During Ill Health',
  129: 'Supplication for Good Health and Wellbeing',
  130: 'Supplication for Strengthening Faith (Imaan)',
  131: 'Supplication for Hajj and Umrah Pilgrims',
  132: 'Supplication for Protection From Whispers',
  133: 'Ruqyah (Healing Verses) for General Illness',
  134: 'Ruqyah for Physical Pain or Discomfort',
  135: 'Ruqyah for Poison or Stings',
  136: 'Istighfar (Seeking Forgiveness) and Tawbah',
  137: 'Sayyidul Istighfar (Master Supplication for Forgiveness)',
  138: 'General Supplications from the Sunnah',
  139: 'Supplication for Righteous Offspring',
  140: 'Supplication for Knowledge and Understanding',
  141: 'Supplication for Parents',
  142: 'Supplication for Forgiveness for All Believers',
  143: 'Supplication for a Good End (Husn al-Khatimah)',
  144: 'Supplication for Protection From Hellfire',
  145: 'Supplication Asking for Jannatul Firdaus',
  146: 'Supplication for Contentment and Satisfaction',
  147: 'Supplication for Family and Relatives',
  148: 'Supplication for Refuge From Oppression',
  149: 'Supplication for Light and Clarity',
  150: 'Supplication for Righteous Spouse',
  151: 'Supplication for Increase in Provisions (Rizq)',
  152: 'Supplication for Purification of the Heart',
  153: 'Supplication During Grief and Sorrow',
  154: 'Supplication for Barakah (Blessing)',
  155: 'Supplication for Safety and Protection',
  156: "Supplication Asking for Allah's Affection",
  157: 'Supplication for Deliverance From Calamity',
  158: 'Supplication Seeking Refuge From Wrath of Allah',
  159: 'Supplication Seeking Refuge From Severe Diseases',
  160: "Supplication Asking for Allah's Affection",
  161: 'Supplication Seeking Refuge From Poverty',
  162: 'Supplications Seeking Protection and Refuge',
  163: 'Supplications That Are Answered (Mustajab)',
  164: 'Supplication for Increasing Faith (Imaan)',
  165: 'Supplication for Guidance of Non-Muslims',
  166: 'Supplication for Laylatul Qadr (Night of Power)',
};

class DuaWord {
  final String arabic;
  final String malayalam;

  const DuaWord({required this.arabic, required this.malayalam});

  factory DuaWord.fromJson(Map<String, dynamic> json) => DuaWord(
        arabic: json['ar']?.toString() ?? '',
        malayalam: json['ml']?.toString() ?? '',
      );
}

class HadithNote {
  final String hadith;
  final String title;

  const HadithNote({required this.hadith, required this.title});

  factory HadithNote.fromJson(Map<String, dynamic> json) => HadithNote(
        hadith: json['hadith']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
      );
}

class Dua {
  final int id;
  final String dua;
  final String trans;
  final String transli;
  final String ref;
  final String desc;
  final String descEn;
  final String hint;
  final String audioUrl;
  final List<HadithNote> hadith;
  final List<DuaWord> wordByWord;

  const Dua({
    required this.id,
    required this.dua,
    required this.trans,
    required this.transli,
    required this.ref,
    required this.desc,
    required this.descEn,
    required this.hint,
    required this.audioUrl,
    required this.hadith,
    required this.wordByWord,
  });

  bool get hasArabic => dua.trim().isNotEmpty;

  String get fullAudioUrl {
    final a = audioUrl.trim();
    if (a.isEmpty) return '';
    if (a.startsWith('http')) return a;
    return 'https://raw.githubusercontent.com/expertmars/awraad_audio/main/${a.endsWith('.mp3') ? a : '$a.mp3'}';
  }

  factory Dua.fromJson(Map<String, dynamic> json) => Dua(
        id: (json['id'] as num?)?.toInt() ?? 0,
        dua: json['dua']?.toString().trim() ?? '',
        trans: json['trans']?.toString().trim() ?? '',
        transli: json['transli']?.toString().trim() ?? '',
        ref: json['ref']?.toString().trim() ?? '',
        desc: json['desc']?.toString().trim() ?? '',
        descEn: json['desc_en']?.toString().trim() ?? '',
        hint: json['hint']?.toString().trim() ?? '',
        audioUrl: json['audio_url']?.toString() ?? '',
        hadith: ((json['dua_hadith'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => HadithNote.fromJson(e))
            .toList(),
        wordByWord: ((json['word_by_word'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => DuaWord.fromJson(e))
            .toList(),
      );
}

class AdhkaarSubCategory {
  final int id;
  final String title;
  final String titleEn;
  final String titleArabic;
  final List<int> duaIds;

  const AdhkaarSubCategory({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.titleArabic,
    required this.duaIds,
  });

  factory AdhkaarSubCategory.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final jsonEn = json['title_en']?.toString().trim() ?? '';
    final fallbackEn = kSubCategoryEnglishTitles[id] ?? '';

    return AdhkaarSubCategory(
      id: id,
      title: json['title']?.toString() ?? '',
      titleEn: jsonEn.isNotEmpty ? jsonEn : fallbackEn,
      titleArabic: json['title_arabic']?.toString() ?? '',
      duaIds: ((json['duas'] as List?) ?? const [])
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(),
    );
  }
}

class AdhkaarCategory {
  final int id;
  final String title;
  final String titleEn;
  final String icon;
  final List<int> subCategoryIds;

  const AdhkaarCategory({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.icon = '',
    required this.subCategoryIds,
  });

  factory AdhkaarCategory.fromJson(Map<String, dynamic> json) => AdhkaarCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        titleEn: json['title_en']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        subCategoryIds: ((json['sub_cats'] as List?) ?? const [])
            .whereType<num>()
            .map((e) => e.toInt())
            .toList(),
      );
}

class AsmaulHusnaName {
  final int slNo;
  final String arabic;
  final String trans;
  final String transli;
  final String audioUrl;

  const AsmaulHusnaName({
    required this.slNo,
    required this.arabic,
    required this.trans,
    required this.transli,
    this.audioUrl = '',
  });

  String get fullAudioUrl {
    final a = audioUrl.trim();
    if (a.isEmpty) return '';
    if (a.startsWith('http')) return a;
    return 'https://raw.githubusercontent.com/expertmars/awraad_audio/main/${a.endsWith('.mp3') ? a : '$a.mp3'}';
  }

  factory AsmaulHusnaName.fromJson(Map<String, dynamic> json) => AsmaulHusnaName(
        slNo: (json['sl_no'] as num?)?.toInt() ?? 0,
        arabic: json['name_arabic']?.toString() ?? '',
        trans: json['name_trans']?.toString() ?? '',
        transli: json['name_transli']?.toString() ?? '',
        audioUrl: json['audio_url']?.toString() ?? '',
      );
}

class AdhkaarBundle {
  final List<AdhkaarCategory> categories;
  final List<AdhkaarSubCategory> subCategories;
  final Map<int, Dua> duas;
  final List<AsmaulHusnaName> names;
  final List<int> quranicDuaIds;
  final String quranicDuasTitle;
  final String quranicDuasTitleMl;

  AdhkaarBundle({
    required this.categories,
    required this.subCategories,
    required this.duas,
    required this.names,
    required this.quranicDuaIds,
    required this.quranicDuasTitle,
    required this.quranicDuasTitleMl,
  });

  AdhkaarSubCategory? subCategoryById(int id) {
    for (final s in subCategories) {
      if (s.id == id) return s;
    }
    return null;
  }

  factory AdhkaarBundle.fromJson(Map<String, dynamic> json) {
    final rawDuas = (json['duas'] as List?) ?? const [];
    final mapDuas = <int, Dua>{};
    for (final e in rawDuas) {
      if (e is Map<String, dynamic>) {
        final id = (e['id'] as num?)?.toInt();
        if (id != null) {
          mapDuas[id] = Dua.fromJson(e);
        }
      }
    }

    return AdhkaarBundle(
      categories: ((json['categories'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => AdhkaarCategory.fromJson(e))
          .toList(),
      subCategories: ((json['sub_categories'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => AdhkaarSubCategory.fromJson(e))
          .toList(),
      duas: mapDuas,
      names: ((json['asmaul_husna'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => AsmaulHusnaName.fromJson(e))
          .toList(),
      quranicDuaIds: (json['collections'] != null &&
              json['collections']['quranic_duas'] != null &&
              json['collections']['quranic_duas']['ids'] != null)
          ? ((json['collections']['quranic_duas']['ids'] as List)
              .whereType<num>()
              .map((e) => e.toInt())
              .toList())
          : const [],
      quranicDuasTitle: (json['collections'] != null &&
              json['collections']['quranic_duas'] != null)
          ? json['collections']['quranic_duas']['title']?.toString() ??
              'Quranic Duas'
          : 'Quranic Duas',
      quranicDuasTitleMl: (json['collections'] != null &&
              json['collections']['quranic_duas'] != null)
          ? json['collections']['quranic_duas']['title_ml']?.toString() ??
              'ഖുർആനിക ദുആകൾ'
          : 'ഖുർആനിക ദുആകൾ',
    );
  }

  static AdhkaarBundle fromRaw(String raw) =>
      AdhkaarBundle.fromJson(json.decode(raw) as Map<String, dynamic>);
}
