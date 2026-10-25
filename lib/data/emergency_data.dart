import '../models/emergency_model.dart';

// Helper function to create localized text across all 6 languages easily
LocalizedContent lc(String en, {String? kn, String? hi, String? ta, String? te, String? ml}) {
  return LocalizedContent(
    en: en,
    kn: kn ?? en,
    hi: hi ?? en,
    ta: ta ?? en,
    te: te ?? en,
    ml: ml ?? en,
  );
}

class EmergencyData {
  // 1. CPR Protocol Steps
  static final List<InstructionStep> cprSteps = [
    InstructionStep(
      title: lc(
        "Check Responsiveness",
        kn: "ಪ್ರಜ್ಞೆ ಪರಿಶೀಲಿಸಿ",
        hi: "प्रतिक्रिया की जाँच करें",
      ),
      quickTip: lc(
        "Tap shoulder and call 112/108",
        kn: "ಹೆಗಲು ತಟ್ಟಿ 112/108 ಗೆ ಕರೆ ಮಾಡಿ",
        hi: "कंधा थपथपाएं और 112/108 पर कॉल करें",
      ),
      detailed: lc(
        "Gently tap shoulders and shout 'Are you okay?'. Call 112/108 immediately and put on speaker.",
        kn: "ಹೆಗಲನ್ನು ನಿಧಾನವಾಗಿ ತಟ್ಟಿ 'ಆರಾಮವಾಗಿದ್ದೀರಾ?' ಎಂದು ಕೇಳಿ. ತಕ್ಷಣ 112 ಕರೆ ಮಾಡಿ.",
        hi: "कंधे को थपथपाएं और 'क्या आप ठीक हैं?' पूछें। तुरंत 112 पर कॉल करें।",
      ),
      audioPrompt: lc(
        "Tap shoulder firmly. If no response, call 112 now.",
        kn: "ಹೆಗಲು ತಟ್ಟಿ ನೋಡಿ. ಪ್ರತಿಕ್ರಿಯೆ ಇಲ್ಲದಿದ್ದರೆ 112 ಗೆ ಕರೆ ಮಾಡಿ.",
        hi: "कंधे को थपथपाएं। अगर कोई प्रतिक्रिया नहीं है, तो तुरंत 112 पर कॉल करें।",
      ),
      visualAsset: "assets/images/cpr_step1.png",
    ),
    InstructionStep(
      title: lc(
        "Open Airway & Check Breathing",
        kn: "ಉಸಿರಾಟ ಪರೀಕ್ಷಿಸಿ",
        hi: "सांस की जांच करें",
      ),
      quickTip: lc(
        "Tilt head back, look for chest rise",
        kn: "ತಲೆ ಹಿಂದಕ್ಕೆ ಬಾಗಿಸಿ, ಎದೆಯ ಚಲನೆ ನೋಡಿ",
        hi: "सिर पीछे झुकाएं, छाती का उठना देखें",
      ),
      detailed: lc(
        "Tilt head back and lift chin. Look, listen, and feel for normal breathing for no more than 10 seconds.",
        kn: "ತಲೆ ಹಿಂದಕ್ಕೆ ಬಾಗಿಸಿ ಗಲ್ಲ ಎತ್ತಿ. 10 ಸೆಕೆಂಡುಗಳ ಕಾಲ ಉಸಿರಾಟವನ್ನು ಗಮನಿಸಿ.",
        hi: "सिर पीछे झुकाएं और ठुड्डी उठाएं। 10 सेकंड तक सांस की जांच करें।",
      ),
      audioPrompt: lc(
        "Look at the chest. If not breathing normally, prepare for compressions.",
        kn: "ಎದೆಯ ಭಾಗವನ್ನು ಗಮನಿಸಿ. ಉಸಿರಾಟವಿಲ್ಲದಿದ್ದರೆ ಎದೆ ಒತ್ತಲು ಸಿದ್ಧರಾಗಿ.",
        hi: "छाती को देखें। यदि सामान्य सांस नहीं है, तो छाती दबाने के लिए तैयार हों।",
      ),
      visualAsset: "assets/images/cpr_step2.png",
    ),
    InstructionStep(
      title: lc(
        "Hand Placement on Center of Chest",
        kn: "ಎದೆಯ ಮಧ್ಯಭಾಗದಲ್ಲಿ ಕೈ ಇರಿಸಿ",
        hi: "छाती के बीच में हाथ रखें",
      ),
      quickTip: lc(
        "Heel of hand on breastbone, interlock fingers",
        kn: "ಎದೆ ಮೂಳೆಯ ಮೇಲೆ ಕೈ ಹಿಮ್ಮಡಿ, ಬೆರಳು ಲಾಕ್ ಮಾಡಿ",
        hi: "हथेली छाती की हड्डी पर, उंगलियां फंसाएं",
      ),
      detailed: lc(
        "Place heel of one hand in the center of chest between nipples. Place other hand on top and interlock fingers.",
        kn: "ಎದೆಯ ಮಧ್ಯದಲ್ಲಿ ಒಂದು ಕೈ ಹಿಮ್ಮಡಿ ಇಡಿ. ಇನ್ನೊಂದು ಕೈ ಮೇಲಿಟ್ಟು ಬೆರಳುಗಳನ್ನು ಲಾಕ್ ಮಾಡಿ.",
        hi: "छाती के बीच में एक हथेली रखें। दूसरा हाथ ऊपर रखकर उंगलियां फंसाएं।",
      ),
      audioPrompt: lc(
        "Place the heel of your hand on the center of the breastbone. Lock your fingers.",
        kn: "ಎದೆಯ ಮೂಳೆಯ ಮಧ್ಯಭಾಗದಲ್ಲಿ ಕೈ ಹಿಮ್ಮಡಿ ಇರಿಸಿ ಬೆರಳುಗಳನ್ನು ಲಾಕ್ ಮಾಡಿ.",
        hi: "छाती की हड्डी के बीच में हथेली रखें और उंगलियां फंसाएं।",
      ),
      visualAsset: "assets/images/cpr_step3.png",
    ),
    InstructionStep(
      title: lc(
        "Deliver Hard & Fast Compressions",
        kn: "ವೇಗವಾಗಿ ಮತ್ತು ಬಲವಾಗಿ ಎದೆ ಒತ್ತಿರಿ",
        hi: "जोर से और तेजी से दबाएं",
      ),
      quickTip: lc(
        "Push 2 inches deep at 110 BPM",
        kn: "2 ಇಂಚು ಆಳಕ್ಕೆ 110 BPM ಲಯದಲ್ಲಿ ಒತ್ತಿರಿ",
        hi: "2 इंच गहरा, 110 बीट प्रति मिनट से दबाएं",
      ),
      detailed: lc(
        "Keep arms straight and lock elbows. Compress at least 2 inches deep at 100 to 120 beats per minute.",
        kn: "ಮೊಣಕೈ ಮಣಿಸದೆ ನೇರವಾಗಿಡಿ. 2 ಇಂಚು ಆಳಕ್ಕೆ ನಿಮಿಷಕ್ಕೆ 110 ರ ವೇಗದಲ್ಲಿ ಒತ್ತಿರಿ.",
        hi: "कोहनी सीधी रखें। 2 इंच गहरा 100 से 120 प्रति मिनट की गति से दबाएं।",
      ),
      audioPrompt: lc(
        "Push hard and fast to the beat of the metronome. Allow full chest recoil.",
        kn: "ಬಲವಾಗಿ ಮತ್ತು ವೇಗವಾಗಿ ಒತ್ತಿರಿ. ಎದೆ ಪೂರ್ಣ ಮೇಲಕ್ಕೆ ಬರಲು ಬಿಡಿ.",
        hi: "मेट्रोनोम की बीट पर तेजी और जोर से दबाएं। छाती को पूरी तरह ऊपर आने दें।",
      ),
      visualAsset: "assets/images/cpr_step4.png",
    ),
  ];

