import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ActiveRescueScreen extends StatefulWidget {
  final String protocolKey;
  final String language;

  const ActiveRescueScreen({
    super.key,
    required this.protocolKey,
    this.language = 'en',
  });

  @override
  State<ActiveRescueScreen> createState() => _ActiveRescueScreenState();
}

class _ActiveRescueScreenState extends State<ActiveRescueScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Timer? _metronomeTimer;
  Timer? _seizureStopwatch;
  int _seizureSecondsElapsed = 0;
  bool _pulseState = false;
  late AnimationController _animController;

  bool get _isCPR => widget.protocolKey.toUpperCase() == 'CPR';
  bool get _isSeizure => widget.protocolKey.toUpperCase() == 'SEIZURE';
  bool get _isBleeding =>
      widget.protocolKey.toUpperCase().contains('BLEEDING');
  bool get _isHelmet =>
      widget.protocolKey.toUpperCase().contains('HELMET');
  bool get _isChoking => widget.protocolKey.toUpperCase() == 'CHOKING';

  @override
  void initState() {
    super.initState();
    // 1. Immediately silence any leftover audio from the previous chat screen
    _stopAllAudio();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    )..repeat(reverse: true);

    if (_isCPR) {
      _startMetronome();
    } else if (_isSeizure) {
      _startSeizureTimer();
    }

    // Delay slightly to give screen transition time before speech starts
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _speakCurrentStep();
    });
  }

  void _stopAllAudio() {
    if (kIsWeb) {
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) {
          window.rapidAidAudio.pause();
          window.rapidAidAudio.currentTime = 0;
        }
        if (window.rapidAidStepAudio) {
          window.rapidAidStepAudio.pause();
          window.rapidAidStepAudio.currentTime = 0;
        }
      """]);
    }
  }

  void _startMetronome() {
    _metronomeTimer = Timer.periodic(const Duration(milliseconds: 545), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _pulseState = !_pulseState);

      if (kIsWeb) {
        js.context.callMethod('eval', ["""
          if (navigator.vibrate) navigator.vibrate(50);
          try {
            var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            var osc = audioCtx.createOscillator();
            var gain = audioCtx.createGain();
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.frequency.value = 880;
            gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.04);
            osc.start();
            osc.stop(audioCtx.currentTime + 0.05);
          } catch(e) {}
        """]);
      }
    });
  }

  void _startSeizureTimer() {
    _seizureStopwatch = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seizureSecondsElapsed++);
    });
  }

  void _speakCurrentStep() {
    final steps = _getSteps();
    if (_currentStep < steps.length) {
      final text = steps[_currentStep]['instruction'] ?? '';
      if (kIsWeb && text.isNotEmpty) {
        _stopAllAudio(); // Stop any currently playing sentence before starting new one
        final encoded = Uri.encodeComponent(text);
        final url = "http://127.0.0.1:8000/api/tts?text=$encoded&lang=${widget.language}";
        js.context.callMethod('eval', ["""
          window.rapidAidStepAudio = new Audio('$url');
          window.rapidAidStepAudio.play().catch(function(e){ console.log(e); });
        """]);
      }
    }
  }

  String _getImageAssetForProtocol() {
    final proto = widget.protocolKey.toUpperCase();
    if (proto == 'SEIZURE') return 'assets/images/seizure_guide.png';
    if (proto == 'BLEEDING_AND_HELMET') return 'assets/images/spinal_caution.png';
    if (proto.contains('BLEEDING')) return 'assets/images/bleeding_control.png';
    if (proto == 'CHOKING') return 'assets/images/choking_guide.png';
    if (proto == 'SPINAL_CAUTION') return 'assets/images/spinal_caution.png';
    return 'assets/images/cpr_guide.png';
  }

  List<Map<String, String>> _getSteps() {
    final proto = widget.protocolKey.toUpperCase();

    if (proto == 'SEIZURE') {
      return [
        {
          'title': '1. PROTECT THE HEAD & CLEAR HAZARDS',
          'instruction':
              'Do NOT hold the person down. Move hard furniture, sharp objects, and hazards away. Place a folded jacket or soft towel gently under their head to prevent head trauma.',
          'tip': 'Never force anything between their teeth.',
          'type': 'seizure_head_cushion'
        },
        {
          'title': '2. DO NOT RESTRAIN OR PUT OBJECTS IN MOUTH',
          'instruction':
              'Strictly do NOT place your fingers, water, spoons, or medicines into their mouth. They will not swallow their tongue. Loosen tight clothing around their neck.',
          'tip': 'Do not attempt to restrict their arm or leg movements.',
          'type': 'seizure_no_restraint'
        },
        {
          'title': '3. TIME THE SEIZURE',
          'instruction':
              'Track how long the shaking lasts. If the seizure lasts longer than 5 minutes, or if another seizure starts right away, this is a critical medical emergency.',
          'tip': 'Inform 112 dispatchers the exact duration.',
          'type': 'seizure_timing'
        },
        {
          'title': '4. RECOVERY POSITION ONCE SHAKING STOPS',
          'instruction':
              'Once active jerking stops, roll them gently onto their side facing you. Tilt their chin forward to drain saliva and keep the airway clear. Stay with them until fully conscious.',
          'tip': 'Confusion and fatigue are completely normal post-seizure.',
          'type': 'recovery_position'
        },
      ];
    } else if (proto == 'BLEEDING_AND_HELMET') {
      return [
        {
          'title': '1. CRITICAL: DO NOT REMOVE HELMET (SPINE LOCK)',
          'instruction':
              'Strictly DO NOT pull the helmet off or twist their neck! Moving the neck can sever an injured cervical spinal cord and cause permanent paralysis. Stabilize the head in-line.',
          'tip': 'Leave the helmet on even if the victim is unresponsive.',
          'type': 'spine_lock'
        },
        {
          'title': '2. APPLY FIRM PALM PRESSURE TO WOUND',
          'instruction':
              'While keeping the neck completely still, take a clean cloth pad and press down with both hands directly over the bleeding wound.',
          'tip': 'Do not move the victim’s torso or rotate their head.',
          'type': 'bleeding_pressure'
        },
        {
          'title': '3. LAYER EXTRA CLOTHS IF SOAKED',
          'instruction':
              'If blood soaks through, do NOT lift the first cloth. Place more clean cloth layers directly on top and continue pressing hard until paramedics arrive.',
          'tip': 'Lifting the cloth tears away forming blood clots.',
          'type': 'bleeding_layers'
        },
      ];
    } else if (proto.contains('BLEEDING')) {
      return [
        {
          'title': '1. APPLY DIRECT PALM PRESSURE',
          'instruction':
              'Place a clean cloth, towel, or shirt directly over the bleeding wound. Press down firmly with both hands.',
          'tip': 'Maintain firm, continuous pressure without lifting to look.',
          'type': 'bleeding_pressure'
        },
        {
          'title': '2. ADD MORE LAYERS IF SOAKED THROUGH',
          'instruction':
              'If blood soaks through, do NOT remove the first cloth. Place additional cloth layers directly on top and continue pressing hard.',
          'tip': 'Lifting the cloth tears away forming blood clots.',
          'type': 'bleeding_layers'
        },
        {
          'title': '3. ELEVATE WOUND IF NO FRACTURE',
          'instruction':
              'If there are no broken bones, raise the bleeding limb above heart level while maintaining uninterrupted palm pressure.',
          'tip': 'Elevation reduces gravitational blood flow.',
          'type': 'bleeding_pressure'
        },
      ];
    } else if (proto == 'CHOKING') {
      return [
        {
          'title': '1. 5 SHARP BACK BLOWS',
          'instruction':
              'Lean the person forward. Deliver 5 sharp blows between the shoulder blades with the heel of your hand.',
          'tip': 'Gravity helps dislodge the foreign object.',
          'type': 'choking_blows'
        },
        {
          'title': '2. 5 ABDOMINAL THRUSTS (HEIMLICH)',
          'instruction':
              'Stand behind them. Place your fist thumb-side in just above their navel. Grasp with your other hand and pull sharply inward and upward.',
          'tip': 'Repeat 5 blows and 5 thrusts until the airway is clear.',
          'type': 'choking_thrusts'
        },
      ];
    } else {
      // Default: CPR
      return [
        {
          'title': '1. HAND POSITION (CENTER OF CHEST)',
          'instruction':
              'Place the heel of your dominant hand in the center of the chest between the nipples. Interlock your other hand on top.',
          'tip': 'Lock your elbows straight and position your shoulders directly above your hands.',
          'type': 'cpr_placement'
        },
        {
          'title': '2. PUSH HARD & FAST (110 BPM)',
          'instruction':
              'Push down at least 2 inches deep. Let the chest rise completely between compressions. Maintain pace with the metronome.',
          'tip': 'Do not pause. Count along with the beats.',
          'type': 'cpr_compress'
        },
      ];
    }
  }

  @override
  void dispose() {
    _stopAllAudio();
    _metronomeTimer?.cancel();
    _seizureStopwatch?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final currentStepData = steps[_currentStep];

    String formatTimer(int totalSecs) {
      final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
      final secs = (totalSecs % 60).toString().padLeft(2, '0');
      return "$mins:$secs";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF991B1B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _stopAllAudio();
            Navigator.pop(context);
          },
        ),
        title: Text(
          _isSeizure
              ? "EMD Protocol: Seizure First Aid"
              : (_isBleeding
                  ? "EMD Protocol: Bleeding Control"
                  : (_isCPR
                      ? "EMD Protocol: Active CPR Pacing"
                      : "Active First Aid Guidance")),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white),
            tooltip: "Repeat Instruction",
            onPressed: _speakCurrentStep,
          ),
        ],
      ),
      body: Column(
        children: [
          // STATUS BANNER (METRONOME OR TIMER OR GENERAL ADVISORY)
          if (_isCPR)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: _pulseState ? const Color(0xFFDC2626) : const Color(0xFF7F1D1D),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "CPR METRONOME • 110 BPM (PUSH HARD & FAST)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else if (_isSeizure)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "SEIZURE ELAPSED TIME",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _seizureSecondsElapsed >= 300
                          ? Colors.red.shade700
                          : Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _seizureSecondsElapsed >= 300 ? Colors.white : Colors.amber,
                      ),
                    ),
                    child: Text(
                      formatTimer(_seizureSecondsElapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_isHelmet)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFFB45309),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "SPINAL PROTECTION: LEAVE HELMET ON",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
            ),

          // INFOGRAPHIC DISPLAY AREA (Image with vector fallback)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        _getImageAssetForProtocol(),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Clean responsive Vector Fallback if the PNG is missing
                          return CustomPaint(
                            painter: ProtocolGraphicPainter(
                              type: currentStepData['type'] ?? 'general',
                              pulse: _pulseState,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STEP CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF991B1B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "STEP ${_currentStep + 1} OF ${steps.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentStepData['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStepData['instruction'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (currentStepData['tip'] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFB45309), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentStepData['tip']!,
                                    style: const TextStyle(
                                      color: Color(0xFF78350F),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM STEP NAVIGATION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("PREV"),
                  onPressed: _currentStep > 0
                      ? () {
                          _stopAllAudio();
                          setState(() => _currentStep--);
                          _speakCurrentStep();
                        }
                      : null,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF991B1B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(_currentStep == steps.length - 1
                      ? Icons.check_circle
                      : Icons.arrow_forward),
                  label: Text(
                    _currentStep == steps.length - 1 ? "FINISH" : "NEXT STEP",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onPressed: () {
                    _stopAllAudio();
                    if (_currentStep < steps.length - 1) {
                      setState(() => _currentStep++);
                      _speakCurrentStep();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Complete Vector Fallback Painter (Provides meaningful diagrams for all protocols)
class ProtocolGraphicPainter extends CustomPainter {
  final String type;
  final bool pulse;

  ProtocolGraphicPainter({required this.type, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case 'bleeding_pressure':
        // Forearm with pressure bandage and down-force hands
        final armPaint = Paint()
          ..color = const Color(0xFFFDBA74)
          ..strokeWidth = 32
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - 110, center.dy),
          Offset(center.dx + 110, center.dy),
          armPaint,
        );

        // White Pressure Pad
        final padPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 80, height: 44),
            const Radius.circular(8),
          ),
          padPaint,
        );

        // Downward pressing arrow
        final arrowPaint = Paint()
          ..color = const Color(0xFFDC2626)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx, center.dy - 65),
          Offset(center.dx, center.dy - 25),
          arrowPaint,
        );
        // Arrow head
        canvas.drawLine(
            Offset(center.dx - 12, center.dy - 38), Offset(center.dx, center.dy - 25), arrowPaint);
        canvas.drawLine(
            Offset(center.dx + 12, center.dy - 38), Offset(center.dx, center.dy - 25), arrowPaint);
        break;

      case 'bleeding_layers':
        // Stack of pressure cloths
        final layerPaint1 = Paint()..color = const Color(0xFFEF4444);
        final layerPaint2 = Paint()..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + 12), width: 90, height: 26),
            const Radius.circular(6),
          ),
          layerPaint1,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy - 12), width: 90, height: 26),
            const Radius.circular(6),
          ),
          layerPaint2,
        );
        break;

      case 'spine_lock':
        // Head / Helmet with bilateral stabilizer arrows
        final helmetPaint = Paint()..color = const Color(0xFF38BDF8);
        canvas.drawCircle(center, 45, helmetPaint);
        // Neck line
        final neckPaint = Paint()
          ..color = const Color(0xFFFDBA74)
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx, center.dy + 40),
          Offset(center.dx, center.dy + 80),
          neckPaint,
        );
        // Hold still indicators (side clamps)
        final clampPaint = Paint()
          ..color = Colors.amber
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(center.dx - 70, center.dy - 30), Offset(center.dx - 50, center.dy), clampPaint);
        canvas.drawLine(
            Offset(center.dx + 70, center.dy - 30), Offset(center.dx + 50, center.dy), clampPaint);
        break;

      case 'choking_blows':
      case 'choking_thrusts':
        // Torso profile with Heimlich thrust direction
        final torsoPaint = Paint()
          ..color = Colors.white70
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(center.dx - 20, center.dy - 40), 25, torsoPaint);
        canvas.drawLine(
          Offset(center.dx - 20, center.dy - 15),
          Offset(center.dx - 20, center.dy + 60),
          torsoPaint,
        );
        // Upward-inward thrust arrow
        final thrustArrow = Paint()
          ..color = Colors.amber
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(center.dx + 40, center.dy + 30), Offset(center.dx - 10, center.dy + 15), thrustArrow);
        break;

      case 'seizure_head_cushion':
        final cushionPaint = Paint()
          ..color = Colors.amber.shade300
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + 45), width: 140, height: 35),
            const Radius.circular(14),
          ),
          cushionPaint,
        );
        canvas.drawCircle(Offset(center.dx, center.dy + 15), 32, Paint()..color = Colors.white);
        break;

      case 'cpr_compress':
      case 'cpr_placement':
      default:
        final fillHeart = Paint()
          ..color = pulse ? Colors.redAccent : Colors.red.shade900
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, pulse ? 55 : 45, fillHeart);

        final targetLine = Paint()
          ..color = Colors.white
          ..strokeWidth = 3;
        canvas.drawLine(
            Offset(center.dx - 70, center.dy), Offset(center.dx + 70, center.dy), targetLine);
        canvas.drawLine(
            Offset(center.dx, center.dy - 70), Offset(center.dx, center.dy + 70), targetLine);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ProtocolGraphicPainter oldDelegate) => true;
}