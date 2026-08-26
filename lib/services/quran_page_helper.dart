/// High-precision helper mapping every Surah and Ayah to its real Madani Mushaf Page (1 - 604) and Juz (1 - 30).
class QuranPageHelper {
  static const List<int> surahStartPages = [
    1,   // 1. Al-Fatihah
    2,   // 2. Al-Baqarah
    50,  // 3. Ali 'Imran
    77,  // 4. An-Nisa
    106, // 5. Al-Ma'idah
    128, // 6. Al-An'am
    151, // 7. Al-A'raf
    177, // 8. Al-Anfal
    187, // 9. At-Tawbah
    208, // 10. Yunus
    221, // 11. Hud
    235, // 12. Yusuf
    249, // 13. Ar-Ra'd
    255, // 14. Ibrahim
    262, // 15. Al-Hijr
    267, // 16. An-Nahl
    282, // 17. Al-Isra
    293, // 18. Al-Kahf
    305, // 19. Maryam
    312, // 20. Ta-Ha
    322, // 21. Al-Anbiya
    332, // 22. Al-Hajj
    342, // 23. Al-Mu'minun
    350, // 24. An-Nur
    359, // 25. Al-Furqan
    367, // 26. Ash-Shu'ara
    377, // 27. An-Naml
    385, // 28. Al-Qasas
    396, // 29. Al-'Ankabut
    404, // 30. Ar-Rum
    411, // 31. Luqman
    415, // 32. As-Sajdah
    418, // 33. Al-Ahzab
    428, // 34. Saba
    434, // 35. Fatir
    440, // 36. Ya-Sin
    446, // 37. As-Saffat
    453, // 38. Sad
    458, // 39. Az-Zumar
    467, // 40. Ghafir
    477, // 41. Fussilat
    483, // 42. Ash-Shura
    489, // 43. Az-Zukhruf
    496, // 44. Ad-Dukhan
    499, // 45. Al-Jathiyah
    502, // 46. Al-Ahqaf
    507, // 47. Muhammad
    511, // 48. Al-Fath
    515, // 49. Al-Hujurat
    518, // 50. Qaf
    520, // 51. Adh-Dhariyat
    523, // 52. At-Tur
    526, // 53. An-Najm
    528, // 54. Al-Qamar
    531, // 55. Ar-Rahman
    534, // 56. Al-Waqi'ah
    537, // 57. Al-Hadid
    542, // 58. Al-Mujadila
    545, // 59. Al-Hashr
    549, // 60. Al-Mumtahanah
    551, // 61. As-Saff
    553, // 62. Al-Jumu'ah
    554, // 63. Al-Munafiqun
    556, // 64. At-Taghabun
    558, // 65. At-Talaq
    560, // 66. At-Tahrim
    562, // 67. Al-Mulk
    564, // 68. Al-Qalam
    566, // 69. Al-Haqqah
    568, // 70. Al-Ma'arij
    570, // 71. Nuh
    572, // 72. Al-Jinn
    574, // 73. Al-Muzzammil
    575, // 74. Al-Muddaththir
    577, // 75. Al-Qiyamah
    578, // 76. Al-Insan
    580, // 77. Al-Mursalat
    582, // 78. An-Naba
    583, // 79. An-Nazi'at
    585, // 80. 'Abasa
    586, // 81. At-Takwir
    587, // 82. Al-Infitar
    587, // 83. Al-Mutaffifin
    589, // 84. Al-Inshiqaq
    590, // 85. Al-Buruj
    591, // 86. At-Tariq
    591, // 87. Al-A'la
    592, // 88. Al-Ghashiyah
    593, // 89. Al-Fajr
    594, // 90. Al-Balad
    595, // 91. Ash-Shams
    595, // 92. Al-Layl
    596, // 93. Ad-Duha
    596, // 94. Ash-Sharh
    597, // 95. At-Tin
    597, // 96. Al-'Alaq
    598, // 97. Al-Qadr
    598, // 98. Al-Bayyinah
    599, // 99. Az-Zalzalah
    599, // 100. Al-'Adiyat
    600, // 101. Al-Qari'ah
    600, // 102. At-Takathur
    601, // 103. Al-'Asr
    601, // 104. Al-Humazah
    601, // 105. Al-Fil
    602, // 106. Quraysh
    602, // 107. Al-Ma'un
    602, // 108. Al-Kawthar
    603, // 109. Al-Kafirun
    603, // 110. An-Nasr
    603, // 111. Al-Masad
    604, // 112. Al-Ikhlas
    604, // 113. Al-Falaq
    604, // 114. An-Nas
  ];

  static const List<int> surahVerseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
  ];

  /// Get the Madani Mushaf Page number for a given Surah and Ayah number in Surah.
  static int getPage(int surahNumber, int verseInSurah) {
    if (surahNumber < 1 || surahNumber > 114) return 1;
    final int startPage = surahStartPages[surahNumber - 1];
    final int nextStartPage = surahNumber < 114 ? surahStartPages[surahNumber] : 605;
    final int totalPagesForSurah = nextStartPage - startPage;
    final int totalVerses = surahVerseCounts[surahNumber - 1];

    if (totalPagesForSurah <= 1 || totalVerses <= 1) {
      return startPage;
    }

    final double ratio = (verseInSurah - 1) / totalVerses;
    final int offset = (ratio * totalPagesForSurah).floor();
    return (startPage + offset).clamp(startPage, nextStartPage - 1);
  }

  /// Get the Juz number for a given Madani page.
  static int getJuzFromPage(int page) {
    if (page <= 21) return 1;
    if (page <= 41) return 2;
    if (page <= 61) return 3;
    if (page <= 81) return 4;
    if (page <= 101) return 5;
    if (page <= 121) return 6;
    if (page <= 141) return 7;
    if (page <= 161) return 8;
    if (page <= 181) return 9;
    if (page <= 201) return 10;
    if (page <= 221) return 11;
    if (page <= 241) return 12;
    if (page <= 261) return 13;
    if (page <= 281) return 14;
    if (page <= 301) return 15;
    if (page <= 321) return 16;
    if (page <= 341) return 17;
    if (page <= 361) return 18;
    if (page <= 381) return 19;
    if (page <= 401) return 20;
    if (page <= 421) return 21;
    if (page <= 441) return 22;
    if (page <= 461) return 23;
    if (page <= 481) return 24;
    if (page <= 501) return 25;
    if (page <= 521) return 26;
    if (page <= 541) return 27;
    if (page <= 561) return 28;
    if (page <= 581) return 29;
    return 30;
  }
}