  // 2. Severe Bleeding Protocol Steps
  static final List<InstructionStep> bleedingSteps = [
    InstructionStep(
      title: lc(
        "Direct Downward Pressure",
        kn: "ಗಾಯದ ಮೇಲೆ ನೇರ ಒತ್ತಡ",
        hi: "घाव पर सीधा दबाव",
      ),
      quickTip: lc(
        "Press clean cloth with full palm force",
        kn: "ಶುದ್ಧ ಬಟ್ಟೆಯಿಂದ ಅಂಗೈ ಬಲದಿಂದ ಒತ್ತಿ",
        hi: "साफ कपड़े से हथेली की ताकत से दबाएं",
      ),
      detailed: lc(
        "Place a clean folded cloth pad directly over the laceration and press with full body force. Never lift your hand.",
        kn: "ಶುದ್ಧ ಬಟ್ಟೆಯನ್ನು ಗಾಯದ ಮೇಲಿಟ್ಟು ಪೂರ್ಣ ಬಲದಿಂದ ಒತ್ತಿ. ಕೈ ತೆಗೆಯಬೇಡಿ.",
        hi: "घाव पर साफ कपड़ा रखें और पूरी ताकत से दबाएं। हाथ न उठाएं।",
      ),
      audioPrompt: lc(
        "Apply firm direct pressure to the wound with a clean cloth.",
        kn: "ಸ್ವಚ್ಛ ಬಟ್ಟೆಯಿಂದ ಗಾಯದ ಮೇಲೆ ಬಲವಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ.",
        hi: "घाव पर साफ कपड़े से सीधा और गहरा दबाव बनाए रखें।",
      ),
      visualAsset: "assets/images/bleeding_step1.png",
    ),
    InstructionStep(
      title: lc(
        "Wrap Pressure Bandage",
        kn: "ಬ್ಯಾಂಡೇಜ್ ಬಿಗಿಯಾಗಿ ಕಟ್ಟಿ",
        hi: "पट्टी कसकर बांधें",
      ),
      quickTip: lc(
        "Wrap tightly over cloth pad",
        kn: "ಬಟ್ಟೆಯ ಮೇಲೆ ಬಿಗಿಯಾಗಿ ಕಟ್ಟಿ",
        hi: "कपड़े के ऊपर कसकर पट्टी लपेटें",
      ),
      detailed: lc(
        "Tie a bandage, scarf, or cloth strip firmly over the pad to lock the continuous pressure in place.",
        kn: "ಬ್ಯಾಂಡೇಜ್ ಅಥವಾ ಶಾಲನ್ನು ಬಟ್ಟೆಯ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಬಿಗಿಯಾಗಿ ಕಟ್ಟಿ.",
        hi: "दबाव बनाए रखने के लिए कपड़े के ऊपर पट्टी या दुपट्टा कसकर बांधें।",
      ),
      audioPrompt: lc(
        "Wrap a bandage tightly over the pad to hold constant pressure.",
        kn: "ನಿರಂತರ ಒತ್ತಡ ಉಳಿಸಿಕೊಳ್ಳಲು ಬ್ಯಾಂಡೇಜ್ ಬಿಗಿಯಾಗಿ ಕಟ್ಟಿ.",
        hi: "दबाव बनाए रखने के लिए कपड़े के ऊपर पट्टी कसकर बांधें।",
      ),
      visualAsset: "assets/images/bleeding_step2.png",
    ),
    InstructionStep(
      title: lc(
        "Elevate Injured Limb",
        kn: "ಗಾಯಗೊಂಡ ಅಂಗವನ್ನು ಮೇಲಕ್ಕೆತ್ತಿ",
        hi: "घायल अंग को ऊपर उठाएं",
      ),
      quickTip: lc(
        "Raise limb above heart level",
        kn: "ಹೃದಯದ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲೆ ಅಂಗ ಎತ್ತಿ",
        hi: "अंग को दिल के स्तर से ऊपर उठाएं",
      ),
      detailed: lc(
        "If no broken bones are suspected, raise the bleeding arm or leg above chest level to lower blood flow.",
        kn: "ಮೂಳೆ ಮುರಿದಿಲ್ಲದಿದ್ದರೆ, ಗಾಯವಾದ ಕೈ ಅಥವಾ ಕಾಲನ್ನು ಎದೆಯ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ.",
        hi: "हड्डी न टूटी हो तो घायल हाथ या पैर को दिल के स्तर से ऊपर उठाएं।",
      ),
      audioPrompt: lc(
        "Raise the injured limb above heart level to slow the bleeding.",
        kn: "ರಕ್ತದ ಹರಿವು ಕಡಿಮೆ ಮಾಡಲು ಗಾಯಗೊಂಡ ಭಾಗವನ್ನು ಮೇಲಕ್ಕೆತ್ತಿ.",
        hi: "खून का बहाव कम करने के लिए घायल हिस्से को दिल से ऊपर उठाएं।",
      ),
      visualAsset: "assets/images/bleeding_step3.png",
    ),
  ];

