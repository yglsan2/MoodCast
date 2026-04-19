import 'dart:math' show pi, sin;

/// Signe du zodiaque avec dates (mois début, jour début, mois fin, jour fin).
class ZodiacSign {
  const ZodiacSign({
    required this.name,
    required this.symbol,
    required this.element,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });

  final String name;
  final String symbol;
  final String element;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
}

/// Décan européen (1/3 du signe) avec planète sous-régente et traits.
class EuropeanDecan {
  const EuropeanDecan({
    required this.sign,
    required this.decanNumber,
    required this.ruler,
    required this.trait,
  });
  final ZodiacSign sign;
  final int decanNumber; // 1, 2 ou 3
  final String ruler;   // planète sous-régente
  final String trait;   // courte description du décan
}

/// Signe du zodiaque chinois (année de naissance).
class ChineseSign {
  const ChineseSign({
    required this.animal,
    required this.element,
    required this.chineseYear,
  });
  final String animal;
  final String element;
  final int chineseYear;
}

class HoroscopeService {
  HoroscopeService._();

  static const List<ZodiacSign> signs = [
    ZodiacSign(name: 'Bélier', symbol: '♈', element: 'Feu', startMonth: 3, startDay: 21, endMonth: 4, endDay: 19),
    ZodiacSign(name: 'Taureau', symbol: '♉', element: 'Terre', startMonth: 4, startDay: 20, endMonth: 5, endDay: 20),
    ZodiacSign(name: 'Gémeaux', symbol: '♊', element: 'Air', startMonth: 5, startDay: 21, endMonth: 6, endDay: 20),
    ZodiacSign(name: 'Cancer', symbol: '♋', element: 'Eau', startMonth: 6, startDay: 21, endMonth: 7, endDay: 22),
    ZodiacSign(name: 'Lion', symbol: '♌', element: 'Feu', startMonth: 7, startDay: 23, endMonth: 8, endDay: 22),
    ZodiacSign(name: 'Vierge', symbol: '♍', element: 'Terre', startMonth: 8, startDay: 23, endMonth: 9, endDay: 22),
    ZodiacSign(name: 'Balance', symbol: '♎', element: 'Air', startMonth: 9, startDay: 23, endMonth: 10, endDay: 22),
    ZodiacSign(name: 'Scorpion', symbol: '♏', element: 'Eau', startMonth: 10, startDay: 23, endMonth: 11, endDay: 21),
    ZodiacSign(name: 'Sagittaire', symbol: '♐', element: 'Feu', startMonth: 11, startDay: 22, endMonth: 12, endDay: 21),
    ZodiacSign(name: 'Capricorne', symbol: '♑', element: 'Terre', startMonth: 12, startDay: 22, endMonth: 1, endDay: 19),
    ZodiacSign(name: 'Verseau', symbol: '♒', element: 'Air', startMonth: 1, startDay: 20, endMonth: 2, endDay: 18),
    ZodiacSign(name: 'Poissons', symbol: '♓', element: 'Eau', startMonth: 2, startDay: 19, endMonth: 3, endDay: 20),
  ];

  /// Retourne le signe pour une date de naissance.
  static ZodiacSign getSignForDate(DateTime date) {
    final month = date.month;
    final day = date.day;
    for (final sign in signs) {
      if (sign.startMonth == 12 && sign.endMonth == 1) {
        if ((month == 12 && day >= sign.startDay) || (month == 1 && day <= sign.endDay)) return sign;
      } else if (sign.startMonth == month && day >= sign.startDay) {
        return sign;
      } else if (sign.endMonth == month && day <= sign.endDay) {
        return sign;
      }
    }
    return signs[0];
  }

  /// Jour dans le signe (1 à ~30) pour le calcul du décan.
  static int _dayInSign(DateTime date, ZodiacSign sign) {
    final start = (sign.startMonth == 12 && date.month == 1)
        ? DateTime(date.year - 1, sign.startMonth, sign.startDay)
        : DateTime(date.year, sign.startMonth, sign.startDay);
    return date.difference(start).inDays + 1;
  }

  /// Décans : pour chaque signe, [décan 1, décan 2, décan 3] avec (ruler, trait).
  static const Map<String, List<({String ruler, String trait})>> _decansData = {
    'Bélier': [
      (ruler: 'Mars', trait: 'Pionnier, courageux, direct. Leadership naturel.'),
      (ruler: 'Soleil', trait: 'Créatif, rayonnant. Affirmation de soi.'),
      (ruler: 'Jupiter', trait: 'Optimiste, expansif. Ouverture et générosité.'),
    ],
    'Taureau': [
      (ruler: 'Vénus', trait: 'Sensuel, stable. Plaisirs et sécurité.'),
      (ruler: 'Mercure', trait: 'Pratique, communicant. Réalisation concrète.'),
      (ruler: 'Saturne', trait: 'Endurant, structuré. Patience et persévérance.'),
    ],
    'Gémeaux': [
      (ruler: 'Mercure', trait: 'Vif, curieux. Communication et idées.'),
      (ruler: 'Vénus', trait: 'Charme, harmonie. Relations et art.'),
      (ruler: 'Uranus', trait: 'Original, inventif. Liberté et surprise.'),
    ],
    'Cancer': [
      (ruler: 'Lune', trait: 'Émotionnel, protecteur. Foyer et intuition.'),
      (ruler: 'Pluton', trait: 'Profond, transformateur. Enjeux cachés.'),
      (ruler: 'Neptune', trait: 'Rêveur, empathique. Imagination et compassion.'),
    ],
    'Lion': [
      (ruler: 'Soleil', trait: 'Généreux, fier. Créativité et cœur.'),
      (ruler: 'Jupiter', trait: 'Magnanime, confiant. Expansion et joie.'),
      (ruler: 'Mars', trait: 'Combattif, passionné. Audace et volonté.'),
    ],
    'Vierge': [
      (ruler: 'Mercure', trait: 'Analytique, précis. Service et détail.'),
      (ruler: 'Saturne', trait: 'Discipliné, responsable. Travail et santé.'),
      (ruler: 'Vénus', trait: 'Raffiné, dévoué. Harmonie et soin.'),
    ],
    'Balance': [
      (ruler: 'Vénus', trait: 'Diplomate, esthète. Paix et partenariat.'),
      (ruler: 'Uranus', trait: 'Équilibré mais novateur. Justice et originalité.'),
      (ruler: 'Mercure', trait: 'Sociable, juste. Dialogue et équité.'),
    ],
    'Scorpion': [
      (ruler: 'Pluton', trait: 'Intense, transformateur. Pouvoir et vérité.'),
      (ruler: 'Neptune', trait: 'Mystérieux, intuitif. Secrets et régénération.'),
      (ruler: 'Lune', trait: 'Émotionnel, psychique. Profondeur et lien.'),
    ],
    'Sagittaire': [
      (ruler: 'Jupiter', trait: 'Philosophique, voyageur. Sagesse et optimisme.'),
      (ruler: 'Mars', trait: 'Aventurier, franc. Élan et honnêteté.'),
      (ruler: 'Soleil', trait: 'Généreux, rayonnant. Vision et partage.'),
    ],
    'Capricorne': [
      (ruler: 'Saturne', trait: 'Ambitieux, sérieux. Structure et autorité.'),
      (ruler: 'Vénus', trait: 'Persévérant mais raffiné. Réussite et goût.'),
      (ruler: 'Mercure', trait: 'Stratège, méthodique. Organisation et ambition.'),
    ],
    'Verseau': [
      (ruler: 'Uranus', trait: 'Inventif, humanitaire. Liberté et amitié.'),
      (ruler: 'Mercure', trait: 'Intellectuel, original. Idées et collectif.'),
      (ruler: 'Vénus', trait: 'Indépendant mais attaché. Innovation et lien.'),
    ],
    'Poissons': [
      (ruler: 'Neptune', trait: 'Intuitif, artiste. Rêve et spiritualité.'),
      (ruler: 'Lune', trait: 'Sensible, empathique. Émotions et imagination.'),
      (ruler: 'Pluton', trait: 'Mystique, transformateur. Transcendance et guérison.'),
    ],
  };

