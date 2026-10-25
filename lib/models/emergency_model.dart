class LocalizedContent {
  final String en;
  final String kn;
  final String ta;
  final String te;
  final String hi;
  final String ml;

  const LocalizedContent({
    required this.en,
    required this.kn,
    required this.ta,
    required this.te,
    required this.hi,
    required this.ml,
  });

  String get(String lang) {
    switch (lang) {
      case 'kn': return kn;
      case 'ta': return ta;
      case 'te': return te;
      case 'hi': return hi;
      case 'ml': return ml;
      default: return en;
    }
  }

  factory LocalizedContent.fromJson(Map<String, dynamic> json) {
    return LocalizedContent(
      en: json['en'] ?? '',
      kn: json['kn'] ?? '',
      ta: json['ta'] ?? '',
      te: json['te'] ?? '',
      hi: json['hi'] ?? '',
      ml: json['ml'] ?? '',
    );
  }
}

class EmergencyStep {
  final LocalizedContent title;
  final LocalizedContent quickTip;
  final LocalizedContent detailed;
  final LocalizedContent audioPrompt;
  final String visualAsset;
  final bool hasMetronome;
  final int stepDurationSeconds; // Auto-advancement countdown

  const EmergencyStep({
    required this.title,
    required this.quickTip,
    required this.detailed,
    required this.audioPrompt,
    required this.visualAsset,
    this.hasMetronome = false,
    this.stepDurationSeconds = 12,
  });
}