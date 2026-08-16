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

  /// AlQuran Cloud CDN audio edition identifier (only for verified active 200/206 editions)
  String? getAlQuranCloudEdition() {
    final path = relativePath.toLowerCase();
    final n = name.toLowerCase();
    if (path.contains('minshaawee') || path.contains('minshawi') || n.contains('minshawi')) return 'ar.minshawi';
    if (path.contains('shaatree') || path.contains('shatri') || n.contains('shatri')) return 'ar.shaatree';
    if (path.contains('hudhayfee') || path.contains('hudhaifi') || n.contains('hudhaify') || n.contains('hudhaifi')) return 'ar.hudhaify';
    if (path.contains('husaree') || path.contains('husary') || n.contains('husary') || n.contains('hussary')) return 'ar.husary';
    if (path.contains('mu3ayqlee') || path.contains('muaiqly') || n.contains('muaiqly') || n.contains('muaiqli')) return 'ar.mahermuaiqly';
    if (path.contains('ajmee') || path.contains('ajmy') || n.contains('ajmy') || n.contains('ajami')) return 'ar.ahmedajamy';
    if (path.contains('ayyoob') || path.contains('ayyoub') || n.contains('ayyoub') || n.contains('ayyoob')) return 'ar.muhammadayyoub';
    if (path.contains('jibreel') || n.contains('jibreel') || n.contains('jibril')) return 'ar.muhammadjibreel';
    if (path.contains('mishaari') || path.contains('afasy') || path.contains('alafasy') || n.contains('afasy')) return 'ar.alafasy';
    return null;
  }

  /// Primary AlQuran Cloud CDN per-Ayah stream (Global Ayah 1 to 6236)
  String? getAlQuranCloudAyahUrl(int globalAyahNumber, {int bitrate = 128}) {
    final edition = getAlQuranCloudEdition();
    if (edition == null) return null;
    return 'https://cdn.islamic.network/quran/audio/$bitrate/$edition/$globalAyahNumber.mp3';
  }

  String getAyahDirectory() {
    final path = relativePath.toLowerCase();
    final n = name.toLowerCase();

    if (path.contains('suday') || path.contains('sudais') || n.contains('sudais')) return 'Abdurrahmaan_As-Sudais_192kbps';
    if (path.contains('baasit') || path.contains('basit') || n.contains('basit')) {
      return path.contains('mujawwad') ? 'Abdul_Basit_Mujawwad_128kbps' : 'Abdul_Basit_Murattal_192kbps';
    }
    if (path.contains('minshaawee') || path.contains('minshawi') || n.contains('minshawi')) {
      return path.contains('mujawwad') ? 'Minshawy_Mujawwad_192kbps' : 'Minshawy_Murattal_128kbps';
    }
    if (path.contains('shaatree') || path.contains('shatri') || n.contains('shatri')) return 'Abu_Bakr_Ash-Shaatree_128kbps';
    if (path.contains('shuraym') || n.contains('shuraym') || n.contains('shuraim')) return 'Saood_ash-Shuraym_128kbps';
    if (path.contains('ghaamidee') || path.contains('ghamdi') || n.contains('ghamdi')) return 'Ghamadi_40kbps';
    if (path.contains('hudhayfee') || path.contains('hudhaifi') || n.contains('hudhaifi')) return 'Hudhaify_128kbps';
    if (path.contains('husaree') || path.contains('husary') || n.contains('husary')) {
      return path.contains('mujawwad') ? 'Husary_Mujawwad_128kbps' : 'Husary_128kbps';
    }
    if (path.contains('juhaynee') || path.contains('juhani') || n.contains('juhani')) return 'Abdullaah_3awwaad_Al-Juhaynee_128kbps';
    if (path.contains('basfar') || n.contains('basfar')) return 'Abdullah_Basfar_192kbps';
    if (path.contains('rifaa3ee') || path.contains('rifai') || n.contains('rifai')) return 'Hani_Rifai_192kbps';
    if (path.contains('mu3ayqlee') || path.contains('muaiqly') || n.contains('muaiqly')) return 'Maher_AlMuaiqly_64kbps';
    if (path.contains('dawsaree') || path.contains('dosari') || path.contains('dussary') || n.contains('dosari') || n.contains('dussary')) return 'Yasser_Ad-Dussary_128kbps';
    if (path.contains('qatamee') || path.contains('qatami') || n.contains('qatami')) return 'Nasser_Alqatami_128kbps';
    if (path.contains('ajmee') || path.contains('ajmy') || n.contains('ajamy') || n.contains('ajmy')) return 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net';
    if (path.contains('matrood') || n.contains('matrood') || n.contains('matroud')) return 'Abdullah_Matroud_128kbps';
    if (path.contains('ayyoob') || path.contains('ayyoub') || n.contains('ayyoub')) return 'Muhammad_Ayyoub_128kbps';
    if (path.contains('jibreel') || n.contains('jibreel')) return 'Muhammad_Jibreel_128kbps';
    if (path.contains('budair') || n.contains('budair')) return 'Salah_Al_Budair_128kbps';
    if (path.contains('jaber') || n.contains('ali jaber')) return 'Ali_Jaber_64kbps';
    if (path.contains('ismail') || n.contains('mustafa ismail')) return 'Mustafa_Ismail_48kbps';
    if (path.contains('tablawi') || path.contains('tablaway') || n.contains('tablawi')) return 'Mohammad_al_Tablaway_128kbps';
    if (path.contains('abbad') || n.contains('fares abbad')) return 'Fares_Abbad_64kbps';
    if (path.contains('qasim') || path.contains('muhsin') || n.contains('qasim')) return 'Muhsin_Al_Qasim_192kbps';
    if (path.contains('akhdar') || n.contains('akhdar')) return 'Ibrahim_Akhdar_32kbps';
    if (path.contains('baleela') || n.contains('baleela') || n.contains('balila')) return 'Bandar_Baleela_64kbps';
    if (path.contains('bukhatir') || n.contains('bukhatir')) return 'Salah_Bukhatir_128kbps';
    if (path.contains('qahtaanee') || path.contains('qahtani') || n.contains('qahtani')) return 'Khaalid_Al-Qahtaanee_192kbps';
    if (path.contains('alili') || n.contains('alili')) return 'Aziz_Alili_128kbps';
    if (path.contains('alaqmi') || n.contains('alaqmy')) return 'Akram_AlAlaqimy_128kbps';
    if (path.contains('souasi') || path.contains('suesy') || n.contains('suesy')) return 'Ali_Hajjaj_AlSuesy_128kbps';
    if (path.contains('yasin') || path.contains('yassin') || n.contains('yassin')) return 'Sahl_Yassin_128kbps';

    return 'Alafasy_128kbps';
  }

  /// Ayah audio URL (direct to high-speed verified endpoint without 403 delays)
  String getAyahAudioUrl(int surahNumber, int verseNumber, {int? globalNumber}) {
    if (globalNumber != null && globalNumber > 0) {
      final cloudUrl = getAlQuranCloudAyahUrl(globalNumber);
      if (cloudUrl != null) return cloudUrl;
    }
    final sPad = surahNumber.toString().padLeft(3, '0');
    final vPad = verseNumber.toString().padLeft(3, '0');
    final dir = getAyahDirectory();
    return 'https://everyayah.com/data/$dir/$sPad$vPad.mp3';
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