  /// Retourne le décan européen pour une date de naissance.
  static EuropeanDecan getDecanForDate(DateTime date) {
    final sign = getSignForDate(date);
    final dayInSign = _dayInSign(date, sign);
    final decanIndex = ((dayInSign - 1) ~/ 10).clamp(0, 2);
    final decanNumber = decanIndex + 1;
    final list = _decansData[sign.name]!;
    final data = list[decanIndex];
    return EuropeanDecan(
      sign: sign,
      decanNumber: decanNumber,
      ruler: data.ruler,
      trait: data.trait,
    );
  }

  // ——— Astrologie chinoise ———

  /// Dates du Nouvel An chinois (premier jour de l'année lunaire), 1900–2050.
  static final Map<int, DateTime> _cnyDates = {
    1900: DateTime(1900, 1, 31),
    1901: DateTime(1901, 2, 19),
    1902: DateTime(1902, 2, 8),
    1903: DateTime(1903, 1, 29),
    1904: DateTime(1904, 2, 16),
    1905: DateTime(1905, 2, 4),
    1906: DateTime(1906, 1, 25),
    1907: DateTime(1907, 2, 13),
    1908: DateTime(1908, 2, 2),
    1909: DateTime(1909, 1, 22),
    1910: DateTime(1910, 2, 10),
    1911: DateTime(1911, 1, 30),
    1912: DateTime(1912, 2, 18),
    1913: DateTime(1913, 2, 6),
    1914: DateTime(1914, 1, 26),
    1915: DateTime(1915, 2, 14),
    1916: DateTime(1916, 2, 4),
    1917: DateTime(1917, 1, 23),
    1918: DateTime(1918, 2, 11),
    1919: DateTime(1919, 2, 1),
    1920: DateTime(1920, 2, 20),
    1921: DateTime(1921, 2, 8),
    1922: DateTime(1922, 1, 28),
    1923: DateTime(1923, 2, 16),
    1924: DateTime(1924, 2, 5),
    1925: DateTime(1925, 1, 24),
    1926: DateTime(1926, 2, 13),
    1927: DateTime(1927, 2, 2),
    1928: DateTime(1928, 1, 23),
    1929: DateTime(1929, 2, 10),
    1930: DateTime(1930, 1, 30),
    1931: DateTime(1931, 2, 17),
    1932: DateTime(1932, 2, 6),
    1933: DateTime(1933, 1, 26),
    1934: DateTime(1934, 2, 14),
    1935: DateTime(1935, 2, 4),
    1936: DateTime(1936, 1, 24),
    1937: DateTime(1937, 2, 11),
    1938: DateTime(1938, 1, 31),
    1939: DateTime(1939, 2, 19),
    1940: DateTime(1940, 2, 8),
    1941: DateTime(1941, 1, 27),
    1942: DateTime(1942, 2, 15),
    1943: DateTime(1943, 2, 5),
    1944: DateTime(1944, 1, 25),
    1945: DateTime(1945, 2, 13),
    1946: DateTime(1946, 2, 2),
    1947: DateTime(1947, 1, 22),
    1948: DateTime(1948, 2, 10),
    1949: DateTime(1949, 1, 29),
    1950: DateTime(1950, 2, 17),
    1951: DateTime(1951, 2, 6),
    1952: DateTime(1952, 1, 27),
    1953: DateTime(1953, 2, 14),
    1954: DateTime(1954, 2, 3),
    1955: DateTime(1955, 1, 24),
    1956: DateTime(1956, 2, 12),
    1957: DateTime(1957, 1, 31),
    1958: DateTime(1958, 2, 18),
    1959: DateTime(1959, 2, 8),
    1960: DateTime(1960, 1, 28),
    1961: DateTime(1961, 2, 15),
    1962: DateTime(1962, 2, 5),
    1963: DateTime(1963, 1, 25),
    1964: DateTime(1964, 2, 13),
    1965: DateTime(1965, 2, 2),
    1966: DateTime(1966, 1, 21),
    1967: DateTime(1967, 2, 9),
    1968: DateTime(1968, 1, 30),
    1969: DateTime(1969, 2, 17),
    1970: DateTime(1970, 2, 6),
    1971: DateTime(1971, 1, 27),
    1972: DateTime(1972, 2, 15),
    1973: DateTime(1973, 2, 3),
    1974: DateTime(1974, 1, 23),
    1975: DateTime(1975, 2, 11),
    1976: DateTime(1976, 1, 31),
    1977: DateTime(1977, 2, 18),
    1978: DateTime(1978, 2, 7),
    1979: DateTime(1979, 1, 28),
    1980: DateTime(1980, 2, 16),
    1981: DateTime(1981, 2, 5),
    1982: DateTime(1982, 1, 25),
    1983: DateTime(1983, 2, 13),
    1984: DateTime(1984, 2, 2),
    1985: DateTime(1985, 2, 20),
    1986: DateTime(1986, 2, 9),
    1987: DateTime(1987, 1, 29),
    1988: DateTime(1988, 2, 17),
    1989: DateTime(1989, 2, 6),
    1990: DateTime(1990, 1, 27),
    1991: DateTime(1991, 2, 15),
    1992: DateTime(1992, 2, 4),
    1993: DateTime(1993, 1, 23),
    1994: DateTime(1994, 2, 10),
    1995: DateTime(1995, 1, 31),
    1996: DateTime(1996, 2, 19),
    1997: DateTime(1997, 2, 7),
    1998: DateTime(1998, 1, 28),
    1999: DateTime(1999, 2, 16),
    2000: DateTime(2000, 2, 5),
    2001: DateTime(2001, 1, 24),
    2002: DateTime(2002, 2, 12),
    2003: DateTime(2003, 2, 1),
    2004: DateTime(2004, 1, 22),
    2005: DateTime(2005, 2, 9),
    2006: DateTime(2006, 1, 29),
    2007: DateTime(2007, 2, 18),
    2008: DateTime(2008, 2, 7),
    2009: DateTime(2009, 1, 26),
    2010: DateTime(2010, 2, 14),
    2011: DateTime(2011, 2, 3),
    2012: DateTime(2012, 1, 23),
    2013: DateTime(2013, 2, 10),
    2014: DateTime(2014, 1, 31),
    2015: DateTime(2015, 2, 19),
    2016: DateTime(2016, 2, 8),
    2017: DateTime(2017, 1, 28),
    2018: DateTime(2018, 2, 16),
    2019: DateTime(2019, 2, 5),
    2020: DateTime(2020, 1, 25),
    2021: DateTime(2021, 2, 12),
    2022: DateTime(2022, 2, 1),
    2023: DateTime(2023, 1, 22),
    2024: DateTime(2024, 2, 10),
    2025: DateTime(2025, 1, 29),
    2026: DateTime(2026, 2, 17),
    2027: DateTime(2027, 2, 6),
    2028: DateTime(2028, 1, 26),
    2029: DateTime(2029, 2, 13),
    2030: DateTime(2030, 2, 3),
    2031: DateTime(2031, 1, 23),
    2032: DateTime(2032, 2, 11),
    2033: DateTime(2033, 1, 31),
    2034: DateTime(2034, 2, 19),
    2035: DateTime(2035, 2, 8),
    2036: DateTime(2036, 1, 28),
    2037: DateTime(2037, 2, 15),
    2038: DateTime(2038, 2, 4),
    2039: DateTime(2039, 1, 24),
    2040: DateTime(2040, 2, 12),
    2041: DateTime(2041, 2, 1),
    2042: DateTime(2042, 1, 22),
    2043: DateTime(2043, 2, 10),
    2044: DateTime(2044, 1, 30),
    2045: DateTime(2045, 2, 17),
    2046: DateTime(2046, 2, 6),
    2047: DateTime(2047, 1, 26),
    2048: DateTime(2048, 2, 14),
    2049: DateTime(2049, 2, 2),
    2050: DateTime(2050, 1, 23),
  };

