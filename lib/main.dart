import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const RapidAidApp());
}

class RapidAidApp extends StatelessWidget {
  const RapidAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidAid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF991B1B)),
      ),
      home: const MainEmergencyScreen(),
    );
  }
}

class MainEmergencyScreen extends StatefulWidget {
  const MainEmergencyScreen({super.key});

  @override
  State<MainEmergencyScreen> createState() => _MainEmergencyScreenState();
}

class _MainEmergencyScreenState extends State<MainEmergencyScreen> with SingleTickerProviderStateMixin {
  String _selectedLang = 'en';
  String _locationStatus = "Acquiring live GPS coordinates...";
  late AnimationController _pulseController;

  final Map<String, String> _languages = {
    'en': 'English',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'hi': 'हिंदी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'ml': 'മലയാളം (Malayalam)',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      if (mounted) {
        setState(() {
          _locationStatus = "GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (Bengaluru)";
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationStatus = "Location: Bengaluru, Karnataka (Share landmark with 112)");
    }
  }

  void _call112() async {
    final Uri uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openVoiceTriageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => VoiceAssistantModal(
        language: _selectedLang,
        onScenarioResolved: (protocolKey, spokenResponse) {
          Navigator.pop(context);
          _navigateToProcedure(protocolKey);
        },
      ),
    );
  }

  void _navigateToProcedure(String protocolKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveRescueScreen(
          protocolKey: protocolKey,
          language: _selectedLang,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF991B1B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              "RapidAid",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButton<String>(
              value: _selectedLang,
              dropdownColor: const Color(0xFF7F1D1D),
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.white, size: 18),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              items: _languages.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLang = val);
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _locationStatus,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.phone_in_talk, size: 24),
              label: const Text(
                "CALL 112 / 108 AMBULANCE DISPATCH",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: _call112,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _openVoiceTriageDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 26,
                      child: Icon(Icons.mic, color: Color(0xFF1E3A8A), size: 30),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TALK TO VOICE ASSISTANT",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "\"Describe what happened in your language. The assistant will guide you and calm your panic.\"",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.self_improvement_rounded, color: Colors.amber, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "STAY CALM: You are capable of helping. Speak to the assistant above or follow the visual hand placements below.",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF78350F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ScaleTransition(
              scale: Tween(begin: 0.98, end: 1.02).animate(_pulseController),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InteractiveTriageScreen(language: _selectedLang),
                    ),
                  );
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.troubleshoot_rounded, color: Colors.white, size: 42),
                      SizedBox(width: 14),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "MANUAL TRIAGE QUESTIONS",
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            "Tap here if you cannot speak right now",
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Direct Road Emergency Pathways (1-Tap):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            _buildEmergencyTile(
              title: "Cardiac Arrest / Collapsed (CPR)",
              subtitle: "Sternum hand placement & 110 BPM rhythm",
              icon: Icons.favorite_rounded,
              color: Colors.red.shade700,
              protocolKey: "CPR",
            ),
            _buildEmergencyTile(
              title: "Severe Road Bleeding & Trauma",
              subtitle: "Wound direct pressure & limb elevation",
              icon: Icons.bloodtype_rounded,
              color: Colors.red.shade900,
              protocolKey: "BLEEDING",
            ),
            _buildEmergencyTile(
              title: "Severe Choking / Airway Blocked",
              subtitle: "Scapula back blows & navel Heimlich thrusts",
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade800,
              protocolKey: "CHOKING",
            ),
            _buildEmergencyTile(
              title: "Motorcycle Crash / Neck Injury",
              subtitle: "Spinal alignment, DO NOT remove helmet",
              icon: Icons.two_wheeler_rounded,
              color: Colors.deepOrange.shade800,
              protocolKey: "SPINAL_CAUTION",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String protocolKey,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => _navigateToProcedure(protocolKey),
      ),
    );
  }
}

class VoiceAssistantModal extends StatefulWidget {
  final String language;
  final Function(String protocolKey, String spokenResponse) onScenarioResolved;

