import '../models/emergency_model.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";

  static String getTtsLocale(String lang) {
    switch (lang) {
      case 'kn': return 'kn';
      case 'ta': return 'ta';
      case 'te': return 'te';
      case 'hi': return 'hi';
      case 'ml': return 'ml';
      default: return 'en';
    }
  }

  static List<EmergencyStep> getAdaptiveProtocol({
    required String emergencyType,
    required bool isVictimResponsive,
    required bool isVictimBreathing,
    required bool isHelperPanicked,
    required bool isHelperAlone,
  }) {
    switch (emergencyType.toUpperCase()) {
      case "CPR":
        return [
          EmergencyStep(
            stepDurationSeconds: 10,
            hasMetronome: false,
            // Step 1: Victim lying flat on firm ground, rescuer kneeling beside shoulders
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Cardiopulmonary_resuscitation.svg/640px-Cardiopulmonary_resuscitation.svg.png",
            title: const LocalizedContent(
              en: "Step 1: Emergency Call & Positioning",
              kn: "ಹಂತ 1: 112 ಕರೆ & ವ್ಯಕ್ತಿಯನ್ನು ಮಲಗಿಸಿ",
              ta: "படி 1: அவசர அழைப்பு 112 & நிலைப்படுத்துதல்",
              te: "దశ 1: 112 అత్యవసర కాల్ & స్థానం",
              hi: "चरण 1: 112 पर कॉल करें और सही स्थिति में लिटाएं",
              ml: "ഘട്ടം 1: 112 ലേക്ക് വിളിക്കുക & കിടത്തുക",
            ),
            quickTip: const LocalizedContent(
              en: "DIAL 112! Lay flat on back on hard floor.",
              kn: "112 ಗೆ ಕರೆ ಮಾಡಿ! ಗಟ್ಟಿ ನೆಲದ ಮೇಲೆ ನೇರವಾಗಿ ಮಲಗಿಸಿ.",
              ta: "112 ஐ அழைக்கவும்! தரையில் நேராக படுக்க வைக்கவும்.",
              te: "112 కి కాల్ చేయండి! గట్టి నేలపై పడుకోబెట్టండి.",
              hi: "112 डायल करें! सख्त फर्श पर सीधा लिटाएं।",
              ml: "112 ലേക്ക് വിളിക്കുക! തറയിൽ നേരെ കിടത്തുക.",
            ),
            detailed: const LocalizedContent(
              en: "Call 112 immediately. Lay the person flat on their back on a firm surface. Kneel directly beside their chest.",
              kn: "ತಕ್ಷಣ 112 ಗೆ ಕರೆ ಮಾಡಿ. ವ್ಯಕ್ತಿಯನ್ನು ಗಟ್ಟಿ ಸಮತಟ್ಟಾದ ನೆಲದ ಮೇಲೆ ಮಲಗಿಸಿ ಅವರ ಎದೆಯ ಪಕ್ಕದಲ್ಲಿ ಮಂಡಿಯೂರಿ ಕುಳಿತುಕೊಳ್ಳಿ.",
              ta: "உடனே 112 ஐ அழைக்கவும். நபரை கடினமான தரைப்பகுதியில் படுக்க வைத்து மார்பின் அருகே மண்டியிடவும்.",
              te: "వెంటనే 112 కు కాల్ చేయండి. వ్యక్తిని గట్టి నేలపై పడుకోబెట్టి వారి ఛాతీ పక్కన కూర్చోండి.",
              hi: "तुरंत 112 पर कॉल करें। व्यक्ति को सख्त फर्श पर सीधा लिटाएं और उनकी छाती के पास बैठें।",
              ml: "ഉടൻ 112 ലേക്ക് വിളിക്കുക. വ്യക്തിയെ തറയിൽ കിടത്തി നെഞ്ചിന്റെ ഭാഗത്ത് ഇരിക്കുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Dial 112 now. Place the person flat on the floor on their back.",
              kn: "ತಕ್ಷಣ 112 ಗೆ ಕರೆ ಮಾಡಿ. ವ್ಯಕ್ತಿಯನ್ನು ಗಟ್ಟಿ ನೆಲದ ಮೇಲೆ ಮಲಗಿಸಿ.",
              ta: "உடனே 112 ஐ அழைக்கவும். நபரை தரையில் படுக்க வைக்கவும்.",
              te: "వెంటనే 112 కు కాల్ చేయండి. నేలపై పడుకోబెట్టండి.",
              hi: "तुरंत 112 पर कॉल करें। व्यक्ति को फर्श पर सीधा लिटाएं।",
              ml: "ഉടൻ 112 ലേക്ക് വിളിക്കുക. വ്യക്തിയെ തറയിൽ നേരെ കിടത്തുക.",
            ),
          ),
          EmergencyStep(
            stepDurationSeconds: 12,
            hasMetronome: false,
            // Step 2: Clear diagram of heel of palm on sternum, interlocked fingers, and vertical locked elbows
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/CPR_adult_compression_depth.svg/640px-CPR_adult_compression_depth.svg.png",
            title: const LocalizedContent(
              en: "Step 2: Hand Placement & Locked Arms",
              kn: "ಹಂತ 2: ಕೈಗಳ ಸರಿಯಾದ ಜೋಡಣೆ",
              ta: "படி 2: நெஞ்சின் நடுவில் கைகளை வைக்கவும்",
              te: "దశ 2: ఛాతీ మధ్యలో చేతులను ఉంచండి",
              hi: "चरण 2: छाती के केंद्र में हाथ रखें",
              ml: "ഘട്ടം 2: നെഞ്ചിന്റെ മധ്യത്തിൽ കൈ വയ്ക്കുക",
            ),
            quickTip: const LocalizedContent(
              en: "Heel of hand on center of chest. Interlock fingers. Straight elbows!",
              kn: "ಎದೆಯ ಮಧ್ಯದಲ್ಲಿ ಕೈ ಹಿಮ್ಮಡಿ ಇಡಿ. ಬೆರಳುಗಳನ್ನು ಸೇರಿಸಿ ಮೊಣಕೈ ನೇರವಾಗಿಡಿ!",
              ta: "நெஞ்சின் நடுவில் உள்ளங்கையை வைக்கவும். விரல்களைப் பூட்டவும். முழங்கையை நேராக வைக்கவும்!",
              te: "ఛాతీ మధ్యలో చేతి మడమ ఉంచండి. వేళ్లు బిగించి మోచేతులు నిటారుగా ఉంచండి!",
              hi: "छाती के बीच में हथेली रखें। उंगलियां फंसाएं और कोहनी सीधी रखें!",
              ml: "നെഞ്ചിന്റെ നടുവിൽ കൈപ്പത്തി വയ്ക്കുക. വിരലുകൾ കോർത്ത് കൈകൾ നേരെയാക്കുക!",
            ),
            detailed: const LocalizedContent(
              en: "Place the heel of one hand in the center of the breastbone. Lock fingers with the other hand. Keep elbows completely locked and shoulders directly above hands.",
              kn: "ಒಂದು ಕೈಯ ಹಿಮ್ಮಡಿಯನ್ನು ಎದೆಯ ಮೂಳೆಯ ಮಧ್ಯದಲ್ಲಿಡಿ. ಇನ್ನೊಂದು ಕೈಯ ಬೆರಳುಗಳನ್ನು ಸೇರಿಸಿ ಭದ್ರಪಡಿಸಿ. ಮೊಣಕೈ ನೇರವಾಗಿರಲಿ.",
              ta: "ஒரு கையின் அடியை மார்பின் நடுவில் வைக்கவும். மற்றொரு கையால் விரல்களைப் பூட்டவும். கைகளை நேராக வைக்கவும்.",
              te: "ఒక చేతి మడమను ఛాతీ మధ్యలో ఉంచండి. మరో చేతితో వేళ్లను లాక్ చేయండి. మోచేతులను వంచకండి.",
              hi: "एक हाथ की हथेली छाती की हड्डी के बीच में रखें। दूसरे हाथ की उंगलियां फंसाएं और कोहनी बिल्कुल सीधी रखें।",
              ml: "ഒരു കൈ നെഞ്ചിന്റെ നടുവിൽ വയ്ക്കുക. മറ്റേ കൈ കൊണ്ട് വിരലുകൾ കോർക്കുക. കൈ മടക്കരുത്.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Place the heel of your hand on the center of the chest. Interlock your fingers and keep your elbows straight.",
              kn: "ಎದೆಯ ಮಧ್ಯಭಾಗದಲ್ಲಿ ಕೈ ಇಡಿ. ಬೆರಳುಗಳನ್ನು ಸೇರಿಸಿ ಮೊಣಕೈ ನೇರವಾಗಿಡಿ.",
              ta: "நெஞ்சின் நடுவில் கையை வைக்கவும். விரல்களைப் பூட்டி முழங்கையை நேராக வைக்கவும்.",
              te: "ఛాతీ మధ్యలో చేయి ఉంచండి. వేళ్లు బిగించి మోచేతులను నిటారుగా ఉంచండి.",
              hi: "छाती के बीच में हाथ रखें। उंगलियां फंसाएं और कोहनी सीधी रखें।",
              ml: "നെഞ്ചിന്റെ നടുവിൽ കൈ വയ്ക്കുക. വിരലുകൾ കോർത്ത് കൈ നേരെ പിടിക്കുക.",
            ),
          ),
          EmergencyStep(
            stepDurationSeconds: 30,
            hasMetronome: true,
            // Step 3: Compressions in action showing 2-inch depression and upward chest recoil
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Chest_compressions.svg/640px-Chest_compressions.svg.png",
            title: const LocalizedContent(
              en: "Step 3: Push Hard & Fast (110 BPM)",
              kn: "ಹಂತ 3: ಬಲವಾಗಿ ಮತ್ತು ವೇಗವಾಗಿ ಒತ್ತಿರಿ (110 BPM)",
              ta: "படி 3: வேகமாக அழுத்தவும் (110 BPM)",
              te: "దశ 3: బలంగా మరియు వేగంగా నొక్కండి (110 BPM)",
              hi: "चरण 3: जोर से और तेजी से दबाएं (110 BPM)",
              ml: "ഘട്ടം 3: വേഗത്തിലും ശക്തിയിലും അമർത്തുക (110 BPM)",
            ),
            quickTip: const LocalizedContent(
              en: "PUSH HARD! 2 inches deep. Follow the rhythmic metronome beats!",
              kn: "ಬಲವಾಗಿ ಒತ್ತಿರಿ! 2 ಇಂಚು ಆಳಕ್ಕೆ. ಮೆಟ್ರೋನೋಮ್ ಸದ್ದಿನ ಜೊತೆ ಒತ್ತಿರಿ!",
              ta: "வேகமாக அழுத்தவும்! 2 அங்குல ஆழம். பீட் சத்தத்துடன் அழுத்தவும்!",
              te: "బలంగా నొక్కండి! 2 అంగుళాల లోతుకు. శబ్దానికి అనుగుణంగా నొక్కండి!",
              hi: "जोर से दबाएं! 2 इंच गहरा। बीट के साथ ताल मिलाएं!",
              ml: "ശക്തിയായി അമർത്തുക! 2 ഇഞ്ച് താഴ്ചയിൽ. താളത്തിനൊത്ത് അമർത്തുക!",
            ),
            detailed: const LocalizedContent(
              en: "Push down at least 2 inches (5 cm) at 100-120 compressions per minute. Allow the chest to come completely up between pushes. Keep going until paramedics arrive.",
              kn: "ನಿಮಿಷಕ್ಕೆ 100 ರಿಂದ 120 ರ ವೇಗದಲ್ಲಿ ಕನಿಷ್ಠ 2 ಇಂಚು ಆಳಕ್ಕೆ ಒತ್ತಿರಿ. ಪ್ರತಿ ಬಾರಿಯೂ ಎದೆ ಸಹಜ ಸ್ಥಿತಿಗೆ ಬರಲು ಬಿಡಿ. ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೆ ನಿಲ್ಲಿಸಬೇಡಿ.",
              ta: "நிமிடத்திற்கு 100 முதல் 120 முறை 2 அங்குல ஆழத்தில் அழுத்தவும். ஒவ்வொரு முறை அழுத்திய பின் நெஞ்சு இயல்பு நிலைக்கு வரவிடவும். மருத்துவர்கள் வரும் வரை நிறுத்த வேண்டாம்.",
              te: "నిమిషానికి 100 నుండి 120 సార్లు 2 అంగుళాల లోతుకు నొక్కండి. ప్రతిసారీ ఛాతీ పైకి రావడానికి అనుమతించండి. సిబ్బంది వచ్చేవరకు ఆపకండి.",
              hi: "100 से 120 प्रति मिनट की गति से कम से कम 2 इंच गहरा दबाएं। हर बार छाती को पूरा ऊपर आने दें। एम्बुलेंस आने तक रुकें नहीं।",
              ml: "മിനിറ്റിൽ 100 മുതൽ 120 തവണ 2 ഇഞ്ച് താഴ്ചയിൽ അമർത്തുക. ഓരോ അമർത്തലിനും ശേഷം നെഞ്ച് ഉയരാൻ അനുവദിക്കുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Push hard and fast to the beat. Count 1, 2, 3, 4. Do not stop.",
              kn: "ಲಯಬದ್ಧವಾಗಿ ಬಲವಾಗಿ ಒತ್ತುತ್ತಿರಿ. 1, 2, 3, 4. ನಿಲ್ಲಿಸಬೇಡಿ.",
              ta: "பீட் உடன் சேர்த்து அழுத்தவும். 1, 2, 3, 4. நிறுத்த வேண்டாம்.",
              te: "శబ్దంతో పాటు బలంగా నొక్కండి. 1, 2, 3, 4. ఆపకండి.",
              hi: "बीट के साथ तेजी से दबाते रहें। 1, 2, 3, 4. रुकें नहीं।",
              ml: "താളത്തിനൊത്ത് അമർത്തുക. 1, 2, 3, 4. നിർത്തരുത്.",
            ),
          ),
        ];

      case "CHOKING":
        return [
          EmergencyStep(
            stepDurationSeconds: 15,
            hasMetronome: false,
            // 5 Back blows: leaning forward, palm striking between shoulder blades
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Heimlich_maneuver_adult.svg/640px-Heimlich_maneuver_adult.svg.png",
            title: const LocalizedContent(
              en: "Step 1: 5 Sharp Back Blows",
              kn: "ಹಂತ 1: ಬೆನ್ನಿಗೆ 5 ಬಾರಿ ಬಡಿಯಿರಿ",
              ta: "படி 1: முதுகில் 5 முறை தட்டவும்",
              te: "దశ 1: వెనుకభాగంలో 5 సార్లు కొట్టండి",
              hi: "चरण 1: पीठ पर 5 बार थपथपाएं",
              ml: "ഘട്ടം 1: മുതുകിൽ 5 തവണ തട്ടുക",
            ),
            quickTip: const LocalizedContent(
              en: "Lean forward. 5 firm strikes between shoulder blades with heel of hand.",
              kn: "ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ. ಭುಜಗಳ ಮಧ್ಯೆ ಕೈಯಿಂದ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ.",
              ta: "முன்னோக்கி சாய்க்கவும். தோள்பட்டைகளுக்கு இடையே 5 முறை தட்டவும்.",
              te: "ముందుకు వంచండి. భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి.",
              hi: "आगे झुकाएं। दोनों कंधों के बीच हथेली से 5 बार जोर से थपथपाएं।",
              ml: "മുന്നോട്ട് ആഞ്ഞ് നിൽക്കുക. തോളിന് ഇടയിൽ 5 തവണ തട്ടുക.",
            ),
            detailed: const LocalizedContent(
              en: "Support the chest with one hand. Lean the victim forward so the obstruction expels outward. Deliver 5 sharp, forceful blows between shoulder blades.",
              kn: "ಒಂದು ಕೈಯಿಂದ ಎದೆಯನ್ನು ಹಿಡಿದು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ. ನಿಮ್ಮ ಕೈಯ ಹಿಮ್ಮಡಿಯಿಂದ ಭುಜಗಳ ಮಧ್ಯೆ 5 ಬಾರಿ ತಟ್ಟಿ.",
              ta: "ஒரு கையால் மார்பைத் தாங்கி முன்னோக்கி சாய்க்கவும். உள்ளங்கையால் தோள்பட்டை நடுவில் 5 முறை தட்டவும்.",
              te: "ఒక చేత్తో ఛాతీని పట్టుకుని ముందుకు వంచండి. అరచేతితో భుజాల మధ్య 5 సార్లు కొట్టండి.",
              hi: "एक हाथ से छाती को सहारा देकर आगे झुकाएं। हथेली के निचले हिस्से से दोनों कंधों के बीच 5 बार थपथपाएं।",
              ml: "ഒരു കൈകൊണ്ട് നെഞ്ചിൽ താങ്ങി മുന്നോട്ട് ചരിക്കുക. കൈപ്പത്തി കൊണ്ട് മുതുകിൽ 5 തവണ തട്ടുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Lean them forward. Give five firm blows between their shoulder blades.",
              kn: "ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ ಬೆನ್ನಿನ ಮಧ್ಯೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ.",
              ta: "முன்னோக்கி சாய்த்து முதுகில் 5 முறை தட்டவும்.",
              te: "ముందుకు వంచి వెనుక 5 సార్లు కొట్టండి.",
              hi: "उन्हें आगे झुकाएं और पीठ पर पांच बार थपथपाएं।",
              ml: "മുന്നോട്ട് ചരിച്ച് മുതുകിൽ 5 തവണ തട്ടുക.",
            ),
          ),
          EmergencyStep(
            stepDurationSeconds: 15,
            hasMetronome: false,
            // Heimlich maneuver: rescuer standing behind, fist above navel, pulling inward and upward
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Heimlich_maneuver.svg/640px-Heimlich_maneuver.svg.png",
            title: const LocalizedContent(
              en: "Step 2: 5 Abdominal Thrusts (Heimlich)",
              kn: "ಹಂತ 2: ಹೊಟ್ಟೆಯ ಮೇಲ್ಭಾಗ ಒತ್ತಿರಿ",
              ta: "படி 2: அடிவயிற்றில் மேல்நோக்கி அழுத்தவும்",
              te: "దశ 2: పొట్ట పైభాగాన్ని పైకి నొక్కండి",
              hi: "चरण 2: पेट को अंदर और ऊपर की ओर दबाएं (हाइमलिक)",
              ml: "ഘട്ടം 2: വയറ്റിൽ മുകളിലേക്ക് അമർത്തുക",
            ),
            quickTip: const LocalizedContent(
              en: "Fist above navel. Pull inward & upward sharply 5 times.",
              kn: "ಹೊಕ್ಕುಳಿನ ಮೇಲೆ ಮುಷ್ಟಿ ಇಟ್ಟು ಒಳಗೆ ಮತ್ತು ಮೇಲಕ್ಕೆ ಎಳೆಯಿರಿ.",
              ta: "தொப்புளுக்கு மேலே கையை வைத்து உள்நோக்கியும் மேல்நோக்கியும் அழுத்தவும்.",
              te: "బొడ్డు పైభాగంలో పిడికిలి ఉంచి లోపలికి మరియు పైకి నొక్కండి.",
              hi: "नाभि के ठीक ऊपर मुट्ठी रखें और अंदर तथा ऊपर की ओर 5 बार झटका दें।",
              ml: "പൊക്കിളിന് മുകളിൽ മുഷ്ടി വെച്ച് ഉള്ളിലേക്കും മുകളിലേക്കും വലിക്കുക.",
            ),
            detailed: const LocalizedContent(
              en: "Stand behind the person. Place the thumb side of your fist just above the navel. Grasp fist with your other hand. Pull sharply inward and upward.",
              kn: "ವ್ಯಕ್ತಿಯ ಹಿಂದೆ ನಿಂತು ಹೊಕ್ಕುಳಿನ ಮೇಲೆ ಮುಷ್ಟಿ ಇಡಿ. ಇನ್ನೊಂದು ಕೈಯಿಂದ ಹಿಡಿದು ಒಳಮುಖ ಮತ್ತು ಮೇಲ್ಮುಖವಾಗಿ ತೀವ್ರವಾಗಿ ಒತ್ತಿರಿ.",
              ta: "நபருக்கு பின்னால் நின்று தொப்புளுக்கு மேலே முஷ்டியை வைக்கவும். மற்றொரு கையால் பிடித்து மேல்நோக்கி அழுத்தவும்.",
              te: "వ్యక్తి వెనుక నిలబడి బొడ్డు పైభాగంలో పిడికిలిని ఉంచండి. మరో చేత్తో పట్టుకుని పైకి బలంగా లాగండి.",
              hi: "व्यक्ति के पीछे खड़े होकर नाभि के ऊपर मुट्ठी रखें। दूसरे हाथ से पकड़कर तेजी से अंदर और ऊपर की ओर खींचें।",
              ml: "വ്യക്തിയുടെ പിന്നിൽ നിന്ന് പൊക്കിളിന് മുകളിൽ മുഷ്ടി വെക്കുക. മുകളിലേക്ക് ശക്തിയായി വലിക്കുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Pull inward and upward sharply just above the navel. Repeat five times.",
              kn: "ಹೊಕ್ಕುಳಿನ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಒಳಮುಖ ಮತ್ತು ಮೇಲ್ಮುಖವಾಗಿ ತೀವ್ರವಾಗಿ ಒತ್ತಿರಿ.",
              ta: "தொப்புளுக்கு மேலே உள்நோக்கியும் மேல்நோக்கியும் 5 முறை அழுத்தவும்.",
              te: "బొడ్డు పైభాగంలో లోపలికి పైకి బలంగా లాగండి.",
              hi: "नाभि के ऊपर अंदर और ऊपर की ओर तेजी से 5 बार झटका दें।",
              ml: "പൊക്കിളിന് മുകളിൽ ഉള്ളിലേക്കും മുകളിലേക്കും അമർത്തുക.",
            ),
          ),
        ];

      case "BLEEDING":
        return [
          EmergencyStep(
            stepDurationSeconds: 15,
            hasMetronome: false,
            // Direct pressure application with clean cloth/gauze directly over wound
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Direct_pressure.svg/640px-Direct_pressure.svg.png",
            title: const LocalizedContent(
              en: "Step 1: Direct Firm Pressure",
              kn: "ಹಂತ 1: ಗಾಯದ ಮೇಲೆ ನೇರ ಒತ್ತಡ",
              ta: "படி 1: காயத்தில் நேரடி அழுத்தம்",
              te: "దశ 1: గాయంపై నేరుగా ఒత్తిడి",
              hi: "चरण 1: घाव पर सीधा दबाव बनाएं",
              ml: "ഘട്ടം 1: മുറിവിൽ നേരിട്ട് അമർത്തുക",
            ),
            quickTip: const LocalizedContent(
              en: "PRESS DIRECTLY WITH CLOTH! Do not lift hands.",
              kn: "ಬಟ್ಟೆಯಿಂದ ಗಾಯವನ್ನು ಬಲವಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ! ಕೈ ತೆಗೆಯಬೇಡಿ.",
              ta: "துணியால் காயத்தை அழுத்திப் பிடிக்கவும்! கையை எடுக்க வேண்டாம்.",
              te: "బట్టతో గాయంపై బలంగా నొక్కండి! చేతిని తీయవద్దు.",
              hi: "साफ कपड़े से घाव को कसकर दबाएं! हाथ न हटाएं।",
              ml: "തുണികൊണ്ട് മുറിവിൽ അമർത്തിപ്പിടിക്കുക! കൈ മാറ്റരുത്.",
            ),
            detailed: const LocalizedContent(
              en: "Apply firm, continuous pressure directly on the wound using a clean cloth or bandage. Do not lift the cloth to check. If blood soaks through, add another cloth on top.",
              kn: "ಶುದ್ಧ ಬಟ್ಟೆಯಿಂದ ಗಾಯದ ಮೇಲೆ ನೇರವಾಗಿ ಬಲವಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. ರಕ್ತ ನಿಲ್ಲುವವರೆಗೆ ಕೈ ಸಡಿಲಿಸಬೇಡಿ. ಬಟ್ಟೆ ತೋಯ್ದರೆ ಅದರ ಮೇಲೆಯೇ ಮತ್ತೊಂದು ಬಟ್ಟೆ ಇಡಿ.",
              ta: "சுத்தமான துணியால் காயத்தின் மீது தொடர்ச்சியாக அழுத்தம் கொடுக்கவும். துணி நனைந்தால் மேலே மற்றொரு துணியை வைக்கவும்.",
              te: "శుభ్రమైన బట్టతో గాయంపై నిరంతరంగా ఒత్తిడి ఉంచండి. బట్ట తడిసినా తీయకుండా దానిపైనే మరొకటి ఉంచండి.",
              hi: "घाव पर साफ कपड़े से लगातार दबाव बनाए रखें। हाथ उठाकर न देखें। कपड़ा भीगने पर उसके ऊपर दूसरा कपड़ा रखें।",
              ml: "വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ അമർത്തുക. തുണി നനഞ്ഞാലും മാറ്റാതെ മീതെ വേറെ തുണി വയ്ക്കുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Press firmly on the wound with a clean cloth. Do not lift your hands.",
              kn: "ಗಾಯದ ಮೇಲೆ ಬಟ್ಟೆ ಇಟ್ಟು ಬಲವಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. ಕೈ ಸಡಿಲಿಸಬೇಡಿ.",
              ta: "துணியால் காயத்தை அழுத்திப் பிடிக்கவும். கையை எடுக்க வேண்டாம்.",
              te: "గాయంపై బట్టతో బలంగా నొక్కండి. చేతిని తీయకండి.",
              hi: "घाव पर साफ कपड़े से लगातार दबाव बनाए रखें। हाथ न हटाएं।",
              ml: "തുണികൊണ്ട് മുറിവിൽ അമർത്തിപ്പിടിക്കുക. കൈ മാറ്റരുത്.",
            ),
          ),
          EmergencyStep(
            stepDurationSeconds: 12,
            hasMetronome: false,
            // Limb elevation above heart level combined with roller bandage wrapping
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Elevation_of_limb.svg/640px-Elevation_of_limb.svg.png",
            title: const LocalizedContent(
              en: "Step 2: Elevate Injured Limb",
              kn: "ಹಂತ 2: ಗಾಯಗೊಂಡ ಅಂಗವನ್ನು ಎತ್ತರಿಸಿ",
              ta: "படி 2: காயம்பட்ட பகுதியை உயர்த்தவும்",
              te: "దశ 2: గాయపడిన భాగాన్ని ఎత్తులో ఉంచండి",
              hi: "चरण 2: घायल अंग को ऊपर उठाएं",
              ml: "ഘട്ടം 2: മുറിവേറ്റ ഭാഗം ഉയർത്തി വയ്ക്കുക",
            ),
            quickTip: const LocalizedContent(
              en: "RAISE ABOVE HEART LEVEL. Wrap tightly with cloth/bandage.",
              kn: "ಹೃದಯದ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ. ಬಿಗಿಯಾಗಿ ಬ್ಯಾಂಡೇಜ್ ಕಟ್ಟಿ.",
              ta: "இதய மட்டத்திற்கு மேல் உயர்த்தவும். இறுக்கமாகக் கட்டவும்.",
              te: "గుండె స్థాయి కంటే పైకి ఎత్తండి. గట్టిగా కట్టు కట్టండి.",
              hi: "दिल के स्तर से ऊपर उठाएं। कसकर पट्टी बांधें।",
              ml: "ഹൃദയത്തിന്റെ നിരപ്പിന് മുകളിൽ ഉയർത്തുക. തുണികൊണ്ട് മുറുക്കി കെട്ടുക.",
            ),
            detailed: const LocalizedContent(
              en: "If no bones are broken, elevate the bleeding limb above the level of the heart to slow arterial flow. Wrap tightly with a bandage while waiting for the 112 ambulance.",
              kn: "ಮೂಳೆ ಮುರಿತವಿಲ್ಲದಿದ್ದರೆ ಗಾಯವಾದ ಅಂಗವನ್ನು ಹೃದಯಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ ರಕ್ತದ ಹರಿವನ್ನು ಕಡಿಮೆ ಮಾಡಿ. ಬಿಗಿಯಾಗಿ ಬ್ಯಾಂಡೇಜ್ ಕಟ್ಟಿ 112 ಗೆ ಕರೆ ಮಾಡಿ.",
              ta: "எலும்பு முறிவு இல்லை என்றால் காயம்பட்ட பகுதியை இதய நிலைக்கு மேலே உயர்த்தி வைக்கவும். 112 ஐ அழைக்கவும்.",
              te: "ఎముక విరగకపోతే గాయపడిన భాగాన్ని గుండె కంటే ఎత్తులో ఉంచండి. 112 కు కాల్ చేయండి.",
              hi: "हड्डी न टूटी होने पर अंग को दिल से ऊपर उठाएं ताकि रक्तप्रवाह कम हो, और कसकर पट्टी बांधें।",
              ml: "എല്ലിന് പൊട്ടലില്ലെങ്കിൽ മുറിവേറ്റ ഭാഗം ഹൃദയത്തിന് മുകളിലേക്ക് ഉയർത്തി വയ്ക്കുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Keep the limb elevated above heart level and wait for the ambulance.",
              kn: "ಅಂಗವನ್ನು ಎತ್ತರದಲ್ಲೇ ಇರಿಸಿ. ಆಂಬ್ಯುಲೆನ್ಸ್‌ಗಾಗಿ ಕಾಯಿರಿ.",
              ta: "காயம்பட்ட பகுதியை உயர்த்தி வைத்திருக்கவும்.",
              te: "గాయపడిన భాగాన్ని ఎత్తులోనే ఉంచండి.",
              hi: "घायल अंग को ऊपर उठाकर रखें और एम्बुलेंस की प्रतीक्षा करें।",
              ml: "മുറിവേറ്റ ഭാഗം ഉയർത്തിപ്പിടിച്ച് ആംബുലൻസിനായി കാത്തിരിക്കുക.",
            ),
          ),
        ];

      case "SPINAL":
        return [
          EmergencyStep(
            stepDurationSeconds: 15,
            hasMetronome: false,
            // Motorcyclist crash posture with helmet on: rescuer stabilizing head manually without moving the neck
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Manual_in-line_stabilization.svg/640px-Manual_in-line_stabilization.svg.png",
            title: const LocalizedContent(
              en: "Step 1: DO NOT MOVE THE PERSON",
              kn: "ಹಂತ 1: ವ್ಯಕ್ತಿಯನ್ನು ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ಚಲಿಸಬೇಡಿ",
              ta: "படி 1: நபரை அசைக்க வேண்டாம்",
              te: "దశ 1: వ్యక్తిని కదిలించవద్దు",
              hi: "चरण 1: व्यक्ति को बिल्कुल न हिलाएं",
              ml: "ഘട്ടം 1: വ്യക്തിയെ അനക്കരുത്",
            ),
            quickTip: const LocalizedContent(
              en: "DO NOT MOVE! DO NOT REMOVE HELMET! Protect spinal cord.",
              kn: "ಅಲುಗಾಡಿಸಬೇಡಿ! ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ! ಬೆನ್ನುಹುರಿ ರಕ್ಷಿಸಿ.",
              ta: "அசைக்க வேண்டாம்! ஹெல்மெட்டை கழற்ற வேண்டாம்!",
              te: "కదిలించవద్దు! హెல்మెట్ తీయవద్దు!",
              hi: "हिलाएं नहीं! हेलमेट न निकालें! रीढ़ की हड्डी को सुरक्षित रखें।",
              ml: "അനക്കരുത്! ഹെൽമെറ്റ് മാറ്റരുത്!",
            ),
            detailed: const LocalizedContent(
              en: "Do not move the victim or remove their helmet. Unnecessary movement can cause permanent spinal cord severance and paralysis. Keep them in the exact position found.",
              kn: "ವ್ಯಕ್ತಿಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ ಮತ್ತು ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ. ಕುತ್ತಿಗೆ ಅಲುಗಾಡಿದರೆ ಪಾರ್ಶ್ವವಾಯು ಉಂಟಾಗಬಹುದು. ಇದ್ದ ಜಾಗದಲ್ಲೇ ಇರಿಸಿ.",
              ta: "நபரை அசைக்கவோ ஹெல்மெட்டை கழற்றவோ கூடாது. அசைத்தால் பக்கவாதம் ஏற்படலாம்.",
              te: "వ్యక్తిని కదిలించవద్దు మరియు హెల్మెట్ తీయవద్దు. కదిలిస్తే పక్షవాతం రావచ్చు.",
              hi: "व्यक्ति को बिल्कुल न हिलाएं और हेलमेट न उतारें। गर्दन हिलने से रीढ़ की हड्डी को गंभीर नुकसान हो सकता है।",
              ml: "വ്യക്തിയെ അനക്കുകയോ ഹെൽമെറ്റ് മാറ്റുകയോ ചെയ്യരുത്. ചലിച്ചാൽ തളർവാതം വരാം.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Do not move the person. Do not take off their helmet. Keep them still.",
              kn: "ವ್ಯಕ್ತಿಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ. ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ.",
              ta: "நபரை அசைக்க வேண்டாம். ஹெல்மெட்டை எடுக்க வேண்டாம்.",
              te: "వ్యక్తిని కదిలించవద్దు. హెల్మెట్ తీయవద్దు.",
              hi: "व्यक्ति को न हिलाएं और न ही हेलमेट निकालें। उन्हें स्थिर रखें।",
              ml: "വ്യക്തിയെ അനക്കരുത്. ഹെൽമെറ്റ് മാറ്റരുത്.",
            ),
          ),
          EmergencyStep(
            stepDurationSeconds: 15,
            hasMetronome: false,
            // Two hands holding the sides of the head in neutral alignment
            visualAsset: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Cervical_spine_stabilization.svg/640px-Cervical_spine_stabilization.svg.png",
            title: const LocalizedContent(
              en: "Step 2: Hold Head Still",
              kn: "ಹಂತ 2: ತಲೆಯನ್ನು ಭದ್ರವಾಗಿ ಹಿಡಿದುಕೊಳ್ಳಿ",
              ta: "படி 2: தலையை அசையாமல் பிடிக்கவும்",
              te: "దశ 2: తల కదలకుండా పట్టుకోండి",
              hi: "चरण 2: सिर को दोनों हाथों से थामे रखें",
              ml: "ഘട്ടം 2: തല അനങ്ങാതെ പിടിക്കുക",
            ),
            quickTip: const LocalizedContent(
              en: "Kneel at head. Hold both sides of head firmly until 112 arrives.",
              kn: "ತಲೆಯ ಬಳಿ ಕುಳಿತು ಎರಡೂ ಕೈಗಳಿಂದ ತಲೆಯನ್ನು ಅಲುಗಾಡದಂತೆ ಹಿಡಿಯಿರಿ.",
              ta: "தலையின் பக்கவாட்டில் அமர்ந்து இரண்டு கைகளாலும் அசையாமல் பிடிக்கவும்.",
              te: "తల దగ్గర కూర్చుని రెండు చేతులతో కదలకుండా పట్టుకోండి.",
              hi: "सिर के पास बैठें और दोनों हाथों से सिर को स्थिर रखें जब तक 112 न आ जाए।",
              ml: "തലയുടെ ഇരുവശത്തും കൈകൾ വച്ച് അനങ്ങാതെ പിടിക്കുക.",
            ),
            detailed: const LocalizedContent(
              en: "Kneel at the top of their head. Place both hands firmly on either side of their head or helmet to prevent any head rotation or neck flexion until the ambulance arrives.",
              kn: "ವ್ಯಕ್ತಿಯ ತಲೆಯ ಬಳಿ ಕುಳಿತು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ಎರಡೂ ಬದಿಗಳಿಂದ ತಲೆಯನ್ನು ಭದ್ರವಾಗಿ ಹಿಡಿದುಕೊಳ್ಳಿ.",
              ta: "தலையின் அருகே மண்டியிட்டு, கழுத்து அசையாமல் இருக்க தலையின் இருபுறமும் கைகளை வைத்து பிடிக்கவும்.",
              te: "తల పక్కన కూర్చుని మెడ కదలకుండా రెండు చేతులతో గట్టిగా పట్టుకోండి.",
              hi: "सिर के पास बैठकर दोनों हाथों से सिर को ऐसे पकड़ें कि गर्दन बिल्कुल न हिले।",
              ml: "കഴുത്ത് അനങ്ങാതിരിക്കാൻ തല ഇരുവശത്തും കൈകൾ വെച്ച് മുറുകെ പിടിക്കുക.",
            ),
            audioPrompt: const LocalizedContent(
              en: "Hold both sides of the head still until the ambulance team arrives.",
              kn: "ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೆ ತಲೆಯ ಎರಡೂ ಬದಿಗಳನ್ನು ಹಿಡಿದು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ನೋಡಿ.",
              ta: "ஆம்புலன்ஸ் வரும் வரை தலையை அசையாமல் பிடித்துக் கொள்ளவும்.",
              te: "అంబులెన్స్ వచ్చేవరకు తలను కదలకుండా పట్టుకోండి.",
              hi: "एम्बुलेंस आने तक सिर को दोनों तरफ से स्थिर थामे रखें।",
              ml: "ആംബുലൻസ് വരുന്നത് വരെ തല അനങ്ങാതെ പിടിക്കുക.",
            ),
          ),
        ];

      default:
        return getAdaptiveProtocol(
          emergencyType: "CPR",
          isVictimResponsive: isVictimResponsive,
          isVictimBreathing: isVictimBreathing,
          isHelperPanicked: isHelperPanicked,
          isHelperAlone: isHelperAlone,
        );
    }
  }
}