  static const List<String> _chineseAnimals = [
    'Rat', 'Bœuf', 'Tigre', 'Lapin', 'Dragon', 'Serpent',
    'Cheval', 'Chèvre', 'Singe', 'Coq', 'Chien', 'Cochon',
  ];
  static const List<String> _chineseElements = [
    'Métal', 'Métal', 'Eau', 'Eau', 'Bois', 'Bois', 'Feu', 'Feu', 'Terre', 'Terre',
  ];

  /// Année chinoise pour une date (changement au Nouvel An chinois).
  static int _chineseYearForDate(DateTime date) {
    final y = date.year;
    if (y < 1900 || y > 2050) return y;
    final cny = _cnyDates[y]!;
    return date.isBefore(DateTime(cny.year, cny.month, cny.day)) ? y - 1 : y;
  }

  /// Signe chinois (animal + élément) pour une date de naissance.
  static ChineseSign getChineseZodiacForDate(DateTime date) {
    final cy = _chineseYearForDate(date);
    final animalIndex = (cy - 1900) % 12;
    final elementIndex = (cy - 1900) % 10;
    return ChineseSign(
      animal: _chineseAnimals[animalIndex],
      element: _chineseElements[elementIndex],
      chineseYear: cy,
    );
  }

  /// Pour une date donnée, retourne l'animal et l'élément de l'année chinoise en cours (pour la prédiction).
  static ({String animal, String element}) _currentYearChinese(DateTime date) {
    final cy = _chineseYearForDate(date);
    final ai = (cy - 1900) % 12;
    final ei = (cy - 1900) % 10;
    return (animal: _chineseAnimals[ai], element: _chineseElements[ei]);
  }

  /// Trait associé à chaque élément (pour personnaliser les prédictions).
  static const Map<String, String> _chineseElementTrait = {
    'Bois': 'croissance et adaptabilité',
    'Feu': 'passion et dynamisme',
    'Terre': 'stabilité et persévérance',
    'Métal': 'précision et clarté',
    'Eau': 'intuition et fluidité',
  };

  static int _elementIndex(String element) => const {'Métal': 0, 'Eau': 1, 'Bois': 2, 'Feu': 3, 'Terre': 4}[element] ?? 0;

  /// Seed combiné pour prédiction chinoise (animal, élément, année courante, jour/semaine/année).
  static int _chineseDailySeed(ChineseSign chinese, DateTime date) {
    final animalIndex = _chineseAnimals.indexOf(chinese.animal);
    final elemIndex = _elementIndex(chinese.element);
    final yearSign = _currentYearChinese(date);
    final currentAnimalIndex = _chineseAnimals.indexOf(yearSign.animal);
    final currentElemIndex = _elementIndex(yearSign.element);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return (animalIndex * 31 + elemIndex * 7 + currentAnimalIndex * 19 + currentElemIndex * 11 + dayOfYear + date.year).abs();
  }

  /// Horoscope du jour (chinois). Algorithme : seed combiné (votre signe, élément, année en cours, jour).
  static String dailyHoroscopeChinese(ChineseSign chinese, DateTime date) {
    final seed = _chineseDailySeed(chinese, date);
    final templates = _chineseDailyTemplates[chinese.animal] ?? _defaultChineseDaily(chinese);
    final yearSign = _currentYearChinese(date);
    final elementTrait = _chineseElementTrait[chinese.element] ?? chinese.element.toLowerCase();
    var text = templates[seed % templates.length]
        .replaceAll('{{element}}', chinese.element)
        .replaceAll('{{elementTrait}}', elementTrait);
    text += '\n\nEn cette année du ${yearSign.animal} (${yearSign.element}), l\'énergie du jour s\'accorde à votre nature ${chinese.animal}.';
    return text;
  }

  static List<String> _defaultChineseDaily(ChineseSign s) => [
        'Votre nature ${s.animal} (${s.element}) influence le jour. Restez à l\'écoute des opportunités.',
      ];

  static const Map<String, List<String>> _chineseDailyTemplates = {
    'Rat': [
      "L'ingéniosité du Rat est de mise. Une opportunité discrète peut se présenter ; soyez attentif sans forcer.",
      "Votre sens du détail et de la stratégie vous sert. Évitez les dépenses impulsives.",
    ],
    'Bœuf': [
      "La persévérance du Bœuf paie. Travaillez avec régularité ; les résultats viendront.",
      "Stabilité et loyauté : vos qualités sont reconnues. Prenez soin de votre santé.",
    ],
    'Tigre': [
      "Le courage du Tigre vous habite. Osez une décision ou une prise de parole importante.",
      "Énergie et leadership sont au rendez-vous. Attention à ne pas brusquer l'entourage.",
    ],
    'Lapin': [
      "La diplomatie du Lapin est utile. Privilégiez l'harmonie et les compromis constructifs.",
      "Un moment propice pour la créativité ou les échanges affectifs. Restez à l'écoute.",
    ],
    'Dragon': [
      "L'ambition du Dragon est stimulée. Un projet peut prendre de l'ampleur ; gardez la vision.",
      "Chance et audace : la journée favorise les initiatives. Partagez sans dominer.",
    ],
    'Serpent': [
      "La sagesse du Serpent guide. Réfléchissez avant d'agir ; votre intuition est fiable.",
      "Transformation et discrétion. Une situation peut évoluer en profondeur.",
    ],
    'Cheval': [
      "La liberté du Cheval vous appelle. Mouvement, voyage ou nouveau défi sont favorisés.",
      "Énergie et indépendance : avancez sans vous disperser. Écoutez vos proches.",
    ],
    'Chèvre': [
      "La douceur de la Chèvre adoucit le jour. Art, nature et relations apaisantes sont indiqués.",
      "Évitez les conflits ; privilégiez la coopération. Votre sensibilité est un atout.",
    ],
    'Singe': [
      "L'esprit vif du Singe est en forme. Idées, humour et adaptabilité vous servent.",
      "Une solution inattendue peut apparaître. Restez curieux sans vous éparpiller.",
    ],
    'Coq': [
      "La fierté du Coq est de mise. Montrez votre travail ou votre personnalité avec assurance.",
      "Organisation et clarté : un bon jour pour structurer et communiquer.",
    ],
    'Chien': [
      "La loyauté du Chien brille. Fidélité et honnêteté renforcent vos liens.",
      "Protégez votre énergie ; évitez les disputes inutiles. La justice est de votre côté.",
    ],
    'Cochon': [
      "La générosité du Cochon est appréciée. Partage et convivialité sont favorisés.",
      "Abondance et bienveillance : prenez soin de vous et des vôtres.",
    ],
  };