  // 3. Choking Protocol Steps
  static final List<InstructionStep> chokingSteps = [
    InstructionStep(
      title: lc(
        "Deliver 5 Back Blows",
        kn: "ಬೆನ್ನಿಗೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ",
        hi: "पीठ पर 5 बार थपथपाएं",
      ),
      quickTip: lc(
        "Lean forward, strike between shoulder blades",
        kn: "ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ, ಭುಜದ ಮೂಳೆಗಳ ಮಧ್ಯೆ ತಟ್ಟಿ",
        hi: "आगे झुकाएं, कंधों के बीच थपथपाएं",
      ),
      detailed: lc(
        "Support the chest, lean the person forward, and deliver 5 sharp blows between the scapulae using the heel of your hand.",
        kn: "ಎದೆಯನ್ನು ಹಿಡಿದು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ, ಕೈ ಹಿಮ್ಮಡಿಯಿಂದ ಬೆನ್ನಿನ ಮಧ್ಯೆ 5 ಬಾರಿ ತಟ್ಟಿ.",
        hi: "छाती को सहारा देकर आगे झुकाएं और हथेली के निचले हिस्से से पीठ पर 5 बार मारें।",
      ),
      audioPrompt: lc(
        "Lean the person forward and give 5 firm blows between the shoulder blades.",
        kn: "ವ್ಯಕ್ತಿಯನ್ನು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ ಭುಜಗಳ ಮಧ್ಯೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ.",
        hi: "व्यक्ति को आगे झुकाएं और दोनों कंधों के बीच 5 बार थपथपाएं।",
      ),
      visualAsset: "assets/images/choking_step1.png",
    ),
    InstructionStep(
      title: lc(
        "5 Inward & Upward Abdominal Thrusts",
        kn: "ಹೊಟ್ಟೆಯನ್ನು ಒಳಗೆ ಮತ್ತು ಮೇಲಕ್ಕೆ ಜಗ್ಗಿರಿ",
        hi: "पेट को अंदर और ऊपर की ओर दबाएं",
      ),
      quickTip: lc(
        "Fist just above navel, pull sharply",
        kn: "ಹೊಕ್ಕುಳಿನ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಮುಷ್ಟಿ, ಮೇಲಕ್ಕೆ ಜಗ್ಗಿ",
        hi: "नाभि के ठीक ऊपर मुट्ठी रखकर ऊपर झटका दें",
      ),
      detailed: lc(
        "Stand behind victim. Place thumb-side of fist just above navel. Grasp with other hand and pull sharply inward and upward.",
        kn: "ವ್ಯಕ್ತಿಯ ಹಿಂದೆ ನಿಂತು ಹೊಕ್ಕುಳಿನ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಮುಷ್ಟಿ ಇಟ್ಟು, ಒಳಗೆ ಮತ್ತು ಮೇಲ್ಮುಖವಾಗಿ 5 ಬಾರಿ ಜಗ್ಗಿರಿ.",
        hi: "पीछे खड़े होकर नाभि के ऊपर मुट्ठी रखें और अंदर-ऊपर की ओर 5 बार तेजी से झटका दें।",
      ),
      audioPrompt: lc(
        "Place your fist above the navel. Pull inward and upward sharply 5 times.",
        kn: "ಹೊಕ್ಕುಳಿನ ಮೇಲೆ ಮುಷ್ಟಿ ಇರಿಸಿ, ಒಳಗೆ ಮತ್ತು ಮೇಲಕ್ಕೆ 5 ಬಾರಿ ತೀವ್ರವಾಗಿ ಜಗ್ಗಿರಿ.",
        hi: "नाभि के ऊपर मुट्ठी रखें और अंदर तथा ऊपर की ओर तेजी से झटका दें।",
      ),
      visualAsset: "assets/images/choking_step2.png",
    ),
  ];