  const VoiceAssistantModal({
    super.key,
    required this.language,
    required this.onScenarioResolved,
  });

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> {
  bool _isListening = false;
  bool _isAnalyzing = false;
  String _transcript = "";
  String _diagnosisSummary = "";
  String _resolvedProtocol = "";
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _transcript = "Listening... Speak now";
      _diagnosisSummary = "";
    });

    if (kIsWeb) {
      String localeTag = "${widget.language}-IN";
      if (widget.language == 'en') localeTag = 'en-IN';

      js.context.callMethod('eval', ["""
        window.speechResult = "";
        var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (SpeechRec) {
          var rec = new SpeechRec();
          rec.lang = '$localeTag';
          rec.continuous = false;
          rec.interimResults = false;
          rec.start();
          rec.onresult = function(e) {
            window.speechResult = e.results[0][0].transcript;
          };
          rec.onerror = function(e) {
            console.log('Voice rec error', e);
          };
        }
      """]);

      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted || !_isListening) {
          timer.cancel();
          return;
        }
        var res = js.context['speechResult'];
        if (res != null && res.toString().isNotEmpty) {
          timer.cancel();
          setState(() {
            _isListening = false;
            _transcript = res.toString();
            _textController.text = _transcript;
          });
          _analyzeSituation(_transcript);
        }
      });
    }
  }

  Future<void> _analyzeSituation(String spokenText) async {
    if (spokenText.trim().isEmpty) return;
    setState(() {
      _isAnalyzing = true;
      _isListening = false;
    });

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/analyze-scenario"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_speech": spokenText,
          "language": widget.language,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resolvedProtocol = data["resolved_protocol"];
          _diagnosisSummary = data["spoken_reassurance"];
          _isAnalyzing = false;
        });

        // Play the full de-escalation & medical instruction audio
        _playSpokenAudio(_diagnosisSummary, widget.language);
      }
    } catch (e) {
      setState(() {
        _resolvedProtocol = "CPR";
        _diagnosisSummary = "The person is unresponsive. Start Hands-Only CPR immediately.";
        _isAnalyzing = false;
      });
    }
  }

  void _playSpokenAudio(String text, String lang) {
    if (kIsWeb) {
      String encoded = Uri.encodeComponent(text);
      String url = "http://localhost:8000/api/tts?text=$encoded&lang=$lang";
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) window.rapidAidAudio.pause();
        window.rapidAidAudio = new Audio('$url');
        window.rapidAidAudio.play().catch(function(e){ console.log(e); });
      """]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            const Text(
              "RapidAid Emergency Medical Triage",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 14),

            // If diagnosis is ready, display it prominently
            if (_diagnosisSummary.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Color(0xFF991B1B)),
                        const SizedBox(width: 8),
                        Text(
                          "DIAGNOSIS: $_resolvedProtocol",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF991B1B), fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _diagnosisSummary,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  "START VISUAL RESCUE STEPS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  widget.onScenarioResolved(_resolvedProtocol, _diagnosisSummary);
                },
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Text(
                "Describe what happened: (e.g., 'A person fell down and is not responding')",
                style: TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isListening ? null : _startListening,
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: _isListening ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: _isListening ? Colors.red.shade800 : Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isAnalyzing
                    ? "Analyzing clinical scenario..."
                    : (_isListening ? "Listening... Speak now" : "Tap mic to speak again"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "Or type scenario here and press enter...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1E3A8A)),
                    onPressed: () => _analyzeSituation(_textController.text),
                  ),
                ),
                onSubmitted: _analyzeSituation,
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class InteractiveTriageScreen extends StatefulWidget {
  final String language;
  const InteractiveTriageScreen({super.key, required this.language});

  @override
  State<InteractiveTriageScreen> createState() => _InteractiveTriageScreenState();
}

class _InteractiveTriageScreenState extends State<InteractiveTriageScreen> {
  int _step = 0;

  final List<String> _questions = [
    "Is the scene safe from traffic, fire, and live wires?",
    "Tap their shoulder firmly: Is the person responding or awake?",
    "Look at the chest: Are they breathing normally?",
    "Is there severe, spurting external bleeding?",
    "Are they clutching their throat / unable to cough?",
  ];

  void _handleAnswer(bool answer) {
    if (_step == 0) {
      if (!answer) {
        _finishTriage("SPINAL_CAUTION");
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!answer) {
        setState(() => _step = 2);
      } else {
        setState(() => _step = 3);
      }
    } else if (_step == 2) {
      if (!answer) {
        _finishTriage("CPR");
      } else {
        _finishTriage("SPINAL_CAUTION");
      }
    } else if (_step == 3) {
      if (answer) {
        _finishTriage("BLEEDING");
      } else {
        setState(() => _step = 4);
      }
    } else if (_step == 4) {
      if (answer) {
        _finishTriage("CHOKING");
      } else {
        _finishTriage("SPINAL_CAUTION");
      }
    }
  }

  void _finishTriage(String resolvedKey) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveRescueScreen(
          protocolKey: resolvedKey,
          language: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Emergency Triage"),
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / 5,
              color: const Color(0xFFDC2626),
              backgroundColor: Colors.grey.shade300,
              minHeight: 8,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.help_outline_rounded, size: 64, color: Color(0xFF991B1B)),
                    const SizedBox(height: 16),
                    Text(
                      _questions[_step],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleAnswer(true),
                    child: const Text("YES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleAnswer(false),
                    child: const Text("NO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ActiveRescueScreen extends StatefulWidget {
  final String protocolKey;
  final String language;

  const ActiveRescueScreen({super.key, required this.protocolKey, required this.language});

  @override
  State<ActiveRescueScreen> createState() => _ActiveRescueScreenState();
}

class _ActiveRescueScreenState extends State<ActiveRescueScreen> with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _metronomeController;

  final Map<String, List<Map<String, Map<String, String>>>> _localizedProtocols = {
    "CPR": [
      {
        "title": {
          "en": "Step 1: Place Heel on Center of Breastbone (Sternum)",
          "kn": "ಹಂತ 1: ಎದೆಯ ಮಧ್ಯದಲ್ಲಿ (Sternum) ಒಂದು ಕೈಯ ಹಿಮ್ಮಡಿ ಇಡಿ",
          "hi": "चरण 1: छाती की मध्य हड्डी (स्टर्नम) पर हथेली रखें",
          "ta": "படி 1: நெஞ்செலும்பின் நடுவில் உள்ளங்கையின் அடியை வைக்கவும்",
          "te": "దశ 1: ఛాతీ మధ్యభాగం (స్టెర్నమ్) పై చేతి మడమ ఉంచండి",
          "ml": "ഘട്ടം 1: നെഞ്ചെല്ലിന്റെ കൃത്യം മധ്യത്തിൽ കൈപ്പത്തി വയ്ക്കുക",
        },
        "action": {
          "en": "Place the heel of one hand directly in the center of the chest between the nipples.",
          "kn": "ಎರಡು ಮೊಲೆತೊಟ್ಟುಗಳ ಮಧ್ಯಭಾಗದಲ್ಲಿ ನೇರವಾಗಿ ಒಂದು ಕೈಯ ಹಿಮ್ಮಡಿಯನ್ನು ಇರಿಸಿ.",
          "hi": "दोनों निपल्स के ठीक बीच में छाती की हड्डी पर एक हाथ की हथेली रखें।",
          "ta": "மார்பின் நடுப்பகுதியில் ஒரு கையின் அடிபாகத்தை உறுதியாக வைக்கவும்.",
          "te": "ఛాతీ మధ్యలో ఎముకపై ఒక చేతి మడమను నేరుగా ఉంచండి.",
          "ml": "നെഞ്ചിന്റെ മധ്യഭാഗത്ത് കൈപ്പത്തിയുടെ അടിഭാഗം ഉറപ്പിച്ചു വെയ്ക്കുക.",
        },
        "desc": {
          "en": "Keep only the palm heel touching the bone; keep fingers raised off the ribs.",
          "kn": "ಕೇವಲ ಕೈಯ ಹಿಮ್ಮಡಿ ಮಾತ್ರ ಎದೆ ಮೂಳೆ ಮುಟ್ಟಲಿ; ಬೆರಳುಗಳು ಪಕ್ಕೆಲಬಿಗೆ ತಾಗದಂತೆ ಮೇಲಕ್ಕೆತ್ತಿ.",
          "hi": "हथेली का निचला भाग ही हड्डी पर लगे; उंगलियां पसलियों से ऊपर उठी रहें।",
          "ta": "உள்ளங்கையின் அடிப்பகுதி மட்டுமே நெஞ்சில் பட வேண்டும்; விரல்களை உயர்த்தவும்.",
          "te": "చేతి మడమ మాత్రమే తగలాలి; వేళ్లు పక్కటెముకలకు తగలకుండా పైకి ఉంచండి.",
          "ml": "കൈപ്പത്തിയുടെ അടിഭാഗം മാത്രം മുട്ടിക്കുക; വിരലുകൾ വാരിയെല്ലുകളിൽ തട്ടരുത്.",
        }
      },
      {
        "title": {
          "en": "Step 2: Lace Fingers of Second Hand on Top",
          "kn": "ಹಂತ 2: ಎರಡನೇ ಕೈಯನ್ನು ಮೇಲಿಟ್ಟು ಬೆರಳುಗಳನ್ನು ಲಾಕ್ ಮಾಡಿ",
          "hi": "चरण 2: दूसरे हाथ की उंगलियां ऊपर फंसाएं",
          "ta": "படி 2: இரண்டாவது கையை மேலே வைத்து விரல்களைப் பூட்டவும்",
          "te": "దశ 2: రెండో చేయి పైనుంచి వేళ్లను లాక్ చేయండి",
          "ml": "ഘട്ടം 2: അടുത്ത കൈ മുകളിൽ വച്ച് വിരലുകൾ കോർക്കുക",
        },
        "action": {
          "en": "Place your second hand directly over the first and interlock your fingers tightly.",
          "kn": "ಮೊದಲ ಕೈಯ ಮೇಲೆ ಎರಡನೇ ಕೈಯನ್ನು ಇಟ್ಟು ಬೆರಳುಗಳನ್ನು ಒಂದಕ್ಕೊಂದು ಸೇರಿಸಿ ಭದ್ರಪಡಿಸಿ.",
          "hi": "पहली हथेली के ऊपर दूसरा हाथ रखें और उंगलियों को कसकर आपस में फंसाएं।",
          "ta": "முதல் கையின் மேல் இரண்டாவது கையை வைத்து விரல்களை இறுக்கமாகப் பூட்டவும்.",
          "te": "మొదటి చేతిపై రెండో చేతిని ఉంచి వేళ్లను గట్టిగా బంధించండి.",
          "ml": "ആദ്യത്തെ കൈക്ക് മുകളിൽ അടുത്ത കൈ വച്ച് വിരലുകൾ മുറുക്കി കോർക്കുക.",
        },
        "desc": {
          "en": "This locks your hands together so maximum downward force is transferred.",
          "kn": "ಇದು ನಿಮ್ಮ ಕೈಗಳನ್ನು ಭದ್ರಪಡಿಸಿ ಕೆಳಮುಖವಾಗಿ ಪೂರ್ಣ ಬಲ ಪ್ರಯೋಗಿಸಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ.",
          "hi": "यह आपके हाथों को स्थिर करता है ताकि पूरा दबाव नीचे की ओर पड़े।",
          "ta": "இது முழு அழுத்தத்தையும் நேராக நெஞ்சுக்கு செலுத்த உதவுகிறது.",
          "te": "ఇది మీ చేతులను స్థిరంగా ఉంచి పూర్తి బలాన్ని కిందకు ప్రసరింపజేస్తుంది.",
          "ml": "ഇത് കൈകളെ ഉറപ്പിച്ചു നിർത്തി കൃത്യമായ താഴേക്കുള്ള മർദ്ദം നൽകുന്നു.",
        }
      },
      {
        "title": {
          "en": "Step 3: Shoulders Vertically Over Hands & Locked Elbows",
          "kn": "ಹಂತ 3: ಭುಜಗಳನ್ನು ಕೈಯ ಮೇಲೆ ನೇರವಾಗಿಡಿ & ಮೊಣಕೈ ಲಾಕ್ ಮಾಡಿ",
          "hi": "चरण 3: कंधे हाथों की सीधी सीध में और कोहनी बिल्कुल सीधी",
          "ta": "படி 3: தோள்கள் கைகளுக்கு மேலே நேராகவும் முழங்கைகள் நேரான நிலையிலும்",
          "te": "దశ 3: భుజాలు చేతులపై నిటారుగా ఉంచి మోచేతులు లాక్ చేయండి",
          "ml": "ഘട്ടം 3: തോൾ കൈകൾക്ക് മുകളിലായി കൈകൾ വളയാതെ പിടിക്കുക",
        },
        "action": {
          "en": "Kneel beside victim. Bring shoulders directly over your hands. Keep arms completely vertical.",
          "kn": "ವ್ಯಕ್ತಿಯ ಪಕ್ಕದಲ್ಲಿ ಮಂಡಿಯೂರಿ, ಭುಜಗಳನ್ನು ಕೈಗಳ ನೇರಕ್ಕೆ ತಂದು ಮೊಣಕೈ ಮಣಿಸದೆ ನೇರವಾಗಿಡಿ.",
          "hi": "घुटने टेकें। कंधों को सीधे हाथों के ऊपर लाएं। बांहें 90 डिग्री सीधी रखें।",
          "ta": "மண்டியிட்டு அமரவும். தோள்களை கைகளுக்கு மேல் கொண்டு வந்து கைகளை நேராக வைக்கவும்.",
          "te": "మోకరిల్లి కూర్చోండి. భుజాలను చేతులపై ఉంచి చేతులను నిలువుగా ఉంచండి.",
          "ml": "മുട്ടുകുത്തി ഇരിക്കുക. തോൾ കൈകൾക്ക് നേരെ മുകളിലാക്കി കൈകൾ നിവർത്തി പിടിക്കുക.",
        },
        "desc": {
          "en": "Do not bend arms; compress using your upper body core weight.",
          "kn": "ಕೈಗಳನ್ನು ಮಣಿಸಬೇಡಿ; ನಿಮ್ಮ ದೇಹದ ಮೇಲ್ಭಾಗದ ತೂಕದಿಂದ ಎದೆ ಒತ್ತಿರಿ.",
          "hi": "कोहनी न मोड़ें; शरीर के भार का उपयोग करके नीचे दबाएं।",
          "ta": "கைகளை வளைக்காதீர்கள்; உடலின் மேல் எடையால் அழுத்தவும்.",
          "te": "చేతులు వంచకండి; శరీర పైభాగ బరువుతో నొక్కండి.",
          "ml": "കൈ മടക്കരുത്; ശരീരഭാരം ഉപയോഗിച്ച് താഴോട്ട് അമർത്തുക.",
        }
      },
      {
        "title": {
          "en": "Step 4: Compress 2 Inches Deep at 110 BPM",
          "kn": "ಹಂತ 4: 2 ಇಂಚು ಆಳಕ್ಕೆ ನಿಮಿಷಕ್ಕೆ 110 ರ ಲಯದಲ್ಲಿ ಒತ್ತಿರಿ",
          "hi": "चरण 4: 2 इंच गहरा और 110 BPM गति से दबाएं",
          "ta": "படி 4: 2 அங்குல ஆழத்திற்கு 110 BPM வேகத்தில் அழுத்தவும்",
          "te": "దశ 4: 2 అంగుళాల లోతుకు 110 BPM వేగంతో నొక్కండి",
          "ml": "ഘട്ടം 4: 2 ഇഞ്ച് താഴ്ചയിൽ 110 BPM വേഗത്തിൽ അമർത്തുക",
        },
        "action": {
          "en": "Push hard and fast. Compress at least 2 inches deep. Follow the pulsing metronome.",
          "kn": "ಬಲವಾಗಿ ಮತ್ತು ವೇಗವಾಗಿ ಒತ್ತಿರಿ. ಕನಿಷ್ಠ 2 ಇಂಚು ಆಳಕ್ಕೆ ಕೆಂಪು ಪಲ್ಸ್ ಜೊತೆ ಒತ್ತಿರಿ.",
          "hi": "तेजी और जोर से दबाएं। कम से कम 2 इंच गहरा दबाएं। बीट के साथ ताल मिलाएं।",
          "ta": "வேகமாகவும் பலமாகவும் அழுத்தவும். 2 அங்குல ஆழத்திற்கு பீட் உடன் அழுத்தவும்.",
          "te": "వేగంగా బలంగా నొక్కండి. శబ్దంతో పాటు 2 అంగుళాల లోతుకు నొక్కండి.",
          "ml": "വേഗത്തിലും ശക്തിയിലും അമർത്തുക. താളത്തിനൊത്ത് 2 ഇഞ്ച് താഴ്ചയിൽ ചെയ്യുക.",
        },
        "desc": {
          "en": "Allow complete chest recoil between each push so the heart refills with blood.",
          "kn": "ಪ್ರತಿ ಬಾರಿಯೂ ಎದೆ ಸಹಜ ಸ್ಥಿತಿಗೆ ಬರಲು ಬಿಡಿ, ಇದರಿಂದ ರಕ್ತ ಹೃದಯಕ್ಕೆ ಮರುತುಂಬುತ್ತದೆ.",
          "hi": "हर दबाव के बाद छाती को पूरी तरह ऊपर आने दें ताकि खून भर सके।",
          "ta": "ஒவ்வொரு அழுத்தத்திற்குப் பிறகும் நெஞ்சு முழுமையாக மேலே வரவிடவும்.",
          "te": "ప్రతిసారీ ఛాతీ పైకి రావడానికి వీలు కల్పించండి.",
          "ml": "ഓരോ അമർത്തലിനും ശേഷം നെഞ്ച് പൂർണ്ണമായി ഉയരാൻ അനുവദിക്കുക.",
        }
      },
      {
        "title": {
          "en": "Step 5: Do NOT Stop Until Ambulance Arrives",
          "kn": "ಹಂತ 5: 112 ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೂ ನಿಲ್ಲಿಸಬೇಡಿ",
          "hi": "चरण 5: एम्बुलेंस आने तक रुकें नहीं",
          "ta": "படி 5: ஆம்புலன்ஸ் வரும் வரை நிறுத்த வேண்டாம்",
          "te": "దశ 5: అంబులెన్స్ వచ్చేవరకు ఆపకండి",
          "ml": "ഘട്ടം 5: ആംബുലൻസ് വരുന്നത് വരെ നിർത്തരുത്",
        },
        "action": {
          "en": "Continue compressions. You are circulating vital oxygen to the brain.",
          "kn": "ಎದೆ ಒತ್ತುವುದನ್ನು ಮುಂದುವರಿಸಿ. ನೀವು ಮಿದುಳಿಗೆ ಆಮ್ಲಜನಕವನ್ನು ರವಾನಿಸುತ್ತಿದ್ದೀರಿ.",
          "hi": "लगातार दबाते रहें। आप दिमाग तक प्राणवायु पहुंचा रहे हैं।",
          "ta": "தொடர்ந்து அழுத்தவும். மூளைக்கு தேவையான ஆக்ஸிஜனை செலுத்துகிறீர்கள்.",
          "te": "నొక్కుతూనే ఉండండి. మీరు మెదడుకు ఆక్సిజన్‌ను సరఫరా చేస్తున్నారు.",
          "ml": "അമർത്തുന്നത് തുടരുക. ഇത് തലച്ചോറിലേക്ക് ഓക്സിജൻ എത്തിക്കുന്നു.",
        },
        "desc": {
          "en": "If exhausted, swap with another bystander without stopping compressions.",
          "kn": "ಆಯಾಸವಾದರೆ ಇನ್ನೊಬ್ಬರಿಗೆ ತಿಳಿಸಿ ತಕ್ಷಣ ಬದಲಾಯಿಸಿಕೊಳ್ಳಿ.",
          "hi": "थक जाने पर तुरंत किसी अन्य मददगार को जिम्मेदारी सौंपें।",
          "ta": "களைப்படைந்தால் உடனே மற்றொருவரை மாற்றிக் கொள்ளவும்.",
          "te": "అలసిపోతే వెంటనే వేరొకరిని మార్చండి.",
          "ml": "ക്ഷീണിച്ചാൽ അടുത്തയാളെക്കൊണ്ട് ചെയ്യിക്കുക.",
        }
      }
    ],
    "BLEEDING": [
      {
        "title": {
          "en": "Step 1: Direct Downward Pressure on Wound Site",
          "kn": "ಹಂತ 1: ಗಾಯದ ಜಾಗದ ಮೇಲೆ ನೇರ ಕೆಳಮುಖ ಒತ್ತಡ",
          "hi": "चरण 1: घाव पर सीधा नीचे की ओर दबाव बनाएं",
          "ta": "படி 1: காயத்தின் மீது நேரடி கீழ்நோக்கிய அழுத்தம்",
          "te": "దశ 1: గాయంపై నేరుగా కిందకు ఒత్తిడి ఉంచండి",
          "ml": "ഘട്ടം 1: മുറിവിൽ നേരിട്ട് താഴേക്ക് അമർത്തുക",
        },
        "action": {
          "en": "Place a clean cloth pad directly over the bleeding laceration and press with full palm force.",
          "kn": "ಶುದ್ಧ ಬಟ್ಟೆಯನ್ನು ರಕ್ತ ಹರಿಯುತ್ತಿರುವ ಗಾಯದ ಮೇಲಿಟ್ಟು ಅಂಗೈ ಬಲದಿಂದ ಗಟ್ಟಿಯಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ.",
          "hi": "घाव के ठीक ऊपर साफ कपड़ा रखें और पूरी हथेली की ताकत से दबाएं।",
          "ta": "சுத்தமான துணியை காயத்தின் மீது வைத்து உள்ளங்கையின் முழு பலத்தால் அழுத்தவும்.",
          "te": "శుభ్రమైన గుడ్డను గాయంపై ఉంచి అరచేతి బలంతో గట్టిగా నొక్కండి.",
          "ml": "വൃത്തിയുള്ള തുണി മുറിവിന് മുകളിൽ വെച്ച് കൈപ്പത്തി കൊണ്ട് ശക്തിയായി അമർത്തുക.",
        },
        "desc": {
          "en": "Maintain uninterrupted pressure. Do not lift hands to inspect if bleeding has stopped.",
          "kn": "ಒತ್ತಡವನ್ನು ಸಡಿಲಿಸಬೇಡಿ. ರಕ್ತ ನಿಂತಿದೆಯೇ ಎಂದು ನೋಡಲು ಬಟ್ಟೆಯನ್ನು ಮೇಲಕ್ಕೆತ್ತಬೇಡಿ.",
          "hi": "दबाव बनाए रखें। घाव देखने के लिए हाथ बिल्कुल न उठाएं।",
          "ta": "அழுத்தத்தை தளர்த்த வேண்டாம். துணியை தூக்கிப் பார்க்க வேண்டாம்.",
          "te": "ఒత్తిడి తగ్గించవద్దు. రక్తం ఆగిందో లేదో చూడటానికి చేతిని తీయవద్దు.",
          "ml": "അമർത്തിപ്പിടിക്കുക. രക്തം നിലച്ചോ എന്ന് നോക്കാൻ കൈ മാറ്റരുത്.",
        }
      },
      {
        "title": {
          "en": "Step 2: Add Secondary Cloth Layer If Soaked",
          "kn": "ಹಂತ 2: ರಕ್ತ ಸೋರಿದರೆ ಮತ್ತೊಂದು ಬಟ್ಟೆಯನ್ನು ಮೇಲೆಯೇ ಇಡಿ",
          "hi": "चरण 2: कपड़ा भीगने पर उसके ऊपर दूसरा कपड़ा रखें",
          "ta": "படி 2: ரத்தம் கசிந்தால் மேலே மற்றொரு துணியை வைக்கவும்",
          "te": "దశ 2: బట్ట తడిస్తే దానిపైనే మరొకటి ఉంచండి",
          "ml": "ഘട്ടം 2: തുണി നനഞ്ഞാൽ അതിന് മുകളിൽ അടുത്ത തുണി വെക്കുക",
        },
        "action": {
          "en": "Never remove the first cloth layer as it disrupts clot formation. Place more cloth over it.",
          "kn": "ಮೊದಲ ಬಟ್ಟೆಯನ್ನು ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ತೆಗೆಯಬೇಡಿ. ಅದರ ಮೇಲೆಯೇ ಮತ್ತಷ್ಟು ಬಟ್ಟೆಗಳನ್ನು ಇಟ್ಟು ಒತ್ತಿರಿ.",
          "hi": "पहला कपड़ा न हटाएं क्योंकि इससे थक्का टूटता है। उसके ऊपर और कपड़ा रखें।",
          "ta": "முதல் துணியை அகற்ற வேண்டாம். அதன் மேலேயே கூடுதல் துணியை வைத்து அழுத்தவும்.",
          "te": "మొదటి గుడ్డను తీయకండి. దానిపైనే మరిన్ని గుడ్డలు పెట్టి నొక్కండి.",
          "ml": "ആദ്യത്തെ തുണി മാറ്റരുത്. അതിന് മുകളിൽ കൂടുതൽ തുണി വെച്ച് അമർത്തുക.",
        },
        "desc": {
          "en": "Wrap tightly with gauze, scarf, or belt to lock pressure continuously.",
          "kn": "ಬ್ಯಾಂಡೇಜ್ ಅಥವಾ ಶಾಲಿನಿಂದ ಬಿಗಿಯಾಗಿ ಕಟ್ಟಿ ರಕ್ತಸ್ರಾವ ತಡೆಯಿರಿ.",
          "hi": "पट्टी या दुपट्टे से कसकर बांधें ताकि दबाव बना रहे।",
          "ta": "துணியை இறுக்கமாகக் கட்டி அழுத்தத்தைத் தொடரவும்.",
          "te": "ఒత్తిడి కొనసాగేలా గుడ్డతో గట్టిగా కట్టు కట్టండి.",
          "ml": "തുണികൊണ്ട് മുറുക്കി കെട്ടി വെയ്ക്കുക.",
        }
      },
      {
        "title": {
          "en": "Step 3: Elevate Injured Limb Above Heart Level",
          "kn": "ಹಂತ 3: ಗಾಯಗೊಂಡ ಅಂಗವನ್ನು ಹೃದಯದ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ",
          "hi": "चरण 3: घायल अंग को दिल के स्तर से ऊपर उठाएं",
          "ta": "படி 3: காயம்பட்ட பகுதியை இதய நிலைக்கு மேல் உயர்த்தவும்",
          "te": "దశ 3: గాయపడిన భాగాన్ని గుండె కంటే ఎత్తులో ఉంచండి",
          "ml": "ഘട്ടം 3: മുറിവേറ്റ ഭാഗം ഹൃദയത്തിന് മുകളിലേക്ക് ഉയർത്തുക",
        },
        "action": {
          "en": "If bones are not broken, raise the bleeding arm or leg above chest level to lower blood pressure.",
          "kn": "ಮೂಳೆ ಮುರಿದಿಲ್ಲದಿದ್ದರೆ, ರಕ್ತದ ಒತ್ತಡ ಕಡಿಮೆ ಮಾಡಲು ಗಾಯವಾದ ಕೈ ಅಥವಾ ಕಾಲನ್ನು ಎದೆಯ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ.",
          "hi": "हड्डी न टूटी होने पर अंग को छाती के स्तर से ऊपर उठाएं ताकि खून का बहाव कम हो।",
          "ta": "எலும்பு முறிவு இல்லையெனில், காயம்பட்ட கையை அல்லது காலை இதயத்திற்கு மேல் உயர்த்தவும்.",
          "te": "ఎముక విరగకపోతే గాయపడిన భాగాన్ని ఛాతీ కంటే పైకి ఎత్తండి.",
          "ml": "എല്ല് പൊട്ടിയിട്ടില്ലെങ്കിൽ കൈയോ കാലോ നെഞ്ചിന് മുകളിലേക്ക് ഉയർത്തി വെയ്ക്കുക.",
        },
        "desc": {
          "en": "Keep the victim lying flat while keeping the limb elevated until 112 arrives.",
          "kn": "ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೆ ವ್ಯಕ್ತಿಯನ್ನು ಮಲಗಿಸಿ ಅಂಗವನ್ನು ಎತ್ತರದಲ್ಲೇ ಇರಿಸಿ.",
          "hi": "एम्बुलेंस आने तक व्यक्ति को सीधा लिटाए रखें और अंग ऊपर रखें।",
          "ta": "ஆம்புலன்ஸ் வரும் வரை நபரை படுக்க வைத்து பகுதியை உயர்த்தி பிடிக்கவும்.",
          "te": "అంబులెన్స్ వచ్చేవరకు వ్యక్తిని పడుకోబెట్టి ఆ భాగాన్ని పైనే ఉంచండి.",
          "ml": "ആംബുലൻസ് വരുന്നത് വരെ മുറിവേറ്റ ഭാഗം ഉയർത്തിപ്പിടിക്കുക.",
        }
      }
    ],
    "CHOKING": [
      {
        "title": {
          "en": "Step 1: Deliver 5 Firm Back Blows Between Scapulae",
          "kn": "ಹಂತ 1: ಭುಜದ ಮೂಳೆಗಳ (Scapulae) ಮಧ್ಯೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ",
          "hi": "चरण 1: दोनों कंधों की हड्डियों के बीच 5 बार जोर से थपथपाएं",
          "ta": "படி 1: தோள்பட்டைகளுக்கு இடையே 5 முறை பலமாக தட்டவும்",
          "te": "దశ 1: భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి",
          "ml": "ഘട്ടം 1: തോൾപ്പലകകൾക്ക് ഇടയിൽ 5 തവണ ശക്തിയായി തട്ടുക",
        },
        "action": {
          "en": "Support victim's chest with one hand, lean them forward, and strike between shoulder blades with palm heel.",
          "kn": "ಎದೆಯನ್ನು ಒಂದು ಕೈಯಿಂದ ಹಿಡಿದು ವ್ಯಕ್ತಿಯನ್ನು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ, ನಿಮ್ಮ ಕೈಯ ಹಿಮ್ಮಡಿಯಿಂದ ಬೆನ್ನಿನ ಮಧ್ಯೆ 5 ಬಾರಿ ತಟ್ಟಿ.",
          "hi": "छाती को सहारा देकर आगे झुकाएं और हथेली के निचले हिस्से से दोनों कंधों के बीच 5 बार थपथपाएं।",
          "ta": "மார்பைத் தாங்கி நபரை முன்னோக்கி சாய்த்து, தோள்பட்டை நடுவில் 5 முறை உள்ளங்கையால் தட்டவும்.",
          "te": "ఛాతీని పట్టుకుని ముందుకు వంచి, అరచేతి మడమతో భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి.",
          "ml": "നെഞ്ചിൽ താങ്ങി മുന്നോട്ട് ചരിച്ച് കൈപ്പത്തി കൊണ്ട് മുതുകിൽ 5 തവണ തട്ടുക.",
        },
        "desc": {
          "en": "Gravity combined with back blows pushes the stuck airway obstruction outward.",
          "kn": "ಗುರುತ್ವಾಕರ್ಷಣೆ ಮತ್ತು ನಿಮ್ಮ ಹೊಡೆತ ಗಂಟಲಿನಲ್ಲಿ ಸಿಲುಕಿರುವ ವಸ್ತುವನ್ನು ಹೊರದೂಡುತ್ತದೆ.",
          "hi": "आगे झुकने से रुकावट गले से बाहर की ओर निकलती है।",
          "ta": "இது தொண்டையில் அடைத்துள்ள பொருளை வெளியே தள்ள உதவுகிறது.",
          "te": "ఇది గొంతులో చిక్కుకున్న పదార్థాన్ని బయటకు నెడుతుంది.",
          "ml": "ഇത് തൊണ്ടയിൽ കുടുങ്ങിയ വസ്തുവിനെ പുറത്തേക്ക് തള്ളാൻ സഹായിക്കുന്നു.",
        }
      },
      {
        "title": {
          "en": "Step 2: Fist Placement Just Above Navel (Heimlich)",
          "kn": "ಹಂತ 2: ಹೊಕ್ಕುಳಿನ (Navel) ಮೇಲ್ಭಾಗದಲ್ಲಿ ಮುಷ್ಟಿ ಇಡಿ",
          "hi": "चरण 2: नाभि के ठीक ऊपर मुट्ठी रखें (हाइमलिक)",
          "ta": "படி 2: தொப்புளுக்கு மேலே முஷ்டியை வைக்கவும்",
          "te": "దశ 2: బొడ్డు పైభాగంలో పిడికిలిని ఉంచండి",
          "ml": "ഘട്ടം 2: പൊക്കിളിന് തൊട്ട് മുകളിൽ മുഷ്ടി വെക്കുക",
        },
        "action": {
          "en": "Stand behind the person. Place the thumb side of your fist right above their navel (belly button).",
          "kn": "ವ್ಯಕ್ತಿಯ ಹಿಂದೆ ನಿಂತುಕೊಳ್ಳಿ. ಹೊಕ್ಕುಳಿನ ಸರಿಯಾಗಿ ಮೇಲ್ಭಾಗದಲ್ಲಿ ನಿಮ್ಮ ಮುಷ್ಟಿಯ ಹೆಬ್ಬೆರಳಿನ ಬದಿಯನ್ನು ಇರಿಸಿ.",
          "hi": "व्यक्ति के पीछे खड़े हों। नाभि के ठीक ऊपर अंगूठे की तरफ से मुट्ठी रखें।",
          "ta": "நபரின் பின்னால் நின்று, தொப்புளுக்கு சற்று மேலே முஷ்டியை வைக்கவும்.",
          "te": "వ్యక్తి వెనుక నిలబడి, బొడ్డుకు కొద్దిగా పైభాగంలో పిడికిలిని ఉంచండి.",
          "ml": "വ്യക്തിയുടെ പിന്നിൽ നിന്ന് പൊക്കിളിന് തൊട്ട് മുകളിലായി മുഷ്ടി വെക്കുക.",
        },
        "desc": {
          "en": "Stay below the ribcage to avoid fracturing ribs while maximizing diaphragm pressure.",
          "kn": "ಪಕ್ಕೆಲಬುಗಳಿಗೆ ಪೆಟ್ಟಾಗದಂತೆ ಹೊಟ್ಟೆಯ ಮೃದು ಭಾಗದಲ್ಲೇ ಮುಷ್ಟಿ ಇರಿಸಿ.",
          "hi": "पसलियों से नीचे रखें ताकि डायाफ्राम पर दबाव बने।",
          "ta": "விலா எலும்புகளுக்கு கீழே வைக்கவும்.",
          "te": "పక్కటెముకల కింద ఉంచండి.",
          "ml": "വാരിയെല്ലിന് താഴെയായി വെയ്ക്കുക.",
        }
      },
      {
        "title": {
          "en": "Step 3: Sharp Inward & Upward Abdominal Thrusts",
          "kn": "ಹಂತ 3: ಒಳಮುಖ & ಮೇಲ್ಮುಖವಾಗಿ ತೀವ್ರವಾಗಿ ಒತ್ತಿರಿ",
          "hi": "चरण 3: तेजी से अंदर और ऊपर की ओर झटका दें",
          "ta": "படி 3: உள்நோக்கியும் மேல்நோக்கியும் பலமாக அழுத்தவும்",
          "te": "దశ 3: లోపలికి మరియు పైకి వేగంగా లాగండి",
          "ml": "ഘട്ടം 3: ഉള്ളിലേക്കും മുകളിലേക്കും ശക്തിയായി തള്ളുക",
        },
        "action": {
          "en": "Grasp your fist with other hand and pull sharply inward and upward into the abdomen 5 times.",
          "kn": "ಇನ್ನೊಂದು ಕೈಯಿಂದ ಮುಷ್ಟಿಯನ್ನು ಹಿಡಿದು ಒಳಗೆ ಮತ್ತು ಮೇಲ್ಮುಖವಾಗಿ 5 ಬಾರಿ ತೀವ್ರವಾಗಿ ಜಗ್ಗಿರಿ.",
          "hi": "दूसरे हाथ से मुट्ठी को पकड़ें और अंदर तथा ऊपर की ओर 5 बार तेजी से झटका दें।",
          "ta": "மற்றொரு கையால் முஷ்டியைப் பிடித்து உள்நோக்கியும் மேல்நோக்கியும் 5 முறை இழுக்கவும்.",
          "te": "మరో చేత్తో పిడికిలిని పట్టుకుని లోపలికి పైకి 5 సార్లు బలంగా లాగండి.",
          "ml": "മറ്റേ കൈകൊണ്ട് മുഷ്ടി പിടിച്ച് ഉള്ളിലേക്കും മുകളിലേക്കും 5 തവണ ശക്തിയായി വലിക്കുക.",
        },
        "desc": {
          "en": "Repeat cycles of 5 back blows and 5 abdominal thrusts until object pops out or victim breathes.",
          "kn": "ವಸ್ತು ಹೊರಬರುವವರೆಗೆ 5 ಬಾರಿ ಬೆನ್ನಿಗೆ ತಟ್ಟುವುದು ಮತ್ತು 5 ಬಾರಿ ಹೊಟ್ಟೆ ಒತ್ತುವುದನ್ನು ಮುಂದುವರಿಸಿ.",
          "hi": "जब तक वस्तु बाहर न आए, 5 बार पीठ थपथपाएं और 5 बार पेट दबाएं।",
          "ta": "பொருள் வெளியேறும் வரை 5 முறை முதுகிலும் 5 முறை வயிற்றிலும் தொடரவும்.",
          "te": "పదార్థం బయటకు వచ్చేవరకు 5 సార్లు వెనుక కొట్టడం, 5 సార్లు పొట్ట నొక్కడం చేయండి.",
          "ml": "തടസ്സം മാറുന്നത് വരെ 5 തവണ മുതുകിൽ തട്ടുകയും 5 തവണ വയറ്റിൽ അമർത്തുകയും ചെയ്യുക.",
        }
      }
    ],
    "SPINAL_CAUTION": [
      {
        "title": {
          "en": "Step 1: STRICT PROTOCOL - DO NOT MOVE PERSON OR REMOVE HELMET",
          "kn": "ಹಂತ 1: ಕಟ್ಟುನಿಟ್ಟಿನ ನಿಯಮ - ವ್ಯಕ್ತಿಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ & ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ",
          "hi": "चरण 1: सख्त नियम - व्यक्ति को न हिलाएं और हेलमेट न उतारें",
          "ta": "படி 1: கடுமையான விதி - நபரை அசைக்கவோ ஹெல்மெட்டை கழற்றவோ கூடாது",
          "te": "దశ 1: కఠిన నిబంధన - వ్యక్తిని కదిలించవద్దు & హెల్మెట్ తీయవద్దు",
          "ml": "ഘട്ടം 1: കർശന നിർദ്ദേശം - വ്യക്തിയെ അനക്കുകയോ ഹെൽമെറ്റ് മാറ്റുകയോ ചെയ്യരുത്",
        },
        "action": {
          "en": "Moving an accident victim with potential cervical damage can cause instant, permanent paralysis.",
          "kn": "ಅಪಘಾತಕ್ಕೊಳಗಾದ ವ್ಯಕ್ತಿಯ ಕುತ್ತಿಗೆಯನ್ನು ಅಲುಗಾಡಿಸಿದರೆ ಬೆನ್ನುಹುರಿ ಮುರಿದು ಶಾಶ್ವತ ಪಾರ್ಶ್ವವಾಯು ಉಂಟಾಗಬಹುದು.",
          "hi": "गर्दन हिलने से रीढ़ की हड्डी टूट सकती है और व्यक्ति हमेशा के लिए लकवाग्रस्त हो सकता है।",
          "ta": "கழுத்தை அசைத்தால் தண்டுவடம் பாதிக்கப்பட்டு நிரந்தர பக்கவாதம் ஏற்படலாம்.",
          "te": "మెడ కదిలిస్తే వెన్నుపాము దెబ్బతిని శాశ్వత పక్షవాతం రావచ్చు.",
          "ml": "കഴുത്ത് അനങ്ങിയാൽ സുഷുമ്നാ നാഡിക്ക് ക്ഷതമേറ്റ് തളർവാതം വരാം.",
        },
        "desc": {
          "en": "Leave the helmet on; only trained emergency dispatchers with cervical collars should remove it.",
          "kn": "ಹೆಲ್ಮೆಟ್ ಹಾಗೆಯೇ ಇರಲಿ; ವೈದ್ಯಕೀಯ ಸಿಬ್ಬಂದಿ ಬರುವವರೆಗೂ ತೆಗೆಯಲು ಪ್ರಯತ್ನಿಸಬೇಡಿ.",
          "hi": "हेलमेट लगा रहने दें; केवल पैरामेडिक्स ही इसे सही तरीके से निकाल सकते हैं।",
          "ta": "ஹெல்மெட்டை கழற்ற வேண்டாம்; மருத்துவக் குழுவினர் வரும் வரை காத்திருக்கவும்.",
          "te": "హెల్మెట్ తీయకండి; అత్యవసర సిబ్బంది వచ్చేవరకు ఆగండి.",
          "ml": "ഹെൽമെറ്റ് മാറ്റരുത്; ആംബുലൻസ് സംഘം വരുന്നത് വരെ കാത്തിരിക്കുക.",
        }
      },
      {
        "title": {
          "en": "Step 2: Manual Head In-Line Stabilization",
          "kn": "ಹಂತ 2: ಎರಡೂ ಕೈಗಳಿಂದ ತಲೆಯನ್ನು ಅಲುಗಾಡದಂತೆ ಹಿಡಿಯಿರಿ",
          "hi": "चरण 2: दोनों हाथों से सिर को स्थिर थामे रखें",
          "ta": "படி 2: தலையை இரு கைகளாலும் அசையாமல் பிடித்துக் கொள்ளவும்",
          "te": "దశ 2: రెండు చేతులతో తలను కదలకుండా పట్టుకోండి",
          "ml": "ഘട്ടം 2: രണ്ട് കൈകൾ കൊണ്ടും തല അനങ്ങാതെ പിടിക്കുക",
        },
        "action": {
          "en": "Kneel at the top of victim's head. Place hands firmly on both sides of head/helmet to freeze movement.",
          "kn": "ವ್ಯಕ್ತಿಯ ತಲೆಯ ಬಳಿ ಕುಳಿತು, ತಲೆ ಅಥವಾ ಹೆಲ್ಮೆಟ್‌ನ ಎರಡೂ ಬದಿಗಳಲ್ಲಿ ಕೈಯಿಟ್ಟು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ಭದ್ರವಾಗಿ ಹಿಡಿಯಿರಿ.",
          "hi": "सिर के पीछे बैठें। दोनों हाथों से सिर या हेलमेट को दोनों तरफ से पकड़कर स्थिर रखें।",
          "ta": "தலையின் அருகே அமர்ந்து, தலை அல்லது ஹெல்மெட்டின் இருபுறமும் கைகளை வைத்து அசைக்காமல் பிடிக்கவும்.",
          "te": "తల వెనుక కూర్చుని, రెండు చేతులతో హెల్మెట్ లేదా తలను కదలకుండా పట్టుకోండి.",
          "ml": "തലയ്ക്ക് സമീപം ഇരുന്ന് രണ്ട് കൈകൾ കൊണ്ടും തലയോ ഹെൽമെറ്റോ അനങ്ങാതെ ഉറപ്പിച്ചു പിടിക്കുക.",
        },
        "desc": {
          "en": "Reassure them with a calm voice: 'Help is on the way, keep your head completely still'.",
          "kn": "ಅವರಿಗೆ ಧೈರ್ಯ ತುಂಬಿ: 'ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುತ್ತಿದೆ, ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ತಲೆ ಅಲುಗಾಡಿಸಬೇಡಿ'.",
          "hi": "शांत स्वर में कहें: 'मदद आ रही है, अपना सिर बिल्कुल न हिलाएं'।",
          "ta": "அமைதியாக தைரியம் கூறுங்கள்: 'உதவி வருகிறது, தலையை அசைக்காதீர்கள்'.",
          "te": "ధైర్యం చెప్పండి: 'అంబులెన్స్ వస్తోంది, తల కదల్చకండి'.",
          "ml": "ധൈര്യം നൽകുക: 'ആംബുലൻസ് വരുന്നുണ്ട്, തല അനക്കരുത്'.",
        }
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _metronomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrent();
    });
  }

  void _speakCurrent() {
    final protocol = _localizedProtocols[widget.protocolKey] ?? _localizedProtocols["CPR"]!;
    final step = protocol[_currentStepIndex];

    String lang = widget.language;
    String titleText = step["title"]?[lang] ?? step["title"]?["en"] ?? "";
    String actionText = step["action"]?[lang] ?? step["action"]?["en"] ?? "";
    String fullSentence = "$titleText. $actionText";

    if (kIsWeb) {
      String encoded = Uri.encodeComponent(fullSentence);
      String url = "http://localhost:8000/api/tts?text=$encoded&lang=$lang";
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) {
          window.rapidAidAudio.pause();
          window.rapidAidAudio.currentTime = 0;
        }
        window.rapidAidAudio = new Audio('$url');
        window.rapidAidAudio.play().catch(function(err){ console.log(err); });
      """]);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) {
          window.rapidAidAudio.pause();
          window.rapidAidAudio.currentTime = 0;
        }
      """]);
    }
    _metronomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final protocol = _localizedProtocols[widget.protocolKey] ?? _localizedProtocols["CPR"]!;
    final step = protocol[_currentStepIndex];
    final bool isCpr = widget.protocolKey == "CPR";

    String lang = widget.language;
    String title = step["title"]?[lang] ?? step["title"]?["en"] ?? "";
    String action = step["action"]?[lang] ?? step["action"]?["en"] ?? "";
    String desc = step["desc"]?[lang] ?? step["desc"]?["en"] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text("Rescue: ${widget.protocolKey}"),
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
            tooltip: "Repeat Voice Instruction",
            onPressed: _speakCurrent,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStepIndex > 0
                    ? () {
                        setState(() => _currentStepIndex--);
                        _speakCurrent();
                      }
                    : null,
                child: const Text("Previous Step"),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${_currentStepIndex + 1} / ${protocol.length}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B),
                  foregroundColor: Colors.white,
                ),
                onPressed: _currentStepIndex < protocol.length - 1
                    ? () {
                        setState(() => _currentStepIndex++);
                        _speakCurrent();
                      }
                    : null,
                child: const Text("Next Step"),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isCpr && _currentStepIndex == 3)
              ScaleTransition(
                scale: Tween(begin: 0.98, end: 1.02).animate(_metronomeController),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB91C1C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "METRONOME: 110 COMPRESSIONS / MINUTE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: CustomPaint(
                painter: DedicatedEmergencyPainter(
                  protocolKey: widget.protocolKey,
                  stepIndex: _currentStepIndex,
                  pulseValue: _metronomeController.value,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "STEP ${_currentStepIndex + 1} OF ${protocol.length}",
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF991B1B), height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DedicatedEmergencyPainter extends CustomPainter {
  final String protocolKey;
  final int stepIndex;
  final double pulseValue;

  DedicatedEmergencyPainter({
    required this.protocolKey,
    required this.stepIndex,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final darkGrey = Paint()..color = const Color(0xFF5A6065)..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF2C3236)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final purpleArm = Paint()..color = const Color(0xFF8B5CF6)..style = PaintingStyle.fill;
    final darkPurple = Paint()..color = const Color(0xFF4C1D95)..style = PaintingStyle.fill;
    final redAccent = Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.fill;
    final bloodRed = Paint()..color = const Color(0xFFB91C1C)..style = PaintingStyle.fill;

    if (protocolKey == "BLEEDING") {
      _paintBleedingProtocol(canvas, center, outlinePaint, bloodRed, darkGrey);
    } else if (protocolKey == "CHOKING") {
      _paintChokingProtocol(canvas, center, outlinePaint, purpleArm, darkPurple, redAccent);
    } else if (protocolKey == "SPINAL_CAUTION") {
      _paintSpinalProtocol(canvas, center, outlinePaint, darkGrey, redAccent);
    } else {
      _paintCprProtocol(canvas, center, outlinePaint, darkGrey, purpleArm, darkPurple, redAccent);
    }
  }

  void _paintCprProtocol(Canvas canvas, Offset center, Paint outline, Paint grey, Paint purple, Paint darkPurple, Paint red) {
    switch (stepIndex) {
      case 0:
        _drawRibcageAndSternumTarget(canvas, center, outline);
        final arm1 = Path()
          ..moveTo(center.dx - 85, center.dy - 65)
          ..lineTo(center.dx - 55, center.dy - 80)
          ..lineTo(center.dx - 2, center.dy - 5)
          ..lineTo(center.dx - 25, center.dy + 15)
          ..close();
        canvas.drawPath(arm1, purple);
        canvas.drawPath(arm1, outline);

        canvas.drawCircle(Offset(center.dx, center.dy + 10), 18, purple);
        canvas.drawCircle(Offset(center.dx, center.dy + 10), 18, outline);
        _drawFingers(canvas, Offset(center.dx, center.dy + 10), purple, outline);
        break;

      case 1:
        _drawRibcageAndSternumTarget(canvas, center, outline);
        final arm1 = Path()
          ..moveTo(center.dx - 85, center.dy - 65)
          ..lineTo(center.dx - 55, center.dy - 80)
          ..lineTo(center.dx - 2, center.dy - 5)
          ..lineTo(center.dx - 25, center.dy + 15)
          ..close();
        canvas.drawPath(arm1, purple);
        canvas.drawPath(arm1, outline);

        final arm2 = Path()
          ..moveTo(center.dx + 80, center.dy - 65)
          ..lineTo(center.dx + 50, center.dy - 80)
          ..lineTo(center.dx - 8, center.dy - 5)
          ..lineTo(center.dx + 15, center.dy + 15)
          ..close();
        canvas.drawPath(arm2, darkPurple);
        canvas.drawPath(arm2, outline);

        canvas.drawCircle(Offset(center.dx, center.dy + 10), 20, darkPurple);
        canvas.drawCircle(Offset(center.dx, center.dy + 10), 20, outline);
        _drawFingers(canvas, Offset(center.dx, center.dy + 10), darkPurple, outline);
        break;

      case 2:
        _drawKneelingRescuer(canvas, center, outline, grey, purple, compressionOffset: 0);
        final dashPaint = Paint()
          ..color = Colors.blue.shade700
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(center.dx - 30, center.dy - 50), Offset(center.dx - 30, center.dy + 35), dashPaint);
        break;

      case 3:
        double comp = pulseValue * 14.0;
        _drawKneelingRescuer(canvas, center, outline, grey, purple, compressionOffset: comp);
        final arrow = Path()
          ..moveTo(center.dx - 85, center.dy - 15 + comp)
          ..lineTo(center.dx - 85, center.dy + 12 + comp)
          ..lineTo(center.dx - 95, center.dy + 12 + comp)
          ..lineTo(center.dx - 80, center.dy + 28 + comp)
          ..lineTo(center.dx - 65, center.dy + 12 + comp)
          ..lineTo(center.dx - 75, center.dy + 12 + comp)
          ..lineTo(center.dx - 75, center.dy - 15 + comp)
          ..close();
        canvas.drawPath(arrow, red);
        break;

      default:
        _drawAmbulance(canvas, center, outline);
        break;
    }
  }

  void _paintBleedingProtocol(Canvas canvas, Offset center, Paint outline, Paint bloodRed, Paint grey) {
    if (stepIndex == 0) {
      _drawBleedingLimbWithDirectPressure(canvas, center, outline, bloodRed);
    } else if (stepIndex == 1) {
      _drawLayeredPressureWrap(canvas, center, outline, bloodRed);
    } else {
      _drawElevatedLimb(canvas, center, outline);
    }
  }

  void _paintChokingProtocol(Canvas canvas, Offset center, Paint outline, Paint purple, Paint darkPurple, Paint red) {
    if (stepIndex == 0) {
      _drawBackBlowsBetweenScapulae(canvas, center, outline, purple, red);
    } else if (stepIndex == 1) {
      _drawHeimlichNavelFistPlacement(canvas, center, outline, darkPurple);
    } else {
      _drawHeimlichUpwardThrusts(canvas, center, outline, darkPurple, red);
    }
  }

  void _paintSpinalProtocol(Canvas canvas, Offset center, Paint outline, Paint grey, Paint red) {
    if (stepIndex == 0) {
      _drawHelmetSpinalLock(canvas, center, outline, red);
    } else {
      _drawTwoHandHeadStabilization(canvas, center, outline, grey);
    }
  }

  void _drawRibcageAndSternumTarget(Canvas canvas, Offset center, Paint outline) {
    canvas.drawCircle(Offset(center.dx, center.dy - 60), 26, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx, center.dy - 60), 26, outline);

    final torso = Path()
      ..moveTo(center.dx - 65, center.dy + 75)
      ..lineTo(center.dx - 50, center.dy - 10)
      ..quadraticBezierTo(center.dx - 30, center.dy - 30, center.dx - 12, center.dy - 30)
      ..lineTo(center.dx + 12, center.dy - 30)
      ..quadraticBezierTo(center.dx + 30, center.dy - 30, center.dx + 50, center.dy - 10)
      ..lineTo(center.dx + 65, center.dy + 75)
      ..close();
    canvas.drawPath(torso, Paint()..color = Colors.white);
    canvas.drawPath(torso, outline);

    final redTarget = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(center.dx, center.dy + 10), 16, redTarget);
    canvas.drawLine(Offset(center.dx - 22, center.dy + 10), Offset(center.dx + 22, center.dy + 10), redTarget);
    canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy + 32), redTarget);
  }

  void _drawBleedingLimbWithDirectPressure(Canvas canvas, Offset center, Paint outline, Paint bloodRed) {
    final limb = Path()
      ..moveTo(center.dx - 90, center.dy + 20)
      ..lineTo(center.dx + 90, center.dy + 20)
      ..lineTo(center.dx + 90, center.dy - 20)
      ..lineTo(center.dx - 90, center.dy - 20)
      ..close();
    canvas.drawPath(limb, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawPath(limb, outline);

    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy), width: 36, height: 14), bloodRed);

    final pad = Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 70, height: 26);
    canvas.drawRRect(RRect.fromRectAndRadius(pad, const Radius.circular(6)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(pad, const Radius.circular(6)), outline);

    canvas.drawCircle(Offset(center.dx, center.dy - 35), 24, Paint()..color = Colors.purple.shade700);
    final arrow = Path()
      ..moveTo(center.dx, center.dy - 75)
      ..lineTo(center.dx, center.dy - 48)
      ..lineTo(center.dx - 10, center.dy - 48)
      ..lineTo(center.dx, center.dy - 34)
      ..lineTo(center.dx + 10, center.dy - 48)
      ..lineTo(center.dx, center.dy - 48)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.red.shade700);
  }

  void _drawLayeredPressureWrap(Canvas canvas, Offset center, Paint outline, Paint bloodRed) {
    final limb = Rect.fromCenter(center: center, width: 180, height: 42);
    canvas.drawRect(limb, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawRect(limb, outline);

    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(center.dx + (i * 22) - 10, center.dy - 21),
        Offset(center.dx + (i * 22) + 10, center.dy + 21),
        Paint()..color = Colors.white..strokeWidth = 14..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(center.dx + (i * 22) - 10, center.dy - 21),
        Offset(center.dx + (i * 22) + 10, center.dy + 21),
        outline,
      );
    }
  }

  void _drawElevatedLimb(Canvas canvas, Offset center, Paint outline) {
    canvas.drawCircle(Offset(center.dx - 70, center.dy + 40), 20, outline);
    canvas.drawLine(Offset(center.dx - 50, center.dy + 40), Offset(center.dx + 40, center.dy + 40), outline);
    final arm = Path()
      ..moveTo(center.dx - 20, center.dy + 35)
      ..lineTo(center.dx + 50, center.dy - 55)
      ..lineTo(center.dx + 65, center.dy - 45)
      ..lineTo(center.dx - 5, center.dy + 45)
      ..close();
    canvas.drawPath(arm, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawPath(arm, outline);

    final greenDashed = Paint()
      ..color = Colors.green.shade800
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 60, center.dy + 15), Offset(center.dx + 80, center.dy + 15), greenDashed);
  }

  void _drawBackBlowsBetweenScapulae(Canvas canvas, Offset center, Paint outline, Paint purple, Paint red) {
    final back = Path()
      ..moveTo(center.dx - 60, center.dy + 50)
      ..lineTo(center.dx - 20, center.dy - 20)
      ..lineTo(center.dx + 40, center.dy - 10)
      ..lineTo(center.dx + 20, center.dy + 50)
      ..close();
    canvas.drawPath(back, Paint()..color = Colors.white);
    canvas.drawPath(back, outline);

    canvas.drawCircle(Offset(center.dx, center.dy), 18, Paint()..color = Colors.red.shade100);
    canvas.drawCircle(Offset(center.dx, center.dy), 18, Paint()..color = Colors.red.shade700..style = PaintingStyle.stroke..strokeWidth = 2);

    canvas.drawCircle(Offset(center.dx - 30, center.dy - 10), 20, purple);
    canvas.drawCircle(Offset(center.dx - 30, center.dy - 10), 20, outline);

    final arrow = Path()
      ..moveTo(center.dx - 55, center.dy - 10)
      ..lineTo(center.dx - 15, center.dy - 10)
      ..lineTo(center.dx - 15, center.dy - 18)
      ..lineTo(center.dx, center.dy - 10)
      ..lineTo(center.dx - 15, center.dy - 2)
      ..lineTo(center.dx - 15, center.dy - 10)
      ..close();
    canvas.drawPath(arrow, red);
  }

  void _drawHeimlichNavelFistPlacement(Canvas canvas, Offset center, Paint outline, Paint darkPurple) {
    final belly = Rect.fromCenter(center: center, width: 90, height: 110);
    canvas.drawRRect(RRect.fromRectAndRadius(belly, const Radius.circular(16)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(belly, const Radius.circular(16)), outline);

    canvas.drawCircle(Offset(center.dx, center.dy + 25), 6, Paint()..color = Colors.black87);

    final fist = Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 44, height: 32);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), darkPurple);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), outline);
  }

  void _drawHeimlichUpwardThrusts(Canvas canvas, Offset center, Paint outline, Paint darkPurple, Paint red) {
    final fist = Rect.fromCenter(center: Offset(center.dx, center.dy), width: 55, height: 36);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), darkPurple);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), outline);

    final arrow = Path()
      ..moveTo(center.dx, center.dy + 45)
      ..lineTo(center.dx, center.dy - 40)
      ..lineTo(center.dx - 16, center.dy - 40)
      ..lineTo(center.dx, center.dy - 65)
      ..lineTo(center.dx + 16, center.dy - 40)
      ..lineTo(center.dx, center.dy - 40)
      ..close();
    canvas.drawPath(arrow, red);
  }

  void _drawHelmetSpinalLock(Canvas canvas, Offset center, Paint outline, Paint red) {
    final helmet = Path()
      ..addOval(Rect.fromCenter(center: center, width: 85, height: 95));
    canvas.drawPath(helmet, Paint()..color = Colors.grey.shade800);
    canvas.drawPath(helmet, outline);

    final visor = Rect.fromLTWH(center.dx - 30, center.dy - 20, 60, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(visor, const Radius.circular(6)), Paint()..color = Colors.lightBlue.shade200);

    final crossPaint = Paint()..color = red.color..strokeWidth = 6.0..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 45, center.dy - 45), Offset(center.dx + 45, center.dy + 45), crossPaint);
    canvas.drawLine(Offset(center.dx + 45, center.dy - 45), Offset(center.dx - 45, center.dy + 45), crossPaint);
  }

  void _drawTwoHandHeadStabilization(Canvas canvas, Offset center, Paint outline, Paint grey) {
    canvas.drawCircle(center, 34, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(center, 34, outline);

    final leftHand = Rect.fromLTWH(center.dx - 60, center.dy - 25, 20, 50);
    canvas.drawRRect(RRect.fromRectAndRadius(leftHand, const Radius.circular(8)), grey);
    canvas.drawRRect(RRect.fromRectAndRadius(leftHand, const Radius.circular(8)), outline);

    final rightHand = Rect.fromLTWH(center.dx + 40, center.dy - 25, 20, 50);
    canvas.drawRRect(RRect.fromRectAndRadius(rightHand, const Radius.circular(8)), grey);
    canvas.drawRRect(RRect.fromRectAndRadius(rightHand, const Radius.circular(8)), outline);
  }

  void _drawFingers(Canvas canvas, Offset origin, Paint fill, Paint outline) {
    for (int i = 0; i < 4; i++) {
      double angle = -0.3 + (i * 0.25);
      final finger = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx + (i * 5), origin.dy - 5, 6, 18),
          const Radius.circular(3),
        ));
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      canvas.translate(-origin.dx, -origin.dy);
      canvas.drawPath(finger, fill);
      canvas.drawPath(finger, outline);
      canvas.restore();
    }
  }

  void _drawKneelingRescuer(Canvas canvas, Offset center, Paint outline, Paint grey, Paint purple,
      {required double compressionOffset}) {
    canvas.drawCircle(Offset(center.dx - 80, center.dy + 40), 16, outline);
    final victim = Path()
      ..moveTo(center.dx - 64, center.dy + 40)
      ..quadraticBezierTo(center.dx - 40, center.dy + 25 + compressionOffset, center.dx - 15, center.dy + 40)
      ..lineTo(center.dx - 64, center.dy + 52)
      ..close();
    canvas.drawPath(victim, outline);

    canvas.drawCircle(Offset(center.dx - 30, center.dy - 45 + compressionOffset), 20, grey);

    final body = Path()
      ..moveTo(center.dx - 38, center.dy - 25 + compressionOffset)
      ..lineTo(center.dx - 5, center.dy - 30 + compressionOffset)
      ..lineTo(center.dx + 35, center.dy + 15)
      ..lineTo(center.dx + 35, center.dy + 50)
      ..lineTo(center.dx + 65, center.dy + 50)
      ..lineTo(center.dx + 65, center.dy + 38)
      ..lineTo(center.dx + 48, center.dy + 38)
      ..lineTo(center.dx + 20, center.dy + 10)
      ..lineTo(center.dx - 10, center.dy - 12 + compressionOffset)
      ..close();
    canvas.drawPath(body, grey);

    final arms = Rect.fromLTWH(center.dx - 36, center.dy - 15 + compressionOffset, 20, 55);
    canvas.drawRRect(RRect.fromRectAndRadius(arms, const Radius.circular(6)), purple);
    canvas.drawRRect(RRect.fromRectAndRadius(arms, const Radius.circular(6)), outline);
  }

  void _drawAmbulance(Canvas canvas, Offset center, Paint outline) {
    final whitePaint = Paint()..color = Colors.white;
    final redPaint = Paint()..color = Colors.red.shade700;
    final darkWheel = Paint()..color = const Color(0xFF1E293B);

    final van = Path()
      ..moveTo(center.dx - 80, center.dy + 30)
      ..lineTo(center.dx - 80, center.dy - 35)
      ..lineTo(center.dx + 30, center.dy - 35)
      ..lineTo(center.dx + 52, center.dy - 12)
      ..lineTo(center.dx + 75, center.dy - 12)
      ..lineTo(center.dx + 75, center.dy + 30)
      ..close();
    canvas.drawPath(van, whitePaint);
    canvas.drawPath(van, outline);

    canvas.drawRect(Rect.fromLTWH(center.dx - 80, center.dy + 8, 155, 6), redPaint);
    canvas.drawRect(Rect.fromLTWH(center.dx - 22, center.dy - 22, 6, 20), redPaint);
    canvas.drawRect(Rect.fromLTWH(center.dx - 29, center.dy - 15, 20, 6), redPaint);

    canvas.drawCircle(Offset(center.dx - 45, center.dy + 30), 15, darkWheel);
    canvas.drawCircle(Offset(center.dx + 45, center.dy + 30), 15, darkWheel);
    canvas.drawCircle(Offset(center.dx - 45, center.dy + 30), 6, whitePaint);
    canvas.drawCircle(Offset(center.dx + 45, center.dy + 30), 6, whitePaint);
  }

  @override
  bool shouldRepaint(covariant DedicatedEmergencyPainter oldDelegate) {
    return oldDelegate.protocolKey != protocolKey ||
        oldDelegate.stepIndex != stepIndex ||
        oldDelegate.pulseValue != pulseValue;
  }
}