  static int _chineseWeeklySeed(ChineseSign chinese, DateTime startOfWeek) {
    final animalIndex = _chineseAnimals.indexOf(chinese.animal);
    final elemIndex = _elementIndex(chinese.element);
    final yearSign = _currentYearChinese(startOfWeek);
    final currentAnimalIndex = _chineseAnimals.indexOf(yearSign.animal);
    final weekNum = startOfWeek.difference(DateTime(startOfWeek.year, 1, 1)).inDays ~/ 7;
    return (animalIndex * 41 + elemIndex * 13 + currentAnimalIndex * 23 + weekNum + startOfWeek.year).abs();
  }

  /// Horoscope de la semaine (chinois). Algorithme : seed combiné + année chinoise en cours.
  static String weeklyHoroscopeChinese(ChineseSign chinese, DateTime startOfWeek) {
    final seed = _chineseWeeklySeed(chinese, startOfWeek);
    final templates = _chineseWeeklyTemplates[chinese.animal] ?? _defaultChineseWeekly(chinese);
    final yearSign = _currentYearChinese(startOfWeek);
    final elementTrait = _chineseElementTrait[chinese.element] ?? chinese.element.toLowerCase();
    var text = templates[seed % templates.length]
        .replaceAll('{{element}}', chinese.element)
        .replaceAll('{{elementTrait}}', elementTrait);
    text += '\n\nL\'année du ${yearSign.animal} (${yearSign.element}) favorise cette semaine les projets en phase avec votre signe.';
    return text;
  }

  static List<String> _defaultChineseWeekly(ChineseSign s) => [
        'Cette semaine, votre signe ${s.animal} (${s.element}) vous encourage à rester fidèle à vos valeurs.',
      ];

  static const Map<String, List<String>> _chineseWeeklyTemplates = {
    'Rat': ["Semaine propice aux affaires et à la stratégie. Évitez les risques inutiles.", "Une opportunité peut se préciser en milieu de semaine. Soyez patient."],
    'Bœuf': ["Travail et persévérance portent leurs fruits. Consolidez vos bases.", "Stabilité affective ou professionnelle. Prenez du repos en fin de semaine."],
    'Tigre': ["Dynamisme et initiatives. Un défi peut vous motiver ; gardez le calme.", "Leadership reconnu. Évitez les conflits en privilégiant le dialogue."],
    'Lapin': ["Harmonie et créativité. Les relations sont favorisées.", "Diplomatie et douceur. Un accord ou une réconciliation est possible."],
    'Dragon': ["Ambition et chance. Lancez un projet ou une idée importante.", "Visibilité et soutien. Partagez sans imposer."],
    'Serpent': ["Réflexion et intuition. Une décision importante peut mûrir.", "Transformation en douceur. Protégez votre énergie."],
    'Cheval': ["Mouvement et liberté. Voyage ou changement sont possibles.", "Énergie haute ; évitez la dispersion. Écoutez vos proches."],
    'Chèvre': ["Art et sensibilité. Prenez soin de vous et des vôtres.", "Coopération et paix. Évitez les confrontations."],
    'Singe': ["Ingéniosité et adaptabilité. Une solution créative peut apparaître.", "Communication et humour. Restez concentré sur l'essentiel."],
    'Coq': ["Organisation et fierté. Montrez vos compétences.", "Clarté et structure. Un projet peut aboutir."],
    'Chien': ["Loyauté et justice. Vos liens se renforcent.", "Protection et honnêteté. Évitez les conflits inutiles."],
    'Cochon': ["Générosité et convivialité. Partage et bien-être sont au programme.", "Abondance possible. Prenez soin de votre santé."],
  };

  static int _chineseYearlySeed(ChineseSign chinese, int year) {
    final animalIndex = _chineseAnimals.indexOf(chinese.animal);
    final elemIndex = _elementIndex(chinese.element);
    final jan1 = DateTime(year, 6, 1);
    final yearSign = _currentYearChinese(jan1);
    final currentAnimalIndex = _chineseAnimals.indexOf(yearSign.animal);
    final currentElemIndex = _elementIndex(yearSign.element);
    return (animalIndex * 59 + elemIndex * 17 + currentAnimalIndex * 37 + currentElemIndex * 7 + year).abs();
  }

  /// Horoscope de l'année (chinois). Algorithme : seed combiné (votre signe, année chinoise courante).
  static String yearlyHoroscopeChinese(ChineseSign chinese, int year) {
    final seed = _chineseYearlySeed(chinese, year);
    final templates = _chineseYearlyTemplates[chinese.animal] ?? _defaultChineseYearly(chinese);
    final jan1 = DateTime(year, 6, 1);
    final yearSign = _currentYearChinese(jan1);
    final elementTrait = _chineseElementTrait[chinese.element] ?? chinese.element.toLowerCase();
    var text = templates[seed % templates.length]
        .replaceAll('{{element}}', chinese.element)
        .replaceAll('{{elementTrait}}', elementTrait)
        .replaceAll('{{year}}', year.toString());
    text += '\n\nEn année du ${yearSign.animal} (${yearSign.element}), votre élément ${chinese.element} vous soutient : $elementTrait.';
    return text;
  }

  static List<String> _defaultChineseYearly(ChineseSign s) => [
        'En année ${s.animal} (${s.element}), restez fidèle à vos valeurs. L\'année {{year}} vous réserve des surprises.',
      ];

  static const Map<String, List<String>> _chineseYearlyTemplates = {
    'Rat': ["L'année {{year}} favorise les projets et la stratégie. Opportunités à saisir avec discernement.", "Votre ingéniosité est un atout. Évitez les risques excessifs."],
    'Bœuf': ["{{year}} récompense le travail et la persévérance. Construisez sur des bases solides.", "Stabilité et santé : prenez soin de vous et de vos proches."],
    'Tigre': ["Courage et leadership en {{year}}. Lancez des initiatives ; gardez le calme dans les conflits.", "Une année dynamique. Évitez l'impulsivité."],
    'Lapin': ["Harmonie et créativité en {{year}}. Les relations et l'art sont favorisés.", "Diplomatie et paix. Une réconciliation ou un accord est possible."],
    'Dragon': ["Chance et ambition en {{year}}. Un projet peut prendre de l'ampleur.", "Visibilité et soutien. Partagez votre vision."],
    'Serpent': ["Sagesse et transformation en {{year}}. Réfléchissez avant d'agir.", "Votre intuition est fiable. Une évolution importante est possible."],
    'Cheval': ["Liberté et mouvement en {{year}}. Voyage ou changement sont indiqués.", "Énergie et indépendance. Écoutez vos proches pour éviter la dispersion."],
    'Chèvre': ["Douceur et coopération en {{year}}. Art, nature et relations apaisantes.", "Évitez les conflits ; privilégiez l'harmonie."],
    'Singe': ["Ingéniosité et adaptabilité en {{year}}. Solutions créatives et communication.", "Restez curieux sans vous éparpiller."],
    'Coq': ["Organisation et fierté en {{year}}. Montrez vos compétences et structurez.", "Un projet peut aboutir. Clarté et assurance."],
    'Chien': ["Loyauté et justice en {{year}}. Vos liens se renforcent.", "Honnêteté et protection. Évitez les disputes inutiles."],
    'Cochon': ["Générosité et abondance en {{year}}. Partage et bien-être.", "Prenez soin de vous et des vôtres. Convivialité au programme."],
  };

