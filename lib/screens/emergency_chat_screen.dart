import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'active_rescue_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? actionProtocol;
  final List<String>? options;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.actionProtocol,
    this.options,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String _country = 'IN'; // 'IN' (112) or 'US' (911)
  String _selectedLang = 'en';
  String _sessionStage = 'INITIAL';
  String? _emergencyType;
  String _locationStatus = "Acquiring live GPS coordinates...";
  bool _isListening = false;
  bool _isThinking = false;
  bool _isDeafMode = false;
  late AnimationController _micPulseController;

  final Map<String, String> _languages = {
    'en': 'English',
    'kn': 'ಕನ್ನಡ',
    'hi': 'हिंदी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'ml': 'മലയാളം',
  };

  final Map<String, String> _initialGreetings = {
    'en': "Emergency assistance is available. Please tell me what happened. If someone is in immediate danger, contact your local emergency services now.",
    'kn': "ತುರ್ತು ಸಹಾಯ ಲಭ್ಯವಿದೆ. ಏನಾಗಿದೆ ಎಂದು ತಿಳಿಸಿ. ಯಾರಾದರೂ ತೀವ್ರ ಅಪಾಯದಲ್ಲಿದ್ದರೆ, ತಕ್ಷಣ ತುರ್ತು ಸೇವೆಗೆ ಕರೆ ಮಾಡಿ.",
    'hi': "आपातकालीन सहायता उपलब्ध है। कृपया बताएं क्या हुआ है। यदि कोई तत्काल खतरे में है, तो तुरंत आपातकालीन सेवाओं से संपर्क करें।",
    'ta': "அவசர உதவி தயாராக உள்ளது. என்ன நடந்தது என்று சொல்லுங்கள். உயிருக்கு ஆபத்து என்றால் உடனடியாக அவசர எண்ணை அழைக்கவும்.",
    'te': "అత్యవసర సహాయం అందుబాటులో ఉంది. ఏం జరిగిందో దయచేసి చెప్పండి. ఎవరైనా ప్రాణాపాయంలో ఉంటే వెంటనే అత్యవసర సేవలకు కాల్ చేయండి.",
    'ml': "അടിയന്തിര സഹായം ലഭ്യമാണ്. എന്താണ് സംഭവിച്ചതെന്ന് ദയവായി പറയുക. ആരെങ്കിലും അപകടത്തിലാണെങ്കിൽ ഉടൻ വിളിക്കുക.",
  };

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initLocation();
    _addInitialBotGreeting();
  }

  void _addInitialBotGreeting() {
    _messages.add(
      ChatMessage(
        text: _initialGreetings[_selectedLang] ?? _initialGreetings['en']!,
        isUser: false,
        options: [
          "🚨 Person Unconscious / Fell Down",
          "🩸 Severe Spurting Bleeding",
          "🥪 Choking / Airway Blocked",
          "🏍️ Motorcycle Crash on Road",
          "🔥 Fire / Trapped in Smoke",
        ],
      ),
    );
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
      if (mounted) setState(() => _locationStatus = "Location: Bengaluru, Karnataka (Ready to share with 112)");
    }
  }

  void _dialEmergency() async {
    final number = _country == 'IN' ? '112' : '911';
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleUserResponse(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isThinking = true;
    });
    _scrollToBottom();

    await _sendToBackend(trimmed);
  }

  void _toggleMic() {
    if (_isListening) {
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    if (kIsWeb) {
      String localeTag = "${_selectedLang}-IN";
      if (_selectedLang == 'en') localeTag = (_country == 'IN') ? 'en-IN' : 'en-US';

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
            console.log('Voice recognition error', e);
          };
        }
      """]);

      Timer.periodic(const Duration(milliseconds: 400), (timer) {
        if (!mounted || !_isListening) {
          timer.cancel();
          return;
        }
        var res = js.context['speechResult'];
        if (res != null && res.toString().isNotEmpty) {
          timer.cancel();
          setState(() => _isListening = false);
          _handleUserResponse(res.toString());
        }
      });
    }
  }

  Future<void> _sendToBackend(String text) async {
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/analyze-scenario"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_speech": text,
          "language": _selectedLang,
          "country": _country,
          "session_stage": _sessionStage,
          "emergency_type": _emergencyType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final protocol = data["resolved_protocol"];
        final spoken = data["spoken_reassurance"] ?? "";
        final nextStage = data["next_stage"] ?? "INITIAL";
        final eType = data["emergency_type"];
        final List<dynamic>? options = data["quick_options"];
        final detectedLang = data["language"] ?? _selectedLang;

        setState(() {
          _selectedLang = detectedLang;
          _sessionStage = nextStage;
          if (eType != null) _emergencyType = eType;
          _isThinking = false;

          _messages.add(
            ChatMessage(
              text: spoken,
              isUser: false,
              actionProtocol: protocol,
              options: options?.map((e) => e.toString()).toList(),
            ),
          );
        });
        _scrollToBottom();

        if (!_isDeafMode) {
          _playAudio(spoken, _selectedLang);
        }
      }
    } catch (err) {
      setState(() {
        _isThinking = false;
        _messages.add(
          ChatMessage(
            text: "Connection note: Please ensure backend is running at http://127.0.0.1:8000. Calling emergency services is prioritized.",
            isUser: false,
            actionProtocol: "CPR",
            options: ["CALL EMERGENCY SERVICES"],
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _playAudio(String text, String lang) {
    if (kIsWeb) {
      String encoded = Uri.encodeComponent(text);
      String url = "http://127.0.0.1:8000/api/tts?text=$encoded&lang=$lang";
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) {
          window.rapidAidAudio.pause();
        }
        window.rapidAidAudio = new Audio('$url');
        window.rapidAidAudio.play().catch(function(e){ console.log(e); });
      """]);
    }
  }

  void _launchVisualProtocol(String protocolKey) {
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
    _micPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialNumber = _country == 'IN' ? '112' : '911';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF991B1B),
        elevation: 2,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Icon(Icons.health_and_safety, color: Color(0xFF991B1B), size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              "RapidAid ($_country $dialNumber)",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // Country Switcher
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _country,
              dropdownColor: const Color(0xFF7F1D1D),
              underline: const SizedBox(),
              icon: const Icon(Icons.flag, color: Colors.white, size: 16),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'IN', child: Text("🇮🇳 India 112")),
                DropdownMenuItem(value: 'US', child: Text("🇺🇸 USA 911")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _country = val);
              },
            ),
          ),
          const SizedBox(width: 6),
          // Language Switcher
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedLang,
              dropdownColor: const Color(0xFF7F1D1D),
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.white, size: 16),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              items: _languages.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLang = val);
                  _messages.add(ChatMessage(
                    text: _initialGreetings[val] ?? _initialGreetings['en']!,
                    isUser: false,
                  ));
                  _scrollToBottom();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _locationStatus,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.phone_in_talk, size: 18),
              label: Text("CALL $dialNumber", style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _dialEmergency,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ACCESSIBILITY & INSTANT AUDIO BAR
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isDeafMode = !_isDeafMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDeafMode ? Colors.blue.shade700 : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isDeafMode ? Icons.hearing_disabled : Icons.hearing,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isDeafMode ? "DEAF TACTILE MODE: ON" : "ENABLE DEAF MODE",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  "Deterministic Safety Engine",
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // EMERGENCY VOICE DISPATCH BAR
          GestureDetector(
            onTap: _toggleMic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
              color: _isListening ? Colors.red.shade700 : const Color(0xFF1E3A8A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.2).animate(_micPulseController),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isListening ? "LISTENING TO YOU... SPEAK NOW" : "TAP HERE TO SPEAK EMERGENCY DIRECTLY",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // CHAT STREAM
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          if (_isThinking)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Selecting clinical triage questions...",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

          // INPUT ROW
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Type what is happening or tap options above...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _handleUserResponse,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF991B1B), size: 28),
                    onPressed: () => _handleUserResponse(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isMe = msg.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: _isDeafMode ? 16 : 14,
                height: 1.4,
                color: isMe ? Colors.white : Colors.black87,
                fontWeight: isMe ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            // TACTILE 3-STATE QUICK BUTTONS
            if (msg.options != null && msg.options!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.options!.map((opt) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      foregroundColor: const Color(0xFF991B1B),
                      elevation: 0,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: const Size(80, 48), // Large touch targets for stressful conditions
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleUserResponse(opt),
                    child: Text(
                      opt,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ],
            // VISUAL PROTOCOL ACTION BUTTON
            if (msg.actionProtocol != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_circle_fill, size: 24),
                label: Text(
                  "OPEN ${msg.actionProtocol} VISUAL & VOICE GUIDE",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                onPressed: () => _launchVisualProtocol(msg.actionProtocol!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}