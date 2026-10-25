enum EmergencyType {
  cpr,
  severeBleeding,
  choking,
  spinalCaution,
}

class LocalizedContent {
  final String en;
  final String kn;
  final String hi;
  final String ta;
  final String te;
  final String ml;

  LocalizedContent({
    required this.en,
    required this.kn,
    required this.hi,
    required this.ta,
    required this.te,
    required this.ml,
  });

  String get(String langCode) {
    switch (langCode) {
      case 'kn': return kn;
      case 'hi': return hi;
      case 'ta': return ta;
      case 'te': return te;
      case 'ml': return ml;
      default: return en;
    }
  }
}

class InstructionStep {
  final LocalizedContent title;
  final LocalizedContent quickTip;
  final LocalizedContent detailed;
  final LocalizedContent audioPrompt;
  final String visualAsset;

  InstructionStep({
    required this.title,
    required this.quickTip,
    required this.detailed,
    required this.audioPrompt,
    required this.visualAsset,
  });
}

class AssessmentQuestion {
  final String id;
  final LocalizedContent question;
  final String? yesNextId;
  final String? noNextId;
  final EmergencyType? yesProtocol;
  final EmergencyType? noProtocol;

  AssessmentQuestion({
    required this.id,
    required this.question,
    this.yesNextId,
    this.noNextId,
    this.yesProtocol,
    this.noProtocol,
  });
}