  /// Jour julien (simplifié) pour calculs planétaires.
  static double julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day + date.hour / 24.0 + date.minute / 1440.0;
    if (m <= 2) {
      return (365.25 * (y - 1)).floorToDouble() + (30.6001 * (m + 13)).floorToDouble() + d + 1720994.5;
    }
    return (365.25 * y).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + 1720994.5;
  }

  /// Position approximative du Soleil en degrés (0-360).
  static double sunLongitude(DateTime date) {
    final jd = julianDay(date);
    final n = jd - 2451545.0;
    var l = 280.466 + 0.9856474 * n;
    final g = (357.528 + 0.9856003 * n) * pi / 180;
    l += 1.915 * sin(g) + 0.020 * sin(2 * g);
    return (l % 360 + 360) % 360;
  }

  /// Phase lunaire (0 = nouvelle, 0.5 = pleine, 1 = nouvelle).
  static double moonPhase(DateTime date) {
    final jd = julianDay(date);
    final n = (jd - 2451550.1) / 29.53058867;
    return (n - n.floorToDouble());
  }

  static String moonPhaseName(double phase) {
    if (phase < 0.125) return 'Nouvelle Lune';
    if (phase < 0.25) return 'Premier croissant';
    if (phase < 0.375) return 'Premier quartier';
    if (phase < 0.5) return 'Gibbeuse croissante';
    if (phase < 0.625) return 'Pleine Lune';
    if (phase < 0.75) return 'Gibbeuse décroissante';
    if (phase < 0.875) return 'Dernier quartier';
    return 'Dernier croissant';
  }

  /// Bloc « thème astral » pour le mini-podcast (signe, décan, chinois).
  static String getPodcastAstroBlock(DateTime birthDate) {
    final sign = getSignForDate(birthDate);
    final decan = getDecanForDate(birthDate);
    final chinese = getChineseZodiacForDate(birthDate);
    var block = 'Ton thème astral : ${sign.name} ${sign.symbol}, ${sign.element}.';
    block += ' Décan ${decan.decanNumber} sous ${decan.ruler} : ${decan.trait}';
    block += ' Côté chinois : ${chinese.animal} ${chinese.element}.';
    return block;
  }

  /// Bloc « transits du jour » pour le mini-podcast (phase lunaire).
  static String getPodcastTransitBlock(DateTime date) {
    final phase = moonPhase(date);
    final phaseName = moonPhaseName(phase);
    final theme = _moonPhaseTheme(phase);
    final sentence = _moonThemeSentences[theme] ?? 'Les énergies du jour vous accompagnent.';
    return 'Transits du jour : $phaseName. $sentence';
  }

  /// Quartier lunaire (0-3) pour varier les prédictions.
  static int _moonQuarter(double phase) {
    if (phase < 0.25) return 0;
    if (phase < 0.5) return 1;
    if (phase < 0.75) return 2;
    return 3;
  }

  /// Thème astrologique selon la phase lunaire (influence le ton de la prédiction).
  static String _moonPhaseTheme(double phase) {
    if (phase < 0.15) return 'nouvelle';      // Nouveaux départs, intentions
    if (phase < 0.35) return 'croissant';     // Croissance, construction
    if (phase < 0.45) return 'premier_quart'; // Action, engagement
    if (phase < 0.55) return 'pleine';        // Culmination, clarté
    if (phase < 0.65) return 'gibbeuse_dec';  // Récolte, partage
    if (phase < 0.85) return 'dernier_quart'; // Révision, lâcher-prise
    return 'decroissant';                      // Repos, préparation
  }

  /// Index du signe zodiacal où se trouve le Soleil (0=Bélier..11=Poissons).
  static int _solarSignIndex(DateTime date) {
    final lon = sunLongitude(date);
    return (lon / 30).floor() % 12;
  }

  /// Seed combiné pour prédiction européenne du jour (déterministe, varié).
  static int _europeanDailySeed(ZodiacSign sign, DateTime date, EuropeanDecan? decan) {
    final signIndex = signs.indexOf(sign);
    final sunInSign = _solarSignIndex(date);
    final phase = moonPhase(date);
    final moonQ = _moonQuarter(phase);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final decanPart = (decan?.decanNumber ?? 1) * 17;
    return (signIndex * 31 + sunInSign * 7 + moonQ * 11 + dayOfYear + decanPart + date.year * 365).abs();
  }

  static const Map<String, String> _moonThemeSentences = {
    'nouvelle': 'La Nouvelle Lune favorise les nouveaux départs : c\'est le moment d\'oser.',
    'croissant': 'La Lune croissante soutient vos projets : construisez pas à pas.',
    'premier_quart': 'Le premier quartier lunaire encourage l\'action : engagez-vous.',
    'pleine': 'La Pleine Lune apporte clarté et culmination : les choses se révèlent.',
    'gibbeuse_dec': 'La Lune gibbeuse décroissante invite à récolter et partager.',
    'dernier_quart': 'Le dernier quartier invite à réviser et à lâcher ce qui ne sert plus.',
    'decroissant': 'La Lune décroissante favorise le repos et la préparation au cycle suivant.',
  };

  /// Horoscope du jour pour un signe (optionnellement avec décan).
  /// Algorithme : seed combiné (signe, Soleil du jour, phase lunaire, décan) + thème lunaire.
  static String dailyHoroscope(ZodiacSign sign, DateTime date, {EuropeanDecan? decan}) {
    final phase = moonPhase(date);
    final phaseName = moonPhaseName(phase);
    final theme = _moonPhaseTheme(phase);
    final seed = _europeanDailySeed(sign, date, decan);
    final templates = _dailyTemplates[sign.name] ?? _defaultDaily(sign);
    var text = templates[seed % templates.length]
        .replaceAll('{{phase}}', phaseName)
        .replaceAll('{{element}}', sign.element);
    final themeSentence = _moonThemeSentences[theme];
    if (themeSentence != null) {
      text += '\n\n$themeSentence';
    }
    if (decan != null) {
      text = text.replaceAll('{{ruler}}', decan.ruler).replaceAll('{{trait}}', decan.trait);
      text += '\n\nVotre décan (${decan.decanNumber}ᵉ du ${sign.name}) est sous l\'influence de ${decan.ruler} : ${decan.trait}';
    }
    return text;
  }

  static List<String> _defaultDaily(ZodiacSign sign) => [
        'Votre nature ${sign.element} vous guide aujourd\'hui. Les énergies du jour sont favorables à l\'expression de votre authenticité.',
        'C\'est un bon jour pour avancer sur vos projets. La {{phase}} soutient vos efforts.',
      ];

  /// Thèmes pour l'horoscope du jour (amour, travail, santé, chance).
  static const List<String> dailyThemes = ['amour', 'travail', 'sante', 'chance'];

  static int _themeSeed(ZodiacSign sign, DateTime date, String theme, EuropeanDecan? decan) {
    final signIndex = signs.indexOf(sign);
    final themeHash = theme.hashCode.abs();
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final decanPart = (decan?.decanNumber ?? 1) * 7;
    return (signIndex * 19 + themeHash * 11 + dayOfYear + date.year * 31 + decanPart).abs();
  }

  /// Horoscope du jour par thème (amour, travail, sante, chance).
  static String dailyHoroscopeByTheme(ZodiacSign sign, DateTime date, String theme, {EuropeanDecan? decan}) {
    final seed = _themeSeed(sign, date, theme, decan);
    final templates = _dailyThemeTemplates[theme]!;
    var text = templates[seed % templates.length]
        .replaceAll('{{sign}}', sign.name)
        .replaceAll('{{element}}', sign.element);
    if (decan != null) {
      text += ' L\'influence de votre décan (${decan.ruler}) renforce cette tendance.';
    }
    return text;
  }

  static const Map<String, List<String>> _dailyThemeTemplates = {
    'amour': [
      'En amour, les énergies du jour favorisent les échanges sincères. Les {{sign}} peuvent oser exprimer leurs sentiments.',
      'Cœur et relations : une rencontre ou une conversation importante est possible. Les {{element}} savent séduire aujourd\'hui.',
      'La journée est propice aux rapprochements. Si vous êtes en couple, prenez un moment pour vous. Célibataire : ouvrez les yeux.',
      'Vénus sourit aux {{sign}}. Douceur et compréhension sont de mise. Évitez les sujets qui fâchent.',
      'Un geste d\'attention peut tout changer. Les {{sign}} ont du charme à revendre aujourd\'hui.',
      'Amour : la confiance et l\'écoute priment. Laissez parler le cœur sans précipitation.',
    ],
    'travail': [
      'Au travail, les {{sign}} sont en phase. Vos idées sont entendues ; osez les défendre.',
      'Productivité et clarté : c\'est un bon jour pour structurer vos dossiers ou prendre des décisions importantes.',
      'Les efforts passés portent leurs fruits. Une reconnaissance ou une opportunité peut se présenter.',
      'Évitez la dispersion. Les {{element}} réussissent mieux en se concentrant sur une priorité.',
      'Collaboration favorisée : travaillez en équipe plutôt qu\'en solo. Votre contribution sera appréciée.',
      'Travail : avancez sur les projets en cours. Les nouvelles initiatives peuvent attendre demain.',
    ],
    'sante': [
      'Santé et vitalité : les {{sign}} tirent profit d\'un rythme régulier. Pensez à vous hydrater et à bouger.',
      'Le corps réclame peut-être un peu de repos. Écoutez-vous ; une courte pause fait du bien.',
      'Équilibre physique et mental : une marche ou une activité douce vous ressourcera.',
      'Les {{element}} sont sensibles au stress aujourd\'hui. Respiration et calme sont vos alliés.',
      'Bien-être : c\'est le moment de reprendre une bonne habitude (sommeil, alimentation, sport).',
      'Prenez soin de vous sans culpabiliser. Votre énergie a besoin de douceur pour se régénérer.',
    ],
    'chance': [
      'La chance sourit aux {{sign}} aujourd\'hui. Restez attentif : une opportunité peut se cacher dans le quotidien.',
      'Les planètes favorisent les initiatives. Osez une demande ou un projet que vous repoussez depuis longtemps.',
      'Un hasard heureux est possible. Sortez, échangez ; la chance aime ceux qui bougent.',
      'Les {{element}} ont un bon potentiel chance aujourd\'hui. Évitez toutefois les paris risqués.',
      'Une bonne nouvelle ou une rencontre positive peut arriver. Gardez l\'esprit ouvert.',
      'Chance : soyez à l\'écoute des signes. Une porte peut s\'ouvrir si vous restez réceptif.',
    ],
  };

  static const Map<String, List<String>> _dailyTemplates = {
    'Bélier': [
      "L'énergie martienne vous pousse aujourd'hui. Prenez des initiatives ; votre courage est renforcé. Attention à ne pas brusquer l'entourage.",
      "Votre spontanéité est votre atout. Les défis sont des opportunités. Ne laissez personne freiner votre élan.",
      "Les planètes favorisent l'action directe. Idéal pour démarrer un nouveau projet. Restez focalisé.",
    ],
    'Taureau': [
      "La stabilité vous enveloppe. Savourez les plaisirs simples. Votre patience sera récompensée.",
      "Votre sens pratique est à son apogée. Les projets en cours portent leurs fruits. Investissez dans ce qui vous sécurise.",
      "Construisez sur des bases solides. Prenez soin de votre bien-être physique et émotionnel.",
    ],
    'Gémeaux': [
      "La communication est favorisée. Échanges, idées, contacts : tout circule. Profitez-en pour clarifier des situations.",
      "Votre curiosité est stimulée. Une rencontre ou une lecture peut vous ouvrir de nouvelles perspectives.",
      "Évitez la dispersion. Choisissez une ou deux priorités et tenez-vous-y.",
    ],
    'Cancer': [
      "Vos émotions sont en avant. Accordez-leur de l'attention sans vous laisser submerger. Le foyer et les proches comptent.",
      "La {{phase}} influence votre humeur. C'est un bon moment pour prendre soin de vous et des vôtres.",
      "Écoutez votre intuition. Elle vous guide vers ce dont vous avez besoin.",
    ],
    'Lion': [
      "Votre rayonnement est au rendez-vous. Montrez-vous, créez, prenez la place qui vous revient. Les autres vous regardent.",
      "La créativité et la confiance en soi sont renforcées. Lancez un projet qui vous tient à cœur.",
      "Attention à ne pas tout centrer sur vous. Un peu d'écoute renforce votre charisme.",
    ],
    'Vierge': [
      "L'organisation et le détail sont vos alliés. Triez, clarifiez, améliorez. Votre santé mérite aussi de l'attention.",
      "Un travail bien fait vous satisfait aujourd'hui. Évitez le perfectionnisme excessif.",
      "Service et efficacité : vous pouvez aider votre entourage tout en restant aligné.",
    ],
    'Balance': [
      "L'harmonie et les relations sont à l'honneur. Équilibrez donner et recevoir. Les compromis constructifs sont possibles.",
      "Beauté, art, dialogue : tout ce qui adoucit la vie est favorisé. Profitez-en.",
      "Évitez l'indécision en vous fixant une deadline pour vos choix.",
    ],
    'Scorpion': [
      "Les profondeurs vous appellent. Transformation, vérité, intensité : vous pouvez aller au fond des choses.",
      "Vos ressources (émotionnelles ou matérielles) sont en jeu. Gérez avec lucidité, sans dramatiser.",
      "La {{phase}} renforce votre intuition. Faites confiance à ce que vous ressentez.",
    ],
    'Sagittaire': [
      "L'horizon s'élargit. Voyage, philosophie, apprentissage : tout ce qui vous fait grandir est indiqué.",
      "Votre optimisme attire des opportunités. Partagez votre vision sans imposer.",
      "Un peu de discipline vous évite de vous éparpiller. Concentrez votre flamme.",
    ],
    'Capricorne': [
      "La structure et la persévérance paient. Avancez pas à pas vers vos objectifs. Votre autorité naturelle est reconnue.",
      "Le travail et la responsabilité sont au premier plan. Prenez le temps de récupérer aussi.",
      "Les bases que vous posez maintenant serviront longtemps. Soyez patient.",
    ],
    'Verseau': [
      "L'originalité et l'humanité sont en phase. Idées neuves, amis, collectif : vous êtes dans votre élément.",
      "Une cause ou un projet commun peut vous mobiliser. Restez libre tout en vous engageant.",
      "Évitez l'entêtement. L'innovation passe par l'écoute des autres aussi.",
    ],
    'Poissons': [
      "L'intuition et la compassion sont renforcées. Créativité, rêve, spiritualité : laissez-vous porter sans vous perdre.",
      "La {{phase}} accentue votre sensibilité. Protégez-vous des atmosphères trop lourdes.",
      "Un moment pour vous ressourcer en douceur. L'art et la nature vous font du bien.",
    ],
  };

  /// Seed combiné pour la semaine (Soleil, Lune, numéro de semaine, décan).
  static int _europeanWeeklySeed(ZodiacSign sign, DateTime startOfWeek, EuropeanDecan? decan) {
    final signIndex = signs.indexOf(sign);
    final sunInSign = _solarSignIndex(startOfWeek);
    final moonQ = _moonQuarter(moonPhase(startOfWeek));
    final weekNum = startOfWeek.difference(DateTime(startOfWeek.year, 1, 1)).inDays ~/ 7;
    final decanPart = (decan?.decanNumber ?? 1) * 13;
    return (signIndex * 47 + sunInSign * 19 + moonQ * 23 + weekNum + decanPart + startOfWeek.year * 53).abs();
  }

  /// Horoscope de la semaine (résumé). Optionnellement avec décan.
  static String weeklyHoroscope(ZodiacSign sign, DateTime startOfWeek, {EuropeanDecan? decan}) {
    final seed = _europeanWeeklySeed(sign, startOfWeek, decan);
    final templates = _weeklyTemplates[sign.name] ?? _defaultWeekly(sign);
    final phase = moonPhase(startOfWeek);
    final theme = _moonPhaseTheme(phase);
    var text = templates[seed % templates.length]
        .replaceAll('{{element}}', sign.element)
        .replaceAll('{{phase}}', moonPhaseName(phase));
    final themeSentence = _moonThemeSentences[theme];
    if (themeSentence != null) {
      text += '\n\n$themeSentence';
    }
    if (decan != null) {
      text += '\n\nDécan ${decan.decanNumber} (${decan.ruler}) : ${decan.trait}';
    }
    return text;
  }

  static List<String> _defaultWeekly(ZodiacSign sign) => [
        'Cette semaine, votre nature ${sign.element} sera sollicitée. Restez à l\'écoute de vos besoins et de vos intuitions.',
      ];

  static const Map<String, List<String>> _weeklyTemplates = {
    'Bélier': [
      "Semaine d'action et de leadership. Démarrez les projets qui vous tiennent à cœur. En milieu de semaine, attention aux conflits ; privilégiez le dialogue.",
      "Votre énergie est haute. Utilisez-la pour convaincre et avancer. Vers la fin de la semaine, un temps de repos vous fera du bien.",
    ],
    'Taureau': [
      "Stabilité et concret : cette semaine, consolidez vos acquis. Les finances et le confort méritent votre attention. Évitez les changements brusques.",
      "Patience et persévérance portent leurs fruits. Une opportunité matérielle ou affective peut se préciser en fin de semaine.",
    ],
    'Gémeaux': [
      "Communication et mobilité sont au programme. Réunions, déplacements, idées : tout s'enchaîne. Notez l'essentiel pour ne pas oublier.",
      "Les échanges vous nourrissent. Une nouvelle rencontre ou information peut ouvrir des portes. Restez curieux.",
    ],
    'Cancer': [
      "Émotions et foyer au centre. Prenez soin de vous et des vôtres. La {{phase}} peut amplifier les ressentis ; gardez un ancrage.",
      "Votre intuition est fiable. Suivez-la pour des décisions concernant la maison ou la famille. Évitez les prises de tête inutiles.",
    ],
    'Lion': [
      "Créativité et visibilité. Montrez ce que vous faites ; vous avez le soutien des autres. Un projet personnel peut prendre forme.",
      "Confiance et rayonnement. Profitez de cette dynamique pour avancer. En fin de semaine, partagez plutôt que dominer.",
    ],
    'Vierge': [
      "Organisation et santé. C'est le moment de mettre de l'ordre et de prendre de bonnes habitudes. Le travail bien fait est récompensé.",
      "Service et précision. Vous pouvez aider votre entourage tout en restant exigeant avec vous-même, sans excès.",
    ],
    'Balance': [
      "Relations et équilibre. Les partenariats et la vie à deux sont favorisés. Cherchez le juste milieu dans les désaccords.",
      "Beauté et harmonie. Un projet artistique ou une réconciliation est possible. Évitez l'indécision en vous fixant des objectifs clairs.",
    ],
    'Scorpion': [
      "Transformation et profondeur. Une situation peut évoluer en profondeur. Restez honnête avec vous-même et avec les autres.",
      "Ressources et intuition. Vous sentez ce qui doit changer. Agissez avec discernement plutôt qu'avec passion brute.",
    ],
    'Sagittaire': [
      "Horizons élargis. Voyage, études, philosophie : tout ce qui vous fait grandir est indiqué. Partagez vos idées.",
      "Optimisme et opportunités. Une proposition ou une rencontre peut vous ouvrir des portes. Gardez l'esprit ouvert.",
    ],
    'Capricorne': [
      "Travail et responsabilités. Vous avancez sur des objectifs à long terme. Votre sérieux est reconnu. Pensez aussi à vous reposer.",
      "Structure et autorité. C'est une bonne période pour prendre des décisions importantes. Basez-vous sur les faits.",
    ],
    'Verseau': [
      "Innovation et collectif. Les amis et les projets communs sont en vedette. Une idée originale peut voir le jour.",
      "Liberté et solidarité. Vous pouvez concilier besoin d'indépendance et engagement. Écoutez les autres sans vous perdre.",
    ],
    'Poissons': [
      "Intuition et créativité. L'art, le rêve et la compassion sont renforcés. Prenez du temps pour vous ressourcer.",
      "Sensibilité et spiritualité. Évitez les environnements toxiques. La nature et l'art vous font du bien cette semaine.",
    ],
  };

  /// Seed combiné pour l'année (signe, année, Soleil début d'année, décan).
  static int _europeanYearlySeed(ZodiacSign sign, int year, EuropeanDecan? decan) {
    final signIndex = signs.indexOf(sign);
    final jan1 = DateTime(year, 1, 15);
    final sunInSign = _solarSignIndex(jan1);
    final decanPart = (decan?.decanNumber ?? 1) * 101;
    return (signIndex * 97 + year * 31 + sunInSign * 17 + decanPart).abs();
  }

  /// Horoscope de l'année (résumé). Optionnellement avec décan.
  static String yearlyHoroscope(ZodiacSign sign, int year, {EuropeanDecan? decan}) {
    final seed = _europeanYearlySeed(sign, year, decan);
    final templates = _yearlyTemplates[sign.name] ?? _defaultYearly(sign);
    var text = templates[seed % templates.length].replaceAll('{{element}}', sign.element).replaceAll('{{year}}', year.toString());
    if (decan != null) {
      text += '\n\nVotre décan (${decan.ruler}) renforce : ${decan.trait}';
    }
    return text;
  }

  static List<String> _defaultYearly(ZodiacSign sign) => [
        'En ${sign.name}, l\'année {{year}} met votre nature ${sign.element} à l\'honneur. Restez fidèle à vos valeurs et à vos objectifs.',
      ];

  static const Map<String, List<String>> _yearlyTemplates = {
    'Bélier': [
      "L'année {{year}} vous pousse à prendre le leadership. Nouveaux départs, courage et initiatives sont favorisés. Gare à l'impulsivité : réfléchir avant d'agir vous évitera des retournements.",
      "Mars, votre planète, vous donne de l'élan. Profitez-en pour lancer des projets personnels ou professionnels. En fin d'année, consolidez plutôt que disperser.",
    ],
    'Taureau': [
      "{{year}} est une année de construction. Stabilité, finances et plaisirs concrets sont au programme. Les efforts passés portent leurs fruits. Évitez les changements trop radicaux.",
      "Votre persévérance est récompensée. Investissez dans ce qui dure : relations, biens, santé. La deuxième partie de l'année peut apporter une belle opportunité.",
    ],
    'Gémeaux': [
      "Communication et mobilité marquent {{year}}. Voyages, études, échanges : tout circule. Restez curieux tout en évitant la dispersion.",
      "Vos idées et votre réseau sont des atouts. Une collaboration ou un projet lié à la communication peut aboutir. Pensez à vous ancrer de temps en temps.",
    ],
    'Cancer': [
      "L'année {{year}} met l'accent sur le foyer, la famille et les émotions. Prenez soin de votre nid et de vos proches. Votre intuition est un guide fiable.",
      "Des changements dans l'habitat ou la vie familiale sont possibles. Accueillez les émotions sans vous laisser submerger. Créativité et bien-être sont favorisés.",
    ],
    'Lion': [
      "Créativité, confiance et visibilité sont au rendez-vous en {{year}}. Montrez ce que vous valez. Les projets artistiques ou personnels peuvent briller.",
      "Votre rayonnement attire des soutiens. Attention à ne pas trop centrer sur vous : partager renforce votre position. Une romance ou un enfant peut marquer l'année.",
    ],
    'Vierge': [
      "Santé, travail et organisation sont les maîtres-mots de {{year}}. Mettez de l'ordre, améliorez vos habitudes. Le dévouement est reconnu.",
      "Une évolution professionnelle ou un projet de service est possible. Évitez le perfectionnisme excessif. En fin d'année, pensez à vous ressourcer.",
    ],
    'Balance': [
      "Relations et équilibre sont au cœur de {{year}}. Vie de couple, partenariats, justice : cherchez l'harmonie. Les compromis constructifs paient.",
      "Beauté, art et diplomatie sont favorisés. Une rencontre ou une décision importante peut avoir lieu. Affirmez vos choix sans tergiverser trop longtemps.",
    ],
    'Scorpion': [
      "Transformation et intensité marquent {{year}}. Une page se tourne ; vous pouvez renaître dans un domaine. Ressources et vérité sont en jeu.",
      "Votre pouvoir de rebond est fort. Utilisez-le pour dépasser les crises et aller vers ce qui vous correspond vraiment. L'intuition est votre alliée.",
    ],
    'Sagittaire': [
      "L'année {{year}} élargit vos horizons. Voyage, philosophie, enseignement : tout ce qui vous fait grandir est indiqué. Partagez votre vision.",
      "Optimisme et opportunités sont au rendez-vous. Une expansion (géographique, intellectuelle ou spirituelle) est possible. Gardez les pieds sur terre pour concrétiser.",
    ],
    'Capricorne': [
      "Structure et ambition sont au programme en {{year}}. Vous construisez sur du long terme. Autorité et reconnaissance peuvent augmenter. Prenez soin de votre santé.",
      "Vos efforts sont visibles. Une promotion ou un projet important peut aboutir. En milieu d'année, accordez-vous du repos pour tenir la distance.",
    ],
    'Verseau': [
      "Innovation et humanité marquent {{year}}. Amis, projets collectifs, idées neuves : vous êtes dans votre élément. La liberté et la solidarité vont de pair.",
      "Une cause ou un groupe peut vous mobiliser. Restez vous-même tout en vous engageant. Une surprise positive est possible en cours d'année.",
    ],
    'Poissons': [
      "Intuition, créativité et spiritualité sont renforcées en {{year}}. Écoutez votre voix intérieure. L'art et le rêve vous nourrissent.",
      "Prenez soin de votre monde émotionnel. Évitez les environnements ou relations toxiques. Une forme de guérison ou d'inspiration peut survenir.",
    ],
  };

  /// Score de compatibilité émotionnelle / astro entre deux dates de naissance (0–100).
  /// Combine compatibilité éléments (européen) et affinités chinoises.
  static int compatibilityScore(DateTime date1, DateTime date2) {
    final sign1 = getSignForDate(date1);
    final sign2 = getSignForDate(date2);
    final ch1 = getChineseZodiacForDate(date1);
    final ch2 = getChineseZodiacForDate(date2);

    int euro = 50;
    const compatibleElements = [
      ['Feu', 'Air'],
      ['Air', 'Feu'],
      ['Terre', 'Eau'],
      ['Eau', 'Terre'],
    ];
    if (sign1.element == sign2.element) {
      euro = 85;
    } else if (compatibleElements.any((p) => p[0] == sign1.element && p[1] == sign2.element)) {
      euro = 78;
    } else {
      euro = 45;
    }

    final a1 = _chineseAnimals.indexOf(ch1.animal);
    final a2 = _chineseAnimals.indexOf(ch2.animal);
    final diff = (a1 - a2).abs() % 12;
    int chinese = 50;
    if (diff == 0) {
      chinese = 70;
    } else if (diff == 4 || diff == 8) {
      chinese = 82;
    } else if (diff == 6) {
      chinese = 38;
    }

    return ((euro + chinese) / 2).round().clamp(0, 100);
  }

  /// Message court de compatibilité pour l'écran AstroCompatibilité.
  static String compatibilityMessage(DateTime date1, DateTime date2) {
    final score = compatibilityScore(date1, date2);
    if (score >= 80) return 'Alchimie parfaite. Vos énergies se renforcent mutuellement.';
    if (score >= 65) return 'Belle harmonie. Vous vous comprenez et vous complétez bien.';
    if (score >= 50) return 'Complémentarité possible. Les différences peuvent enrichir le lien.';
    if (score >= 35) return 'Défis stimulants. La communication et l\'écoute feront la différence.';
    return 'Chemins différents. L\'acceptation mutuelle ouvre des portes insoupçonnées.';
  }
}