  // 4. Motorcycle Crash / Spinal Caution Steps
  static final List<InstructionStep> spinalSteps = [
    InstructionStep(
      title: lc(
        "Strict Rule: Do NOT Move Person or Remove Helmet",
        kn: "ವ್ಯಕ್ತಿಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ & ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ",
        hi: "व्यक्ति को न हिलाएं और हेलमेट न उतारें",
      ),
      quickTip: lc(
        "Spinal trauma risk; movement can cause paralysis",
        kn: "ಬೆನ್ನುಹುರಿ ಪೆಟ್ಟಾಗಿದ್ದರೆ ಚಲನೆ ಪಾರ್ಶ್ವವಾಯು ತರಬಹುದು",
        hi: "रीढ़ की चोट का खतरा; हिलाने से लकवा हो सकता है",
      ),
      detailed: lc(
        "Do not pull, lift, or rotate the person. Do not remove helmet as neck twisting can sever the cervical spine.",
        kn: "ವ್ಯಕ್ತಿಯನ್ನು ಎಳೆಯಬೇಡಿ ಅಥವಾ ತಿರುಗಿಸಬೇಡಿ. ಕುತ್ತಿಗೆಯ ಮೂಳೆ ಮುರಿಯುವ ಅಪಾಯವಿರುವುದರಿಂದ ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ.",
        hi: "व्यक्ति को बिल्कुल न खींचें और न घुमाएं। हेलमेट न उतारें क्योंकि इससे गर्दन की हड्डी टूट सकती है।",
      ),
      audioPrompt: lc(
        "Do not move the person and leave the helmet on. Wait for paramedics.",
        kn: "ವ್ಯಕ್ತಿಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ ಮತ್ತು ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ. ಆಂಬ್ಯುಲೆನ್ಸ್‌ಗೆ ಕಾಯಿರಿ.",
        hi: "व्यक्ति को न हिलाएं और हेलमेट लगा रहने दें। एम्बुलेंस का इंतजार करें।",
      ),
      visualAsset: "assets/images/spinal_step1.png",
    ),
    InstructionStep(
      title: lc(
        "Manual Head In-Line Stabilization",
        kn: "ತಲೆಯನ್ನು ಅಲುಗಾಡದಂತೆ ಭದ್ರವಾಗಿ ಹಿಡಿಯಿರಿ",
        hi: "सिर को दोनों तरफ से स्थिर थामे रखें",
      ),
      quickTip: lc(
        "Hold both sides of helmet/head firmly",
        kn: "ತಲೆ ಅಥವಾ ಹೆಲ್ಮೆಟ್‌ನ ಎರಡೂ ಬದಿಗಳನ್ನು ಹಿಡಿಯಿರಿ",
        hi: "हेलमेट या सिर को दोनों तरफ से मजबूती से पकड़ें",
      ),
      detailed: lc(
        "Kneel at the top of their crown. Place hands firmly on both sides of head to freeze any neck movement until 112 arrives.",
        kn: "ತಲೆಯ ಬಳಿ ಕುಳಿತು ಎರಡೂ ಬದಿಗಳಿಂದ ತಲೆಯನ್ನು ಭದ್ರವಾಗಿ ಹಿಡಿದು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ನೋಡಿಕೊಳ್ಳಿ.",
        hi: "सिर के पीछे बैठें और दोनों तरफ हाथ रखकर गर्दन को बिल्कुल स्थिर रखें।",
      ),
      audioPrompt: lc(
        "Hold both sides of the head to prevent any neck movement.",
        kn: "ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ತಲೆಯ ಎರಡೂ ಬದಿಗಳನ್ನು ಭದ್ರವಾಗಿ ಹಿಡಿಯಿರಿ.",
        hi: "गर्दन में कोई हलचल न हो इसके लिए सिर को दोनों तरफ से थामे रखें।",
      ),
      visualAsset: "assets/images/spinal_step2.png",
    ),
  ];

