class Qari {
  final int id;
  final String name;
  final String arabicName;
  final String relativePath;
  final String fileFormat;
  final int sectionId;

  const Qari({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.relativePath,
    this.fileFormat = 'mp3',
    this.sectionId = 1,
  });

  /// QuranicAudio full-surah audio stream
  String getSurahAudioUrl(int surahNumber) {
    final pad = surahNumber.toString().padLeft(3, '0');
    final cleanPath = relativePath.endsWith('/') ? relativePath : '$relativePath/';
    return 'https://download.quranicaudio.com/quran/$cleanPath$pad.mp3';
  }

  /// AlQuran Cloud CDN audio edition identifier
  String getAlQuranCloudEdition() {
    final path = relativePath.toLowerCase();
    if (path.contains('suday') || path.contains('sudais')) return 'ar.sudais';
    if (path.contains('baasit') || path.contains('basit')) return 'ar.abdulbasitmurattal';
    if (path.contains('minshaawee') || path.contains('minshawi')) return 'ar.minshawi';
    if (path.contains('shaatree') || path.contains('shatri')) return 'ar.shaatree';
    if (path.contains('shuraym')) return 'ar.shuraim';
    if (path.contains('hudhayfee') || path.contains('hudhaifi')) return 'ar.hudhaify';
    if (path.contains('husaree') || path.contains('husary')) return 'ar.husary';
    if (path.contains('basfar')) return 'ar.abdullahbasfar';
    if (path.contains('rifaa3ee') || path.contains('rifai')) return 'ar.hanirifai';
    if (path.contains('mu3ayqlee') || path.contains('muaiqly')) return 'ar.mahermuaiqly';
    if (path.contains('ajmee') || path.contains('ajmy')) return 'ar.ahmedajamy';
    if (path.contains('ayman')) return 'ar.aymanswoid';
    return 'ar.alafasy';
  }

  /// Primary AlQuran Cloud CDN per-Ayah stream (Global Ayah 1 to 6236)
  String getAlQuranCloudAyahUrl(int globalAyahNumber, {int bitrate = 128}) {
    final edition = getAlQuranCloudEdition();
    return 'https://cdn.islamic.network/quran/audio/$bitrate/$edition/$globalAyahNumber.mp3';
  }

  String getAyahDirectory() {
    final path = relativePath.toLowerCase();
    if (path.contains('suday') || path.contains('sudais')) return 'Abdurrahmaan_As-Sudais_192kbps';
    if (path.contains('baasit') || path.contains('basit')) return 'Abdul_Basit_Murattal_192kbps';
    if (path.contains('minshaawee') || path.contains('minshawi')) return 'Minshawy_Murattal_128kbps';
    if (path.contains('shaatree') || path.contains('shatri')) return 'Abu_Bakr_Ash-Shaatree_128kbps';
    if (path.contains('shuraym')) return 'Saood_ash-Shuraym_128kbps';
    if (path.contains('ghaamidee') || path.contains('ghamdi')) return 'Ghamadi_40kbps';
    if (path.contains('hudhayfee') || path.contains('hudhaifi')) return 'Hudhaify_128kbps';
    if (path.contains('husaree') || path.contains('husary')) return 'Husary_128kbps';
    if (path.contains('juhaynee') || path.contains('juhani')) return 'Abdullaah_3awwaad_Al-Juhaynee_128kbps';
    if (path.contains('basfar')) return 'Abdullah_Basfar_192kbps';
    if (path.contains('rifaa3ee') || path.contains('rifai')) return 'Hani_Rifai_192kbps';
    if (path.contains('mu3ayqlee') || path.contains('muaiqly')) return 'Maher_AlMuaiqly_64kbps';
    if (path.contains('dawsaree') || path.contains('dosari') || path.contains('dussary')) return 'Yasser_Ad-Dussary_128kbps';
    if (path.contains('qatamee') || path.contains('qatami')) return 'Nasser_Alqatami_128kbps';
    if (path.contains('qahtaanee') || path.contains('qahtani')) return 'Khaalid_Al-Qahtaanee_192kbps';
    if (path.contains('baleela') || path.contains('balila')) return 'Bandar_Baleela_128kbps';
    if (path.contains('bukhatir')) return 'Salah_Bukhatir_128kbps';
    if (path.contains('ajmee') || path.contains('ajmy')) return 'Ahmed_ibn_Ali_al-Ajamy_128kbps';
    if (path.contains('matrood')) return 'Abdullah_Matroud_128kbps';
    if (path.contains('muhsin') || path.contains('qasim')) return 'Abdulmohsen_Al-Qasim_192kbps';
    return 'Alafasy_128kbps';
  }

  /// Ayah audio URL (uses AlQuran Cloud CDN with fallback support)
  String getAyahAudioUrl(int surahNumber, int verseNumber, {int? globalNumber}) {
    if (globalNumber != null && globalNumber > 0) {
      return getAlQuranCloudAyahUrl(globalNumber);
    }
    final sPad = surahNumber.toString().padLeft(3, '0');
    final vPad = verseNumber.toString().padLeft(3, '0');
    final dir = getAyahDirectory();
    return 'https://www.everyayah.com/data/$dir/$sPad$vPad.mp3';
  }

  factory Qari.fromJson(Map<String, dynamic> json) {
    return Qari(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Qari',
      arabicName: json['arabic_name'] as String? ?? '',
      relativePath: json['relative_path'] as String? ?? '',
      fileFormat: json['file_formats'] as String? ?? 'mp3',
      sectionId: json['section_id'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arabic_name': arabicName,
      'relative_path': relativePath,
      'file_formats': fileFormat,
      'section_id': sectionId,
    };
  }
}
