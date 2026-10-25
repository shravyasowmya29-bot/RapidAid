import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'guidance_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final String language;
  const AssessmentScreen({super.key, required this.language});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _questionIndex = 0;
  bool _isSceneSafe = true;
  bool _isVictimResponsive = true;
  bool _isVictimBreathing = true;
  bool _isChoking = false;
  bool _hasSevereBleeding = false;
  bool _isHelperPanicked = false;
  final bool _isHelperAlone = true;

  Future<void> _makeDirectCall(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  void _processAnswer(bool answer) {
    if (_questionIndex == 0) {
      // Q0: Scene Safety
      _isSceneSafe = answer;
      if (!_isSceneSafe) {
        _dispatchProtocol("SPINAL");
        return;
      }
      setState(() => _questionIndex = 1);
    } else if (_questionIndex == 1) {
      // Q1: Victim Responsiveness
      _isVictimResponsive = answer;
      if (!_isVictimResponsive) {
        setState(() => _questionIndex = 2); // Check breathing next
      } else {
        setState(() => _questionIndex = 3); // Check choking next
      }
    } else if (_questionIndex == 2) {
      // Q2: Normal Breathing (if unresponsive)
      _isVictimBreathing = answer;
      setState(() => _questionIndex = 5); // Jump to helper panic evaluation
    } else if (_questionIndex == 3) {
      // Q3: Airway obstruction / Choking (if responsive)
      _isChoking = answer;
      if (_isChoking) {
        setState(() => _questionIndex = 5);
      } else {
        setState(() => _questionIndex = 4); // Check severe bleeding
      }
    } else if (_questionIndex == 4) {
      // Q4: Severe Bleeding
      _hasSevereBleeding = answer;
      setState(() => _questionIndex = 5);
    } else if (_questionIndex == 5) {
      // Q5: Helper panic / confidence check
      _isHelperPanicked = answer;
      _determineAndDispatch();
    }
  }

  void _determineAndDispatch() {
    String emergencyType = "CPR";
    if (!_isVictimResponsive && !_isVictimBreathing) {
      emergencyType = "CPR";
    } else if (_isChoking) {
      emergencyType = "CHOKING";
    } else if (_hasSevereBleeding) {
      emergencyType = "BLEEDING";
    } else {
      emergencyType = "CPR";
    }

    _dispatchProtocol(emergencyType);
  }

  void _dispatchProtocol(String emergencyType) {
    final steps = ApiService.getAdaptiveProtocol(
      emergencyType: emergencyType,
      isVictimResponsive: _isVictimResponsive,
      isVictimBreathing: _isVictimBreathing,
      isHelperPanicked: _isHelperPanicked,
      isHelperAlone: _isHelperAlone,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GuidanceScreen(
          language: widget.language,
          steps: steps,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, Map<String, String>> questionMap = {
      0: {
        'en': 'Is the area safe to approach? (Check for fire, live wires, traffic)',
        'kn': 'ಸ್ಥಳವು ಸುರಕ್ಷಿತವಾಗಿದೆಯೇ? (ಬೆಂಕಿ, ವಿದ್ಯುತ್ ತಂತಿ, ವಾಹನಗಳ ಅಪಾಯ ಗಮನಿಸಿ)',
        'ta': 'அந்த இடம் அணுக பாதுகாப்பானதா? (தீ, மின்கம்பி, போக்குவரத்து சரிபார்க்கவும்)',
        'te': 'ఆ ప్రాంతం సురక్షితంగా ఉందా? (మంటలు, విద్యుత్ తీగలు, ట్రాఫిక్ గమనించండి)',
        'hi': 'क्या दुर्घटना स्थल सुरक्षित है? (आग, बिजली के तार, ट्रैफिक की जांच करें)',
        'ml': 'സ്ഥലം സുരക്ഷിതമാണോ? (തീ, വൈദ്യുതി കമ്പി, വാഹനാപകടം പരിശോധിക്കുക)',
      },
      1: {
        'en': 'Is the injured person conscious or responding to you?',
        'kn': 'ಗಾಯಾಳು ಪ್ರಜ್ಞೆಯಲ್ಲಿದ್ದಾರೆಯೇ ಅಥವಾ ಮಾತಿಗೆ ಸ್ಪಂದಿಸುತ್ತಿದ್ದಾರೆಯೇ?',
        'ta': 'பாதிக்கப்பட்ட நபர் சுயநினைவுடன் உள்ளாரா அல்லது பதிலளிக்கிறாரா?',
        'te': 'బాధితుడు స్పృహలో ఉన్నాడా లేదా మీ మాటకు స్పందిస్తున్నాడా?',
        'hi': 'क्या घायल व्यक्ति होश में है या आपकी बात सुन रहा है?',
        'ml': 'വ്യക്തിക്ക് ബോധമുണ്ടോ അല്ലെങ്കിൽ പ്രതികരിക്കുന്നുണ്ടോ?',
      },
      2: {
        'en': 'Is the person breathing normally? (Look closely at chest movement)',
        'kn': 'ವ್ಯಕ್ತಿ ಸಹಜವಾಗಿ ಉಸಿರಾಡುತ್ತಿದ್ದಾರೆಯೇ? (ಎದೆಯ ಚಲನೆಯನ್ನು ಗಮನಿಸಿ)',
        'ta': 'அவர் சாதாரணமாக சுவாசிக்கிறாரா? (நெஞ்சு அசைவை கவனிக்கவும்)',
        'te': 'వ్యక్తి సాధారణంగా శ్వాస తీసుకుంటున్నాడా? (ఛాతీ కదలికను చూడండి)',
        'hi': 'क्या व्यक्ति सामान्य रूप से सांस ले रहा है? (छाती की हलचल देखें)',
        'ml': 'വ്യക്തി ശ്വാസമെടുക്കുന്നുണ്ടോ? (നെഞ്ചിന്റെ ചലനം ശ്രദ്ധിക്കുക)',
      },
      3: {
        'en': 'Are they clutching their neck or unable to speak (Choking)?',
        'kn': 'ಅವರು ಗಂಟಲು ಹಿಡಿದುಕೊಂಡಿದ್ದಾರೆಯೇ ಅಥವಾ ಉಸಿರುಗಟ್ಟುತ್ತಿದ್ದಾರೆಯೇ?',
        'ta': 'தொண்டையை பிடித்துக்கொண்டு பேச முடியாமல் திணறுகிறாரா?',
        'te': 'గొంతు పట్టుకుని మాట్లాడలేకపోతున్నారా (శ్వాస ఆడకపోవడం)?',
        'hi': 'क्या उनका दम घुट रहा है या वे बोलने में असमर्थ हैं?',
        'ml': 'തൊണ്ടയിൽ എന്തെങ്കിലും കുടുങ്ങി ശ്വാസം മുട്ടുന്നുണ്ടോ?',
      },
      4: {
        'en': 'Is there heavy, spurting, or severe external bleeding?',
        'kn': 'ಅತಿಯಾದ ಅಥವಾ ರಕ್ತಸ್ರಾವ ನಿಲ್ಲದೆ ಹರಿಯುತ್ತಿದೆಯೇ?',
        'ta': 'அதிகளவில் ரத்தம் வெளியேறுகிறதா?',
        'te': 'రక్తం ఎక్కువగా కారుతోందా?',
        'hi': 'क्या बहुत अधिक या तेजी से खून बह रहा है?',
        'ml': 'രക്തം അമിതമായി ഒഴുകുന്നുണ്ടോ?',
      },
      5: {
        'en': 'As the helper, are you feeling panicked or overwhelmed right now?',
        'kn': 'ಸಹಾಯಕರಾಗಿ ನಿಮಗೆ ಈಗ ಹೆಚ್ಚು ಆತಂಕ ಅಥವಾ ಹೆದರಿಕೆಯಾಗುತ್ತಿದೆಯೇ?',
        'ta': 'உதவியாளராகிய நீங்கள் தற்போது அதிக பதற்றத்தில் உள்ளீர்களா?',
        'te': 'సహాయకుడిగా మీకు ఇప్పుడు భయంగా లేదా ఆందోళనగా ఉందా?',
        'hi': 'मददगार के रूप में, क्या आप अभी बहुत घबराए हुए महसूस कर रहे हैं?',
        'ml': 'സഹായി എന്ന നിലയിൽ നിങ്ങൾക്ക് ഭയമോ പരിഭ്രാന്തിയോ തോന്നുന്നുണ്ടോ?',
      },
    };

    final Map<String, Map<String, String>> buttonLabels = {
      'en': {'yes': 'YES', 'no': 'NO', 'call': 'CALL 112 (DIRECT SOS)'},
      'kn': {'yes': 'ಹೌದು (YES)', 'no': 'ಇಲ್ಲ (NO)', 'call': '112 ತುರ್ತು ಕರೆ ಮಾಡಿ'},
      'ta': {'yes': 'ஆம் (YES)', 'no': 'இல்லை (NO)', 'call': '112 அவசர அழைப்பு'},
      'te': {'yes': 'అవును (YES)', 'no': 'కాదు (NO)', 'call': '112 అత్యవసర కాల్'},
      'hi': {'yes': 'हाँ (YES)', 'no': 'नहीं (NO)', 'call': '112 आपातकालीन कॉल'},
      'ml': {'yes': 'അതെ (YES)', 'no': 'അല്ല (NO)', 'call': '112 അടിയന്തര കോൾ'},
    };

    final labels = buttonLabels[widget.language] ?? buttonLabels['en']!;
    final currentQ = questionMap[_questionIndex]?[widget.language] ??
        questionMap[_questionIndex]?['en'] ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('RapidAid Assessment'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.phone_in_talk, size: 24),
          label: Text(
            labels['call']!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _makeDirectCall('112'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_questionIndex + 1) / 6,
              color: Colors.red[800],
              backgroundColor: Colors.grey[300],
              minHeight: 6,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      _questionIndex == 0
                          ? Icons.security
                          : (_questionIndex == 5 ? Icons.psychology : Icons.health_and_safety),
                      size: 64,
                      color: Colors.red[800],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      currentQ,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _processAnswer(true),
                    child: Text(
                      labels['yes']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _processAnswer(false),
                    child: Text(
                      labels['no']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}