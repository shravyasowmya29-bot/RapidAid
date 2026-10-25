import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_model.dart';

class GuidanceScreen extends StatefulWidget {
  final String language;
  final List<EmergencyStep> steps;

  const GuidanceScreen({
    super.key,
    required this.language,
    required this.steps,
  });

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _metronomeController;
  int _currentStepIndex = 0;
  String _confidenceMode = "guide";
  bool _isPlayingVoice = false;
  bool _isBeaconActive = false;

  @override
  void initState() {
    super.initState();
    // 110 BPM Metronome oscillation (545ms)
    _metronomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    )..repeat(reverse: true);

    _speakCurrentInstruction();
  }

  /// Reliable Web Chrome Multilingual Speech Engine
  void _speakText(String text, String lang) {
    if (kIsWeb) {
      try {
        // Direct browser synthesis mapping
        String localeTag = 'en-US';
        switch (lang) {
          case 'kn': localeTag = 'kn-IN'; break;
          case 'hi': localeTag = 'hi-IN'; break;
          case 'ta': localeTag = 'ta-IN'; break;
          case 'te': localeTag = 'te-IN'; break;
          case 'ml': localeTag = 'ml-IN'; break;
          default: localeTag = 'en-US'; break;
        }

        js.context.callMethod('eval', ["""
          window.speechSynthesis.cancel();
          var utter = new SpeechSynthesisUtterance(${js.JsObject.jsify(text)});
          utter.lang = '$localeTag';
          utter.rate = 0.9;
          
          var voices = window.speechSynthesis.getVoices();
          for (var i = 0; i < voices.length; i++) {
            if (voices[i].lang.indexOf('$lang') !== -1 || voices[i].lang.indexOf('$localeTag') !== -1) {
              utter.voice = voices[i];
              break;
            }
          }
          window.speechSynthesis.speak(utter);
        """]);
        setState(() => _isPlayingVoice = true);
        return;
      } catch (_) {}
    }

    // Mobile fallback via flutter_tts
    _flutterTts.setLanguage(lang);
    _flutterTts.speak(text);
  }

  void _speakCurrentInstruction() {
    if (widget.steps.isEmpty) return;
    final step = widget.steps[_currentStepIndex];
    String textToSpeak = _confidenceMode == "know"
        ? step.quickTip.get(widget.language)
        : step.audioPrompt.get(widget.language);

    _speakText(textToSpeak, widget.language);
  }

  Future<void> _dial112() async {
    final Uri callUri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  void _toggleHelperBeacon() {
    setState(() => _isBeaconActive = !_isBeaconActive);
    if (_isBeaconActive) {
      _speakText("Emergency! Help needed immediately! Someone come assist!", widget.language);
    } else {
      if (kIsWeb) {
        js.context.callMethod('eval', ["window.speechSynthesis.cancel();"]);
      }
      _flutterTts.stop();
      _speakCurrentInstruction();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      js.context.callMethod('eval', ["window.speechSynthesis.cancel();"]);
    }
    _flutterTts.stop();
    _metronomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.red[900]),
        body: const Center(child: Text("No protocol steps found.")),
      );
    }

    final step = widget.steps[_currentStepIndex];

    if (_isBeaconActive) {
      return Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.25).animate(_metronomeController),
                  child: const Icon(Icons.campaign, size: 130, color: Colors.amberAccent),
                ),
                const SizedBox(height: 24),
                const Text(
                  "HELP NEEDED HERE!",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "MEDICAL EMERGENCY IN PROGRESS\nPLEASE ASSIST THIS RESCUER",
                  style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("RETURN TO RESCUE STEPS", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _toggleHelperBeacon,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        title: Text(
          "Step ${_currentStepIndex + 1} of ${widget.steps.length}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPlayingVoice ? Icons.volume_up : Icons.volume_off),
            tooltip: "Repeat Voice Prompt",
            onPressed: () {
              _speakCurrentInstruction();
            },
          ),
          IconButton(
            icon: const Icon(Icons.campaign, color: Colors.amberAccent),
            tooltip: "Find A Helper",
            onPressed: _toggleHelperBeacon,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.call, size: 26),
          label: const Text(
            'DIAL 112 (SPEAK TO DISPATCHER)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _dial112,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selectors
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Summary')),
                    selected: _confidenceMode == "know",
                    selectedColor: Colors.green[600],
                    labelStyle: TextStyle(
                      color: _confidenceMode == "know" ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() => _confidenceMode = "know");
                      _speakCurrentInstruction();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Detailed Guide')),
                    selected: _confidenceMode == "guide",
                    selectedColor: Colors.blue[700],
                    labelStyle: TextStyle(
                      color: _confidenceMode == "guide" ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() => _confidenceMode = "guide");
                      _speakCurrentInstruction();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  tooltip: "Cannot Perform (Call Helper)",
                  onPressed: _toggleHelperBeacon,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metronome Indicator
            if (step.hasMetronome)
              ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.03).animate(_metronomeController),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "METRONOME: 110 COMPRESSIONS / MIN",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Main Graphic Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Step Title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Text(
                        step.title.get(widget.language),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom-painted procedural diagram matching your poster
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFBFE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: CustomPaint(
                        painter: CprPosterIllustrationPainter(
                          stepIndex: _currentStepIndex,
                          pulseValue: _metronomeController.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Primary Instruction Text
                    Text(
                      step.quickTip.get(widget.language),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Detailed Instructions
                    if (_confidenceMode != "know")
                      Text(
                        step.detailed.get(widget.language),
                        style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.3),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Manual Step Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentStepIndex > 0
                      ? () {
                          setState(() => _currentStepIndex--);
                          _speakCurrentInstruction();
                        }
                      : null,
                  child: const Text('Previous Step'),
                ),
                Text(
                  '${_currentStepIndex + 1} / ${widget.steps.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _currentStepIndex < widget.steps.length - 1
                      ? () {
                          setState(() => _currentStepIndex++);
                          _speakCurrentInstruction();
                        }
                      : null,
                  child: const Text('Next Step'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Canvas Painter that reproduces the Avive reference poster style
class CprPosterIllustrationPainter extends CustomPainter {
  final int stepIndex;
  final double pulseValue;

  CprPosterIllustrationPainter({required this.stepIndex, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final darkGrey = Paint()..color = const Color(0xFF5A6065)..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF2C3236)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final purpleArm = Paint()..color = const Color(0xFF8B5CF6)..style = PaintingStyle.fill;
    final darkPurple = Paint()..color = const Color(0xFF581C87)..style = PaintingStyle.fill;
    final redAccent = Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.fill;

    switch (stepIndex) {
      case 0: // Step 1: Woman chest outline with one purple arm pressing center
        _drawPatientOutline(canvas, center, outlinePaint);
        // Purple arm coming diagonally from left to center
        final armPath = Path()
          ..moveTo(center.dx - 80, center.dy - 60)
          ..lineTo(center.dx - 55, center.dy - 75)
          ..lineTo(center.dx + 5, center.dy + 5)
          ..lineTo(center.dx - 20, center.dy + 20)
          ..close();
        canvas.drawPath(armPath, purpleArm);
        canvas.drawPath(armPath, outlinePaint);
        // Palm on sternum
        canvas.drawCircle(Offset(center.dx - 5, center.dy + 10), 18, purpleArm);
        canvas.drawCircle(Offset(center.dx - 5, center.dy + 10), 18, outlinePaint);
        break;

      case 1: // Step 2: Patient with second purple hand interlacing over first
        _drawPatientOutline(canvas, center, outlinePaint);
        // Arm 1 (Light purple)
        final arm1 = Path()
          ..moveTo(center.dx - 80, center.dy - 60)
          ..lineTo(center.dx - 55, center.dy - 75)
          ..lineTo(center.dx + 5, center.dy + 5)
          ..lineTo(center.dx - 20, center.dy + 20)
          ..close();
        canvas.drawPath(arm1, purpleArm);
        canvas.drawPath(arm1, outlinePaint);

        // Arm 2 (Dark purple overlapping from opposite side)
        final arm2 = Path()
          ..moveTo(center.dx + 70, center.dy - 60)
          ..lineTo(center.dx + 45, center.dy - 75)
          ..lineTo(center.dx - 15, center.dy + 5)
          ..lineTo(center.dx + 10, center.dy + 20)
          ..close();
        canvas.drawPath(arm2, darkPurple);
        canvas.drawPath(arm2, outlinePaint);
        break;

      case 2: // Step 3: Rescuer kneeling beside patient, vertical straight arms
        _drawKneelingRescuer(canvas, center, outlinePaint, darkGrey, purpleArm, compressionOffset: 0);
        break;

      case 3: // Step 4: Rescuer pushing down 2 inches with red arrows and chest compression
        double comp = pulseValue * 12.0;
        _drawKneelingRescuer(canvas, center, outlinePaint, darkGrey, purpleArm, compressionOffset: comp);
        // Red downward compression arrow
        final arrowPath = Path()
          ..moveTo(center.dx - 80, center.dy - 20 + comp)
          ..lineTo(center.dx - 80, center.dy + 10 + comp)
          ..lineTo(center.dx - 90, center.dy + 10 + comp)
          ..lineTo(center.dx - 75, center.dy + 26 + comp)
          ..lineTo(center.dx - 60, center.dy + 10 + comp)
          ..lineTo(center.dx - 70, center.dy + 10 + comp)
          ..lineTo(center.dx - 70, center.dy - 20 + comp)
          ..close();
        canvas.drawPath(arrowPath, redAccent);
        break;

      case 4: // Step 5: Ambulance graphic arriving
        _drawAmbulance(canvas, center, outlinePaint);
        break;

      default: // Step 6: Child protocol - 1 hand
        _drawKneelingRescuer(canvas, center, outlinePaint, darkGrey, purpleArm, compressionOffset: 0, isChild: true);
        break;
    }
  }

  void _drawPatientOutline(Canvas canvas, Offset center, Paint outline) {
    // Head
    canvas.drawCircle(Offset(center.dx, center.dy - 55), 24, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx, center.dy - 55), 24, outline);
    // Torso / Shoulders
    final torso = Path()
      ..moveTo(center.dx - 55, center.dy + 65)
      ..lineTo(center.dx - 45, center.dy - 10)
      ..quadraticBezierTo(center.dx - 25, center.dy - 25, center.dx - 12, center.dy - 25)
      ..lineTo(center.dx + 12, center.dy - 25)
      ..quadraticBezierTo(center.dx + 25, center.dy - 25, center.dx + 45, center.dy - 10)
      ..lineTo(center.dx + 55, center.dy + 65)
      ..close();
    canvas.drawPath(torso, Paint()..color = Colors.white);
    canvas.drawPath(torso, outline);
  }

  void _drawKneelingRescuer(Canvas canvas, Offset center, Paint outline, Paint grey, Paint purple,
      {required double compressionOffset, bool isChild = false}) {
    // Victim lying on floor (head on left)
    canvas.drawCircle(Offset(center.dx - 75, center.dy + 35), 16, outline);
    final victimBody = Path()
      ..moveTo(center.dx - 60, center.dy + 35)
      ..quadraticBezierTo(center.dx - 35, center.dy + 20 + compressionOffset, center.dx - 10, center.dy + 35)
      ..lineTo(center.dx - 60, center.dy + 45)
      ..close();
    canvas.drawPath(victimBody, outline);

    // Rescuer Head
    canvas.drawCircle(Offset(center.dx - 30, center.dy - 40 + compressionOffset), 18, grey);

    // Rescuer Torso & Thighs
    final rescuerBody = Path()
      ..moveTo(center.dx - 35, center.dy - 20 + compressionOffset)
      ..lineTo(center.dx - 5, center.dy - 25 + compressionOffset)
      ..lineTo(center.dx + 30, center.dy + 15) // Back
      ..lineTo(center.dx + 30, center.dy + 45) // Knee on floor
      ..lineTo(center.dx + 55, center.dy + 45) // Legs tucked back
      ..lineTo(center.dx + 55, center.dy + 35)
      ..lineTo(center.dx + 42, center.dy + 35)
      ..lineTo(center.dx + 18, center.dy + 10)
      ..lineTo(center.dx - 10, center.dy - 10 + compressionOffset)
      ..close();
    canvas.drawPath(rescuerBody, grey);

    // Rescuer Vertical Locked Arms
    final arms = Rect.fromLTWH(center.dx - 36, center.dy - 15 + compressionOffset, isChild ? 12 : 18, 52);
    canvas.drawRRect(RRect.fromRectAndRadius(arms, const Radius.circular(6)), purple);
    canvas.drawRRect(RRect.fromRectAndRadius(arms, const Radius.circular(6)), outline);
  }

  void _drawAmbulance(Canvas canvas, Offset center, Paint outline) {
    final whitePaint = Paint()..color = Colors.white;
    final redPaint = Paint()..color = Colors.red[700]!;
    final darkWheel = Paint()..color = const Color(0xFF1E293B);

    // Ambulance Van Body
    final van = Path()
      ..moveTo(center.dx - 75, center.dy + 25)
      ..lineTo(center.dx - 75, center.dy - 35)
      ..lineTo(center.dx + 30, center.dy - 35)
      ..lineTo(center.dx + 48, center.dy - 15)
      ..lineTo(center.dx + 70, center.dy - 15)
      ..lineTo(center.dx + 70, center.dy + 25)
      ..close();
    canvas.drawPath(van, whitePaint);
    canvas.drawPath(van, outline);

    // Red Cross and Stripe
    canvas.drawRect(Rect.fromLTWH(center.dx - 75, center.dy + 5, 145, 6), redPaint);
    canvas.drawRect(Rect.fromLTWH(center.dx - 22, center.dy - 22, 6, 20), redPaint);
    canvas.drawRect(Rect.fromLTWH(center.dx - 29, center.dy - 15, 20, 6), redPaint);

    // Wheels
    canvas.drawCircle(Offset(center.dx - 45, center.dy + 25), 14, darkWheel);
    canvas.drawCircle(Offset(center.dx + 45, center.dy + 25), 14, darkWheel);
    canvas.drawCircle(Offset(center.dx - 45, center.dy + 25), 5, whitePaint);
    canvas.drawCircle(Offset(center.dx + 45, center.dy + 25), 5, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CprPosterIllustrationPainter oldDelegate) {
    return oldDelegate.stepIndex != stepIndex || oldDelegate.pulseValue != pulseValue;
  }
}