  // 5. Interactive Assessment Questions
  static final List<AssessmentQuestion> triageQuestions = [
    AssessmentQuestion(
      id: "q_scene_safety",
      question: lc(
        "Is the scene safe from traffic, fire, and hazards?",
        kn: "ಸ್ಥಳವು ವಾಹನ ಸಂಚಾರ ಮತ್ತು ಬೆಂಕಿಯಿಂದ ಸುರಕ್ಷಿತವಾಗಿದೆಯೇ?",
        hi: "क्या घटनास्थल यातायात और खतरों से सुरक्षित है?",
      ),
      yesNextId: "q_responsiveness",
      noProtocol: EmergencyType.spinalCaution,
    ),
    AssessmentQuestion(
      id: "q_responsiveness",
      question: lc(
        "Tap shoulder firmly: Is the person awake or responding?",
        kn: "ಹೆಗಲು ತಟ್ಟಿ ನೋಡಿ: ವ್ಯಕ್ತಿಯು ಪ್ರಜ್ಞೆಯಲ್ಲಿದ್ದಾರೆಯೇ?",
        hi: "कंधा थपथपाएं: क्या व्यक्ति होश में है या प्रतिक्रिया दे रहा है?",
      ),
      yesNextId: "q_bleeding",
      noNextId: "q_breathing",
    ),
    AssessmentQuestion(
      id: "q_breathing",
      question: lc(
        "Look at chest: Are they breathing normally?",
        kn: "ಎದೆಯನ್ನು ಗಮನಿಸಿ: ಅವರು ಸಹಜವಾಗಿ ಉಸಿರಾಡುತ್ತಿದ್ದಾರೆಯೇ?",
        hi: "छाती को देखें: क्या वे सामान्य रूप से सांस ले रहे हैं?",
      ),
      yesProtocol: EmergencyType.spinalCaution,
      noProtocol: EmergencyType.cpr,
    ),
    AssessmentQuestion(
      id: "q_bleeding",
      question: lc(
        "Is there severe, spurting external bleeding?",
        kn: "ತೀವ್ರ ರಕ್ತಸ್ರಾವವಾಗುತ್ತಿದೆಯೇ?",
        hi: "क्या अत्यधिक या बहता हुआ रक्तस्राव हो रहा है?",
      ),
      yesProtocol: EmergencyType.severeBleeding,
      noNextId: "q_choking",
    ),
    AssessmentQuestion(
      id: "q_choking",
      question: lc(
        "Are they clutching their throat or unable to cough?",
        kn: "ಗಂಟಲು ಹಿಡಿದುಕೊಂಡಿದ್ದಾರೆಯೇ ಅಥವಾ ಕೆಮ್ಮಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲವೇ?",
        hi: "क्या वे गला पकड़ रहे हैं या खांसने में असमर्थ हैं?",
      ),
      yesProtocol: EmergencyType.choking,
      noProtocol: EmergencyType.spinalCaution,
    ),
  ];
}