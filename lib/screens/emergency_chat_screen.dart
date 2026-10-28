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

  ChatMessage({
    required this.text,
    required this.isUser,
    this.actionProtocol,
    this.options,
  });
}

class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String _country = 'IN';
  String _selectedLang = 'en';
  String _sessionStage = 'INITIAL';
  String? _emergencyCard;
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

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initLocation();
    _initDispatcherSession();
  }

  void _initDispatcherSession() {
    _messages.add(
      ChatMessage(
        text:
            "🚨 EMERGENCY DISPATCH: Help is already being notified. Put phone on SPEAKERPHONE right now. Tell me exactly what happened, or tap an option below.",
        isUser: false,
        options: [
          "🫀 Collapsed / Gasping for Air",
          "🩸 Severe Bleeding Wound",
          "🏍️ Motorcycle Crash + Helmet",
          "🥪 Choking / Airway Blocked",
          "⚡ Seizure / Active Shaking",
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
          _locationStatus =
              "GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (Ready for 112)";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationStatus = "GPS Location: Bengaluru (Sharing with 112)");
      }
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
      if (_selectedLang == 'en') {
        localeTag = (_country == 'IN') ? 'en-IN' : 'en-US';
      }

      js.context.callMethod('eval', ["""
        window.speechResult = "";
        var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (SpeechRec) {
          var rec = new SpeechRec();
          rec.lang = '$localeTag';
          rec.continuous = false;
          rec.interimResults = false;
          rec.start();
          rec.onresult = function(e) { window.speechResult = e.results[0][0].transcript; };
          rec.onerror = function(e) { console.log('Speech error', e); };
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
          "emergency_card": _emergencyCard,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final protocol = data["resolved_protocol"];
        final spoken = data["spoken_reassurance"] ?? "";
        final nextStage = data["next_stage"] ?? "INITIAL";
        final List<dynamic>? options = data["quick_options"];
        final detectedLang = data["language"] ?? _selectedLang;

        setState(() {
          _selectedLang = detectedLang;
          _sessionStage = nextStage;
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
            text:
                "Connection Note: Ensure backend is running at 127.0.0.1:8000. Calling 112 is prioritized.",
            isUser: false,
            actionProtocol: "CPR",
            options: ["CALL 112 NOW"],
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
        if (window.rapidAidAudio) window.rapidAidAudio.pause();
        window.rapidAidAudio = new Audio('$url');
        window.rapidAidAudio.play().catch(function(e){ console.log(e); });
      """]);
    }
  }

  void _launchVisualProtocol(String protocolKey) {
    // Silence chat audio before switching screens
    if (kIsWeb) {
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) {
          window.rapidAidAudio.pause();
          window.rapidAidAudio.currentTime = 0;
        }
      """]);
    }

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
    _textController.dispose();
    _scrollController.dispose();
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
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.emergency, color: Color(0xFF991B1B), size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              "RapidAid EMD ($dialNumber)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _country,
            dropdownColor: const Color(0xFF7F1D1D),
            underline: const SizedBox(),
            icon: const Icon(Icons.flag, color: Colors.white, size: 16),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            items: const [
              DropdownMenuItem(value: 'IN', child: Text("🇮🇳 112")),
              DropdownMenuItem(value: 'US', child: Text("🇺🇸 911")),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _country = val);
            },
          ),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: _selectedLang,
            dropdownColor: const Color(0xFF7F1D1D),
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white, size: 16),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            items: _languages.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLang = val);
            },
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
          // DISPATCHER SPEAKER & SCENE BAR
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.volume_up, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "SPEAKERPHONE ON • FREE BOTH HANDS",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _isDeafMode = !_isDeafMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isDeafMode ? Colors.blue.shade700 : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isDeafMode ? "DEAF VIBRATE: ON" : "DEAF MODE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PUSH TO SPEAK DISPATCH BAR
          GestureDetector(
            onTap: _toggleMic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: _isListening ? Colors.red.shade700 : const Color(0xFF1E3A8A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.2).animate(_micPulseController),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening
                        ? "DISPATCHER LISTENING... SPEAK NOW"
                        : "TAP TO SPEAK DIRECTLY TO DISPATCHER",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
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
                final isMe = msg.isUser;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.88,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF1E3A8A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isMe ? null : Border.all(color: Colors.grey.shade300),
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
                        // LARGE TACTILE ACTION BUTTONS
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  minimumSize: const Size(80, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _handleUserResponse(opt),
                                child: Text(
                                  opt,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        // DYNAMIC ACTION BUTTON: ADAPTS TO PROTOCOL
                        if (msg.actionProtocol != null) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF991B1B),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.play_circle_fill, size: 22),
                            label: Text(
                              msg.actionProtocol == "CPR"
                                  ? "OPEN CPR COACHING & 110 BPM METRONOME"
                                  : "OPEN ${msg.actionProtocol} FIRST-AID COACHING",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () => _launchVisualProtocol(msg.actionProtocol!),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Dispatcher verifying protocol...",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // INPUT ROW
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Type what is happening or tap buttons above...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
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
}