import '../models/emergency_model.dart';

final List adultChokingProtocol = [
  EmergencyStep(
    title: 'Verify Choking & Encourage Coughing',
    quickInstruction: "Ask 'Are you choking?' If they can cough, let them cough forcefully.",
    detailedInstruction: "Ask clearly: 'Are you choking?' If the person can speak, cough loudly, or breathe, do not interfere. Encourage them to keep coughing.",
    actionTip: 'Stay calm and keep watching them closely.',
  ),
  EmergencyStep(
    title: 'Deliver 5 Back Blows',
    quickInstruction: 'Lean them forward. Give 5 firm blows between shoulder blades with palm heel.',
    detailedInstruction: 'Stand slightly behind and to the side. Support their chest with one hand and lean them forward. Deliver up to 5 sharp blows between shoulder blades using the heel of your hand.',
    actionTip: 'Check mouth after each blow to see if the blockage cleared.',
  ),
  EmergencyStep(
    title: 'Perform 5 Abdominal Thrusts (Heimlich)',
    quickInstruction: 'Place fist above navel, grasp with other hand, pull inward and upward 5 times.',
    detailedInstruction: 'Stand behind the person. Wrap your arms around their waist. Place your fist thumb-side just above the navel. Pull sharply inward and upward up to 5 times.',
    actionTip: 'Stop immediately if the obstruction is relieved.',
  ),
  EmergencyStep(
    title: 'Cycle & Monitor',
    quickInstruction: 'Alternate 5 back blows and 5 abdominal thrusts until clear or unresponsive.',
    detailedInstruction: 'Repeat cycles of 5 back blows and 5 abdominal thrusts. If the person loses consciousness at any point, lower them gently to the ground and start CPR immediately.',
    actionTip: 'Call 112 / 108 immediately if not already done.',
  ),
];

final List adultCprProtocol = [
  EmergencyStep(
    title: 'Call Emergency Services (112 / 108)',
    quickInstruction: 'Put phone on speaker, call 112 or 108, and yell for an AED.',
    detailedInstruction: 'Call 112 or 108 immediately. Put the phone on speaker mode next to you so you can talk to the dispatcher while attending to the patient. Shout for someone to bring an AED.',
    actionTip: 'Do not leave the victim alone unless strictly necessary to call.',
  ),
  EmergencyStep(
    title: 'Position Hands on Chest Center',
    quickInstruction: 'Place heel of one hand in center of chest, interlock other hand on top.',
    detailedInstruction: "Kneel beside the victim's chest. Place the heel of one hand on the center of the chest (lower half of breastbone). Interlock the fingers of your second hand on top. Keep elbows straight.",
    actionTip: 'Position your shoulders directly over your hands.',
  ),
  EmergencyStep(
    title: 'Deliver 30 Chest Compressions',
    quickInstruction: 'Push hard and fast: 5 to 6 cm deep, 100 to 120 beats per minute.',
    detailedInstruction: 'Push straight down hard and fast, at least 5 cm (2 inches) deep but no more than 6 cm. Allow full chest recoil between compressions. Maintain a cadence of 100-120 compressions per minute.',
    actionTip: "Think of the tempo of the song 'Stayin Alive'.",
  ),
  EmergencyStep(
    title: 'Deliver 2 Rescue Breaths (If Trained)',
    quickInstruction: 'Tilt head back, pinch nose, give 2 normal breaths. Otherwise, continue compressions only.',
    detailedInstruction: 'If trained and willing: gently tilt the head back and lift the chin. Pinch the nostrils closed, make a complete seal over their mouth, and blow for 1 second until chest rises. Give 2 breaths, then resume compressions.',
    actionTip: 'If untrained or unwilling, provide Hands-Only CPR (continuous compressions).',
  ),
];

final Map triageQuestions = {
  'q_responsive': AssessmentQuestion(
    id: 'q_responsive',
    questionText: 'Is the person responsive?',
    subText: 'Tap their shoulders firmly and ask loudly: "Are you okay?"',
    yesNextQuestionId: 'q_choking',
    noNextQuestionId: 'q_breathing',
  ),
  'q_breathing': AssessmentQuestion(
    id: 'q_breathing',
    questionText: 'Is the person breathing normally?',
    subText: 'Look at the chest for rise and fall. Agonal gasps or snoring sounds are NOT normal breathing.',
    yesResultEmergency: EmergencyType.unknown,
    noResultEmergency: EmergencyType.cprAdult,
  ),
  'q_choking': AssessmentQuestion(
    id: 'q_choking',
    questionText: 'Is the person clutching their throat or unable to speak?',
    subText: 'They cannot talk, have a weak cough, or make high-pitched whistling sounds.',
    yesResultEmergency: EmergencyType.chokingAdult,
    noResultEmergency: EmergencyType.bleedingControl,
  ),
};