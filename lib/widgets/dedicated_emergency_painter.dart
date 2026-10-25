import 'package:flutter/material.dart';

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
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final purpleArm = Paint()..color = const Color(0xFF8B5CF6)..style = PaintingStyle.fill;
    final darkPurple = Paint()..color = const Color(0xFF4C1D95)..style = PaintingStyle.fill;
    final redAccent = Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.fill;
    final bloodRed = Paint()..color = const Color(0xFFB91C1C)..style = PaintingStyle.fill;

    if (protocolKey == "BLEEDING_AND_HELMET") {
      _paintBleedingAndHelmetProtocol(canvas, center, outlinePaint, bloodRed, redAccent, darkGrey);
    } else if (protocolKey == "BLEEDING") {
      _paintBleedingProtocol(canvas, center, outlinePaint, bloodRed, darkGrey);
    } else if (protocolKey == "CHOKING") {
      _paintChokingProtocol(canvas, center, outlinePaint, purpleArm, darkPurple, redAccent);
    } else if (protocolKey == "SPINAL_CAUTION") {
      _paintSpinalProtocol(canvas, center, outlinePaint, darkGrey, redAccent);
    } else {
      _paintCprProtocol(canvas, center, outlinePaint, darkGrey, purpleArm, darkPurple, redAccent);
    }
  }

  // --- DUAL EMERGENCY: BLEEDING + HELMET SPINAL LOCK ---
  void _paintBleedingAndHelmetProtocol(
    Canvas canvas,
    Offset center,
    Paint outline,
    Paint bloodRed,
    Paint redAccent,
    Paint grey,
  ) {
    if (stepIndex == 0) {
      // Step 1: Keep Helmet On & Stabilize Head
      _drawHelmetSpinalLock(canvas, Offset(center.dx, center.dy - 10), outline, redAccent);
    } else {
      // Step 2: Apply Continuous Wound Pressure Without Moving Patient
      _drawBleedingLimbWithDirectPressure(canvas, center, outline, bloodRed);
    }
  }

  // --- CPR PROTOCOL ---
  void _paintCprProtocol(
    Canvas canvas,
    Offset center,
    Paint outline,
    Paint grey,
    Paint purple,
    Paint darkPurple,
    Paint red,
  ) {
    switch (stepIndex) {
      case 0:
        // Step 1: Heel on Sternum Target
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
        // Step 2: Interlock Fingers on Top
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
        // Step 3: Vertical Shoulders and Locked Straight Arms
        _drawKneelingRescuer(canvas, center, outline, grey, purple, compressionOffset: 0);
        final verticalLine = Paint()
          ..color = Colors.blue.shade700
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(center.dx - 30, center.dy - 55),
          Offset(center.dx - 30, center.dy + 35),
          verticalLine,
        );
        break;

      case 3:
        // Step 4: Pulsing Compressions at 110 BPM
        double comp = pulseValue * 15.0;
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
        // Step 5: Continuous Compressions Until Paramedics Arrive
        _drawAmbulance(canvas, center, outline);
        break;
    }
  }

  // --- SEVERE BLEEDING PROTOCOL ---
  void _paintBleedingProtocol(Canvas canvas, Offset center, Paint outline, Paint bloodRed, Paint grey) {
    if (stepIndex == 0) {
      _drawBleedingLimbWithDirectPressure(canvas, center, outline, bloodRed);
    } else if (stepIndex == 1) {
      _drawLayeredPressureWrap(canvas, center, outline, bloodRed);
    } else {
      _drawElevatedLimb(canvas, center, outline);
    }
  }

  // --- CHOKING PROTOCOL ---
  void _paintChokingProtocol(
    Canvas canvas,
    Offset center,
    Paint outline,
    Paint purple,
    Paint darkPurple,
    Paint red,
  ) {
    if (stepIndex == 0) {
      _drawBackBlowsBetweenScapulae(canvas, center, outline, purple, red);
    } else if (stepIndex == 1) {
      _drawHeimlichNavelFistPlacement(canvas, center, outline, darkPurple);
    } else {
      _drawHeimlichUpwardThrusts(canvas, center, outline, darkPurple, red);
    }
  }

  // --- SPINAL CAUTION PROTOCOL ---
  void _paintSpinalProtocol(Canvas canvas, Offset center, Paint outline, Paint grey, Paint red) {
    if (stepIndex == 0) {
      _drawHelmetSpinalLock(canvas, center, outline, red);
    } else {
      _drawTwoHandHeadStabilization(canvas, center, outline, grey);
    }
  }

  // --- COMPONENT PRIMITIVES ---

  void _drawRibcageAndSternumTarget(Canvas canvas, Offset center, Paint outline) {
    // Head silhouette
    canvas.drawCircle(Offset(center.dx, center.dy - 60), 24, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx, center.dy - 60), 24, outline);

    // Torso outline
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

    // Sternum target ring and crosshair
    final redTarget = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(center.dx, center.dy + 10), 16, redTarget);
    canvas.drawLine(Offset(center.dx - 22, center.dy + 10), Offset(center.dx + 22, center.dy + 10), redTarget);
    canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy + 32), redTarget);
  }

  void _drawBleedingLimbWithDirectPressure(Canvas canvas, Offset center, Paint outline, Paint bloodRed) {
    // Limb
    final limb = Path()
      ..moveTo(center.dx - 95, center.dy + 22)
      ..lineTo(center.dx + 95, center.dy + 22)
      ..lineTo(center.dx + 95, center.dy - 22)
      ..lineTo(center.dx - 95, center.dy - 22)
      ..close();
    canvas.drawPath(limb, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawPath(limb, outline);

    // Blood pooling
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy), width: 40, height: 16), bloodRed);

    // Gauze/cloth pad
    final pad = Rect.fromCenter(center: Offset(center.dx, center.dy - 8), width: 75, height: 28);
    canvas.drawRRect(RRect.fromRectAndRadius(pad, const Radius.circular(6)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(pad, const Radius.circular(6)), outline);

    // Pressure hand
    canvas.drawCircle(Offset(center.dx, center.dy - 34), 22, Paint()..color = const Color(0xFF6D28D9));
    canvas.drawCircle(Offset(center.dx, center.dy - 34), 22, outline);

    // Downward arrow
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
    final limb = Rect.fromCenter(center: center, width: 190, height: 44);
    canvas.drawRect(limb, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawRect(limb, outline);

    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(center.dx + (i * 22) - 10, center.dy - 22),
        Offset(center.dx + (i * 22) + 10, center.dy + 22),
        Paint()..color = Colors.white..strokeWidth = 14..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(center.dx + (i * 22) - 10, center.dy - 22),
        Offset(center.dx + (i * 22) + 10, center.dy + 22),
        outline,
      );
    }
  }

  void _drawElevatedLimb(Canvas canvas, Offset center, Paint outline) {
    // Ground level indicator
    canvas.drawCircle(Offset(center.dx - 70, center.dy + 40), 18, outline);
    canvas.drawLine(Offset(center.dx - 50, center.dy + 40), Offset(center.dx + 40, center.dy + 40), outline);

    // Elevated arm
    final arm = Path()
      ..moveTo(center.dx - 20, center.dy + 35)
      ..lineTo(center.dx + 50, center.dy - 55)
      ..lineTo(center.dx + 65, center.dy - 45)
      ..lineTo(center.dx - 5, center.dy + 45)
      ..close();
    canvas.drawPath(arm, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawPath(arm, outline);

    // Elevation reference line
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
    canvas.drawCircle(
      Offset(center.dx, center.dy),
      18,
      Paint()..color = Colors.red.shade700..style = PaintingStyle.stroke..strokeWidth = 2,
    );

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

    // Navel point
    canvas.drawCircle(Offset(center.dx, center.dy + 25), 6, Paint()..color = Colors.black87);

    // Fist positioned directly above navel
    final fist = Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 46, height: 32);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), darkPurple);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), outline);
  }

  void _drawHeimlichUpwardThrusts(Canvas canvas, Offset center, Paint outline, Paint darkPurple, Paint red) {
    final fist = Rect.fromCenter(center: Offset(center.dx, center.dy), width: 55, height: 36);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), darkPurple);
    canvas.drawRRect(RRect.fromRectAndRadius(fist, const Radius.circular(8)), outline);

    // Inward and upward thrust arrow
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
    // Motorcycle helmet shell
    final helmet = Path()
      ..addOval(Rect.fromCenter(center: center, width: 90, height: 100));
    canvas.drawPath(helmet, Paint()..color = const Color(0xFF334155));
    canvas.drawPath(helmet, outline);

    // Visor
    final visor = Rect.fromLTWH(center.dx - 32, center.dy - 22, 64, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(visor, const Radius.circular(6)),
      Paint()..color = Colors.cyan.shade100,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(visor, const Radius.circular(6)), outline);

    // Red prohibition cross (Do not remove)
    final crossPaint = Paint()..color = red.color..strokeWidth = 6.0..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 48, center.dy - 48), Offset(center.dx + 48, center.dy + 48), crossPaint);
    canvas.drawLine(Offset(center.dx + 48, center.dy - 48), Offset(center.dx - 48, center.dy + 48), crossPaint);
  }

  void _drawTwoHandHeadStabilization(Canvas canvas, Offset center, Paint outline, Paint grey) {
    // Head/Helmet center
    canvas.drawCircle(center, 36, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(center, 36, outline);

    // Left and right bracing hands
    final leftHand = Rect.fromLTWH(center.dx - 62, center.dy - 25, 20, 50);
    canvas.drawRRect(RRect.fromRectAndRadius(leftHand, const Radius.circular(8)), grey);
    canvas.drawRRect(RRect.fromRectAndRadius(leftHand, const Radius.circular(8)), outline);

    final rightHand = Rect.fromLTWH(center.dx + 42, center.dy - 25, 20, 50);
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

  void _drawKneelingRescuer(
    Canvas canvas,
    Offset center,
    Paint outline,
    Paint grey,
    Paint purple, {
    required double compressionOffset,
  }) {
    // Victim lying on back
    canvas.drawCircle(Offset(center.dx - 80, center.dy + 40), 16, outline);
    final victim = Path()
      ..moveTo(center.dx - 64, center.dy + 40)
      ..quadraticBezierTo(center.dx - 40, center.dy + 25 + compressionOffset, center.dx - 15, center.dy + 40)
      ..lineTo(center.dx - 64, center.dy + 52)
      ..close();
    canvas.drawPath(victim, outline);

    // Rescuer head
    canvas.drawCircle(Offset(center.dx - 30, center.dy - 45 + compressionOffset), 20, grey);
    canvas.drawCircle(Offset(center.dx - 30, center.dy - 45 + compressionOffset), 20, outline);

    // Rescuer torso & knees
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
    canvas.drawPath(body, outline);

    // Locked vertical straight arms
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

    // Red emergency stripes & cross
    canvas.drawRect(Rect.fromLTWH(center.dx - 80, center.dy + 8, 155, 6), redPaint);
    canvas.drawRect(Rect.fromLTWH(center.dx - 22, center.dy - 22, 6, 20), redPaint);
    canvas.drawRect(Rect.fromLTWH(center.dx - 29, center.dy - 15, 20, 6), redPaint);

    // Wheels
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