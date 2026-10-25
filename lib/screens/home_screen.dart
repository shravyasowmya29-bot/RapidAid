import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'assessment_screen.dart';
import 'guidance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _selectedLang = 'en'; // 'en', 'kn', 'ta', 'te', 'hi', 'ml'
  String _locationDisplay = "Locating nearby landmark...";
  late AnimationController _sosPulseController;

  @override
  void initState() {
    super.initState();
    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _getAccurateLocation();
  }

  Future<void> _getAccurateLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        if (mounted) {
          setState(() {
            _locationDisplay = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)} (Bengaluru)";
          });
        }
      } else {
        if (mounted) setState(() => _locationDisplay = "Bengaluru Urban (State nearest landmark on call)");
      }
    } catch (_) {
      if (mounted) setState(() => _locationDisplay = "Bengaluru, Karnataka (Read landmark to 112)");
    }
  }

  Future<void> _dialEmergency() async {
    final Uri callUri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  void _openDirectProtocol(String key) {
    final steps = ApiService.getAdaptiveProtocol(
      emergencyType: key,
      isVictimResponsive: key != "CPR",
      isVictimBreathing: key != "CPR",
      isHelperPanicked: false,
      isHelperAlone: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuidanceScreen(
          language: _selectedLang,
          steps: steps,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sosPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, String>> localizedUi = {
      'en': {
        'title': 'RapidAid First-Response',
        'safety': 'First Rule: Verify traffic and scene safety before helping.',
        'analyzeTitle': 'ANALYZE SITUATION',
        'analyzeSubtitle': 'Based on victim & helper response',
        'protocolsHeader': 'Direct Emergency Pathways (1-Tap):',
        'callButton': 'CALL 112 (DIRECT EMERGENCY DISPATCH)',
      },
      'kn': {
        'title': 'ರ್ಯಾಪಿಡ್ ಏಡ್ (RapidAid)',
        'safety': 'ರಸ್ತೆಯಲ್ಲಿ ಮೊದಲು ನಿಮ್ಮ ಸುರಕ್ಷತೆಯನ್ನು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ.',
        'analyzeTitle': 'ಸ್ಥಿತಿ ವಿಶ್ಲೇಷಿಸಿ',
        'analyzeSubtitle': 'ಗಾಯಾಳು & ಸಹಾಯಕನ ಸ್ಥಿತಿಯ ಆಧಾರದ ಮೇಲೆ',
        'protocolsHeader': 'ನೇರ ತುರ್ತು ಪ್ರೋಟೋಕಾಲ್‌ಗಳು (1-ಟ್ಯಾಪ್):',
        'callButton': '112 ತುರ್ತು ಕರೆ ಮಾಡಿ (ನೇರ ಸಂಪರ್ಕ)',
      },
      'ta': {
        'title': 'ரேபிட் எய்ட் (RapidAid)',
        'safety': 'முதலில் உங்கள் பாதுகாப்பை உறுதிப்படுத்திக் கொள்ளுங்கள்.',
        'analyzeTitle': 'நிலையை ஆய்வு செய்',
        'analyzeSubtitle': 'பாதிக்கப்பட்டவர் & உதவியாளர் நிலை அடிப்படையில்',
        'protocolsHeader': 'நேரடி அவசர வழிகாட்டுதல்கள்:',
        'callButton': '112 அவசர அழைப்பு (உடனடி உதவி)',
      },
      'te': {
        'title': 'ర్యాపిడ్ ఎయిడ్ (RapidAid)',
        'safety': 'ముందుగా మీ భద్రతను నిర్ధారించుకోండి.',
        'analyzeTitle': 'పరిస్థితిని విశ్లేషించండి',
        'analyzeSubtitle': 'బాధితుడు & సహాయకుడి స్పందన ఆధారంగా',
        'protocolsHeader': 'నేరుగా అత్యవసర చర్యలు (1-ట్యాప్):',
        'callButton': '112 అత్యవసర కాల్ చేయండి',
      },
      'hi': {
        'title': 'रैपिड एड (RapidAid)',
        'safety': 'प्राथमिक नियम: मदद से पहले अपनी सुरक्षा जांचें।',
        'analyzeTitle': 'स्थिति का विश्लेषण करें',
        'analyzeSubtitle': 'घायल और मददगार की स्थिति के अनुसार',
        'protocolsHeader': 'सीधे आपातकालीन प्रोटोकॉल (1-टैप):',
        'callButton': '112 आपातकालीन कॉल करें',
      },
      'ml': {
        'title': 'റാപ്പിഡ് എയ്ഡ് (RapidAid)',
        'safety': 'ആദ്യം നിങ്ങളുടെ സുരക്ഷ ഉറപ്പാക്കുക.',
        'analyzeTitle': 'സാഹചര്യം പരിശോധിക്കുക',
        'analyzeSubtitle': 'രോഗിയുടെയും സഹായിയുടെയും അവസ്ഥ അനുസരിച്ച്',
        'protocolsHeader': 'അടിയന്തര നടപടികൾ (1-ടാപ്പ്):',
        'callButton': '112 അടിയന്തര കോൾ ചെയ്യുക',
      },
    };

    final currentStrings = localizedUi[_selectedLang] ?? localizedUi['en']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.red[900],
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              currentStrings['title']!,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _selectedLang,
              dropdownColor: Colors.red[900],
              icon: const Icon(Icons.language, color: Colors.white, size: 20),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
                DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                DropdownMenuItem(value: 'te', child: Text('తెలుగు')),
                DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                DropdownMenuItem(value: 'ml', child: Text('മലയാളം')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedLang = val);
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationDisplay,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.call, size: 24),
              label: Text(
                currentStrings['callButton']!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: _dialEmergency,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safety Advisory
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[700]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: Colors.amber[900], size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentStrings['safety']!,
                      style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dual-Perspective Diagnostic Trigger
            ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.02).animate(_sosPulseController),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssessmentScreen(language: _selectedLang),
                    ),
                  );
                },
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.red[700]!, Colors.red[900]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.troubleshoot, color: Colors.white, size: 50),
                      const SizedBox(width: 14),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStrings['analyzeTitle']!,
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            currentStrings['analyzeSubtitle']!,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              currentStrings['protocolsHeader']!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red[700], child: const Icon(Icons.favorite, color: Colors.white)),
                title: const Text('Cardiac Arrest / CPR (110 BPM)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Unresponsive victim & no breathing'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openDirectProtocol("CPR"),
              ),
            ),
            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red[900], child: const Icon(Icons.bloodtype, color: Colors.white)),
                title: const Text('Severe Road Bleeding', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Direct continuous pressure & elevation'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openDirectProtocol("BLEEDING"),
              ),
            ),
            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.deepOrange[800], child: const Icon(Icons.two_wheeler, color: Colors.white)),
                title: const Text('Bike Crash / Spinal Caution', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Do not move! Do not remove helmet!'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openDirectProtocol("SPINAL"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}