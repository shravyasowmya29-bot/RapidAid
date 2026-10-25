import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/dedicated_emergency_painter.dart';

class ActiveRescueScreen extends StatefulWidget {
  final String protocolKey;
  final String language;

  const ActiveRescueScreen({
    super.key,
    required this.protocolKey,
    required this.language,
  });

  @override
  State<ActiveRescueScreen> createState() => _ActiveRescueScreenState();
}

class _ActiveRescueScreenState extends State<ActiveRescueScreen>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _metronomeController;
  Timer? _hapticTimer;

  // Map each protocol key directly to its infographic asset
  final Map<String, String> _protocolImages = {
    "CPR": "assets/images/cpr_guide.png",
    "BLEEDING": "assets/images/bleeding_guide.png",
    "CHOKING": "assets/images/choking_guide.png",
    "SPINAL_CAUTION": "assets/images/spinal_guide.png",
    "BLEEDING_AND_HELMET": "assets/images/spinal_guide.png", // Shows spinal lock on step 0, bleeding on step 1
  };

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
          "te": "రెండు నిపుల్స్ మధ్యలో ఛాతీ ఎముకపై ఒక చేతి మడమను నేరుగా ఉంచండి.",
          "ml": "നെഞ്ചിന്റെ മധ്യഭാഗത്ത് കൈപ്പത്തിയുടെ അടിഭാഗം ഉറപ്പിച്ചു വെയ്ക്കുക.",
        },
        "desc": {
          "en": "Look at Step 1 in the diagram above. Keep only the palm heel touching the bone.",
          "kn": "ಚಿತ್ರದಲ್ಲಿರುವ ಹಂತ 1 ನೋಡಿ. ಕೇವಲ ಕೈಯ ಹಿಮ್ಮಡಿ ಮಾತ್ರ ಎದೆ ಮೂಳೆ ಮುಟ್ಟಲಿ.",
          "hi": "ऊपर दिए चित्र में चरण 1 देखें। केवल हथेली का निचला भाग हड्डी को छुए।",
          "ta": "படத்தில் படி 1-ஐ பார்க்கவும். உள்ளங்கையின் அடிப்பகுதி மட்டுமே பட வேண்டும்.",
          "te": "పై చిత్రంలో దశ 1 చూడండి. చేతి మడమ మాత్రమే ఎముకను తాకాలి.",
          "ml": "മുകളിലെ ചിത്രത്തിൽ ഘട്ടം 1 കാണുക. കൈപ്പത്തിയുടെ അടിഭാഗം മാത്രം മുട്ടിക്കുക.",
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
          "en": "Look at Step 2 in the diagram above. This transfers full downward body force.",
          "kn": "ಚಿತ್ರದಲ್ಲಿರುವ ಹಂತ 2 ನೋಡಿ. ಇದು ದೇಹದ ಪೂರ್ಣ ಬಲವನ್ನು ಕೆಳಮುಖವಾಗಿ ಹಾಕಲು ನೆರವಾಗುತ್ತದೆ.",
          "hi": "ऊपर दिए चित्र में चरण 2 देखें। यह पूरे शरीर का भार डालने में मदद करता है।",
          "ta": "படத்தில் படி 2-ஐ பார்க்கவும். இது முழு அழுத்தத்தை கொடுக்க உதவும்.",
          "te": "పై చిత్రంలో దశ 2 చూడండి. ఇది శరీర బలాన్ని కిందకు ప్రసరింపజేస్తుంది.",
          "ml": "മുകളിലെ ചിത്രത്തിൽ ഘട്ടം 2 കാണുക. ഇത് കൃത്യമായ മർദ്ദം നൽകുന്നു.",
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
          "en": "Bring shoulders directly above hands. Lock arms completely straight at 90 degrees.",
          "kn": "ವ್ಯಕ್ತಿಯ ಪಕ್ಕದಲ್ಲಿ ಮಂಡಿಯೂರಿ, ಭುಜಗಳನ್ನು ಕೈಗಳ ನೇರಕ್ಕೆ ತಂದು ಮೊಣಕೈ ಮಣಿಸದೆ ನೇರವಾಗಿಡಿ.",
          "hi": "घुटने टेकें। कंधों को सीधे हाथों के ऊपर लाएं। बांहें 90 डिग्री सीधी रखें।",
          "ta": "மண்டியிட்டு அமரவும். தோள்களை கைகளுக்கு மேல் கொண்டு வந்து கைகளை நேராக வைக்கவும்.",
          "te": "మోకరిల్లి కూర్చోండి. భుజాలను చేతులపై ఉంచి చేతులను నిలువుగా ఉంచండి.",
          "ml": "മുട്ടുകുത്തി ഇരിക്കുക. തോൾ കൈകൾക്ക് നേരെ മുകളിലാക്കി കൈകൾ നിവർത്തി പിടിക്കുക.",
        },
        "desc": {
          "en": "Look at Step 3 dotted line in the diagram. Do not bend your elbows.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಚುಕ್ಕೆಗಳ ಗೆರೆ ನೋಡಿ (ಹಂತ 3). ಮೊಣಕೈ ಮಣಿಸಬೇಡಿ.",
          "hi": "चित्र में बिंदु वाली रेखा (चरण 3) देखें। कोहनी बिल्कुल न मोड़ें।",
          "ta": "படத்தில் உள்ள புள்ளியிடப்பட்ட கோட்டை (படி 3) பார்க்கவும்.",
          "te": "చిత్రంలో చుక్కల గీతను (దశ 3) చూడండి. మోచేతులు వంచకండి.",
          "ml": "ചിത്രത്തിലെ വര ശ്രദ്ധിക്കുക (ഘട്ടം 3). കൈ മടക്കരുത്.",
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
          "en": "Push hard and fast to the metronome pulse. Allow complete chest recoil between pushes.",
          "kn": "ಬಲವಾಗಿ ಮತ್ತು ವೇಗವಾಗಿ ಒತ್ತಿರಿ. ಪ್ರತಿ ಬಾರಿಯೂ ಎದೆ ಸಹಜ ಸ್ಥಿತಿಗೆ ಬರಲು ಬಿಡಿ.",
          "hi": "तेजी और जोर से दबाएं। हर दबाव के बाद छाती को पूरी तरह ऊपर आने दें।",
          "ta": "வேகமாகவும் பலமாகவும் அழுத்தவும். ஒவ்வொரு அழுத்தத்திற்குப் பிறகும் நெஞ்சு மேலே வரவிடவும்.",
          "te": "వేగంగా బలంగా నొక్కండి. ప్రతిసారీ ఛాతీ పైకి రావడానికి వీలు కల్పించండి.",
          "ml": "വേഗത്തിലും ശക്തിയിലും അമർത്തുക. നെഞ്ച് പൂർണ്ണമായി ഉയരാൻ അനുവദിക്കുക.",
        },
        "desc": {
          "en": "Look at Step 4 arrow in the diagram. Match the 110 BPM beat rhythm.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಬಾಣದ ಗುರುತು ಗಮನಿಸಿ. ಮೆಟ್ರೊನೊಮ್ ಶಬ್ದದ ಜೊತೆ ಒತ್ತಿರಿ.",
          "hi": "चित्र में तीर का निशान देखें। बीट की ताल पर लगातार दबाएं।",
          "ta": "படத்தில் உள்ள அம்புக்குறியைப் பார்க்கவும். பீட் உடன் அழுத்தவும்.",
          "te": "చిత్రంలో బాణం గుర్తును చూడండి. శబ్దంతో పాటు నొక్కండి.",
          "ml": "ചിത്രത്തിലെ അമ്പ് ശ്രദ്ധിക്കുക. താളത്തിനൊത്ത് ചെയ്യുക.",
        }
      },
      {
        "title": {
          "en": "Step 5: Do NOT Stop Until Paramedics Arrive",
          "kn": "ಹಂತ 5: ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೂ ನಿಲ್ಲಿಸಬೇಡಿ",
          "hi": "चरण 5: एम्बुलेंस आने तक रुकें नहीं",
          "ta": "படி 5: ஆம்புலன்ஸ் வரும் வரை நிறுத்த வேண்டாம்",
          "te": "దశ 5: అంబులెన్స్ వచ్చేవరకు ఆపకండి",
          "ml": "ഘട്ടം 5: ആംബുലൻസ് വരുന്നത് വരെ നിർത്തരുത്",
        },
        "action": {
          "en": "Continue compressions without stopping. You are supplying oxygen to the brain.",
          "kn": "ಎದೆ ಒತ್ತುವುದನ್ನು ಮುಂದುವರಿಸಿ. ನೀವು ಮಿದುಳಿಗೆ ಆಮ್ಲಜನಕವನ್ನು ರವಾನಿಸುತ್ತಿದ್ದೀರಿ.",
          "hi": "लगातार दबाते रहें। आप दिमाग तक प्राणवायु पहुंचा रहे हैं।",
          "ta": "தொடர்ந்து அழுத்தவும். மூளைக்கு தேவையான ஆக்ஸிஜனை செலுத்துகிறீர்கள்.",
          "te": "నొక్కుతూనే ఉండండి. మీరు మెదడుకు ఆక్సిజన్‌ను సరఫరా చేస్తున్నారు.",
          "ml": "അമർത്തുന്നത് തുടരുക. ഇത് തലച്ചോറിലേക്ക് ഓക്സിജൻ എത്തിക്കുന്നു.",
        },
        "desc": {
          "en": "Look at Step 5 in the diagram. If exhausted, swap with another bystander.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಹಂತ 5 ನೋಡಿ. ಆಯಾಸವಾದರೆ ಇನ್ನೊಬ್ಬರಿಗೆ ಜವಾಬ್ದಾರಿ ನೀಡಿ.",
          "hi": "चित्र में चरण 5 देखें। थकने पर तुरंत दूसरे मददगार को सौंपें।",
          "ta": "படத்தில் படி 5-ஐ பார்க்கவும். களைப்படைந்தால் மற்றொருவரை மாற்றவும்.",
          "te": "చిత్రంలో దశ 5 చూడండి. అలసిపోతే వేరొకరికి అప్పగించండి.",
          "ml": "ചിത്രത്തിൽ ഘട്ടം 5 കാണുക. അടുത്തയാളെക്കൊണ്ട് ചെയ്യിക്കുക.",
        }
      }
    ],
    "BLEEDING": [
      {
        "title": {
          "en": "Step 1: DIRECT DOWNWARD PRESSURE ON WOUND SITE",
          "kn": "ಹಂತ 1: ಗಾಯದ ಜಾಗದ ಮೇಲೆ ನೇರ ಕೆಳಮುಖ ಒತ್ತಡ",
          "hi": "चरण 1: घाव पर सीधा नीचे की ओर दबाव बनाएं",
          "ta": "படி 1: காயத்தின் மீது நேரடி கீழ்நோக்கிய அழுத்தம்",
          "te": "దశ 1: గాయంపై నేరుగా కిందకు ఒత్తిడి ఉంచండి",
          "ml": "ഘട്ടം 1: മുറിവിൽ നേരിട്ട് താഴേക്ക് അമർത്തുക",
        },
        "action": {
          "en": "Check precautions on image: If no fracture, press clean cloth directly on wound with full palm force.",
          "kn": "ಚಿತ್ರದಲ್ಲಿರುವ ಮುನ್ನೆಚ್ಚರಿಕೆ ಗಮನಿಸಿ: ಮೂಳೆ ಮುರಿದಿಲ್ಲದಿದ್ದರೆ, ಶುದ್ಧ ಬಟ್ಟೆಯನ್ನು ಗಾಯದ ಮೇಲಿಟ್ಟು ಒತ್ತಿ ಹಿಡಿಯಿರಿ.",
          "hi": "चित्र में सावधानियां देखें: हड्डी न टूटी हो तो साफ कपड़े से घाव पर पूरी हथेली से दबाएं।",
          "ta": "எலும்பு முறிவு இல்லை என்றால், சுத்தமான துணியை காயத்தின் மீது வைத்து அழுத்தவும்.",
          "te": "ఎముక విరగకపోతే శుభ్రమైన గుడ్డను గాయంపై ఉంచి అరచేతితో గట్టిగా నొక్కండి.",
          "ml": "എല്ല് പൊട്ടിയിട്ടില്ലെങ്കിൽ വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ ശക്തിയായി അമർത്തുക.",
        },
        "desc": {
          "en": "Look at Step 1 blue arrow on image. Do not lift hand to check bleeding.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ನೀಲಿ ಬಾಣದ ಗುರುತು ನೋಡಿ. ರಕ್ತ ನೋಡಲು ಕೈ ತೆಗೆಯಬೇಡಿ.",
          "hi": "चित्र में नीला तीर (Step 1) देखें। हाथ बिल्कुल न उठाएं।",
          "ta": "படத்தில் நீல அம்புக்குறியை (Step 1) பார்க்கவும். கையை எடுக்க வேண்டாம்.",
          "te": "చిత్రంలో నీలి బాణం గుర్తు (Step 1) చూడండి. చేతిని తీయవద్దు.",
          "ml": "ചിത്രത്തിലെ നീല അമ്പ് (Step 1) നോക്കുക. കൈ മാറ്റരുത്.",
        }
      },
      {
        "title": {
          "en": "Step 2: ADD SECONDARY CLOTH LAYER IF SOAKED",
          "kn": "ಹಂತ 2: ರಕ್ತ ಸೋರಿದರೆ ಮತ್ತೊಂದು ಬಟ್ಟೆಯನ್ನು ಮೇಲೆಯೇ ಇಡಿ",
          "hi": "चरण 2: कपड़ा भीगने पर उसके ऊपर दूसरा कपड़ा रखें",
          "ta": "படி 2: ரத்தம் கசிந்தால் மேலே மற்றொரு துணியை வைக்கவும்",
          "te": "దశ 2: బట్ట తడిస్తే దానిపైనే మరొకటి ఉంచండి",
          "ml": "ഘട്ടം 2: തുണി നനഞ്ഞാൽ അതിന് മുകളിൽ അടുത്ത തുണി വെക്കുക",
        },
        "action": {
          "en": "NEVER remove the first cloth layer. Place more cloth pads directly over it and press firmly.",
          "kn": "ಮೊದಲ ಬಟ್ಟೆಯನ್ನು ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ತೆಗೆಯಬೇಡಿ. ಅದರ ಮೇಲೆಯೇ ಮತ್ತಷ್ಟು ಬಟ್ಟೆಗಳನ್ನು ಇಟ್ಟು ಒತ್ತಿರಿ.",
          "hi": "पहला कपड़ा कभी न हटाएं। उसके ऊपर और कपड़ा रखकर लगातार दबाएं।",
          "ta": "முதல் துணியை அகற்றவே கூடாது. அதன் மேலேயே கூடுதல் துணியை வைத்து அழுத்தவும்.",
          "te": "మొదటి గుడ్డను ఎట్టి పరిస్థితుల్లోనూ తీయకండి. దానిపైనే మరిన్ని గుడ్డలు పెట్టి నొక్కండి.",
          "ml": "ആദ്യത്തെ തുണി മാറ്റരുത്. അതിന് മുകളിൽ കൂടുതൽ തുണി വെച്ച് അമർത്തുക.",
        },
        "desc": {
          "en": "Look at Step 2 stack on image. Removing the base cloth tears open fresh blood clots.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಸ್ಟೆಪ್ 2 ಪದರಗಳನ್ನು ಗಮನಿಸಿ. ಮೂಲ ಬಟ್ಟೆ ತೆಗೆದರೆ ರಕ್ತ ಹೆಪ್ಪುಗಟ್ಟುವಿಕೆ ಹಾಳಾಗುತ್ತದೆ.",
          "hi": "चित्र में Step 2 देखें। कपड़ा हटाने से थक्का टूट जाता है।",
          "ta": "படத்தில் Step 2-ஐ பார்க்கவும். துணியை எடுத்தால் ரத்தம் மீண்டும் வேகமாக வழியும்.",
          "te": "చిత్రంలో Step 2 గమనించండి. మొదటి గుడ్డ తీస్తే రక్తం మళ్లీ కారుతుంది.",
          "ml": "ചിത്രത്തിലെ Step 2 ശ്രദ്ധിക്കുക. ആദ്യത്തെ തുണി മാറ്റിയാൽ രക്തം കൂടുതൽ വരും.",
        }
      },
      {
        "title": {
          "en": "Step 3: ELEVATE INJURED LIMB ABOVE HEART LEVEL",
          "kn": "ಹಂತ 3: ಗಾಯಗೊಂಡ ಅಂಗವನ್ನು ಹೃದಯದ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ",
          "hi": "चरण 3: घायल अंग को दिल के स्तर से ऊपर उठाएं",
          "ta": "படி 3: காயம்பட்ட பகுதியை இதய நிலைக்கு மேல் உயர்த்தவும்",
          "te": "దశ 3: గాయపడిన భాగాన్ని గుండె కంటే ఎత్తులో ఉంచండి",
          "ml": "ഘട്ടം 3: മുറിവേറ്റ ഭാഗം ഹൃദയത്തിന് മുകളിലേക്ക് ഉയർത്തുക",
        },
        "action": {
          "en": "If no broken bones exist, raise the bleeding arm above heart height to drop local pressure.",
          "kn": "ಮೂಳೆ ಮುರಿದಿಲ್ಲದಿದ್ದರೆ, ರಕ್ತದ ಒತ್ತಡ ಕಡಿಮೆ ಮಾಡಲು ಕೈಯನ್ನು ಎದೆಯ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ.",
          "hi": "यदि हड्डी न टूटी हो, तो अंग को दिल के स्तर से ऊपर उठाएं ताकि खून का बहाव कम हो।",
          "ta": "எலும்பு முறிவு இல்லையெனில், கையை இதய நிலைக்கு மேல் உயர்த்தவும்.",
          "te": "ఎముక విరగకపోతే గాయపడిన చేతిని గుండె కంటే పైకి ఎత్తండి.",
          "ml": "എല്ല് പൊട്ടിയിട്ടില്ലെങ്കിൽ കൈ നെഞ്ചിന് മുകളിലേക്ക് ഉയർത്തി വെയ്ക്കുക.",
        },
        "desc": {
          "en": "Look at Step 3 upward arrow on image. Keep holding until paramedics arrive.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಮೇಲ್ಮುಖ ಬಾಣದ ಗುರುತು (Step 3) ನೋಡಿ. ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೆ ಹೀಗೆಯೇ ಇಡಿ.",
          "hi": "चित्र में ऊपर का तीर (Step 3) देखें। एम्बुलेंस आने तक ऐसे ही रखें।",
          "ta": "படத்தில் மேல்நோக்கிய அம்புக்குறியைப் பார்க்கவும். உதவி வரும் வரை தொடரவும்.",
          "te": "చిత్రంలో పైకి ఉన్న బాణం గుర్తు చూడండి. అంబులెన్స్ వచ్చేవరకు అలాగే ఉంచండి.",
          "ml": "ചിത്രത്തിലെ മുകളിലേക്കുള്ള അമ്പ് കാണുക. സഹായം എത്തുന്നതുവരെ തുടരുക.",
        }
      }
    ],
    "CHOKING": [
      {
        "title": {
          "en": "Step 1: DELIVER 5 FIRM BACK BLOWS BETWEEN SCAPULAE",
          "kn": "ಹಂತ 1: ಭುಜದ ಮೂಳೆಗಳ (Scapulae) ಮಧ್ಯೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ",
          "hi": "चरण 1: दोनों कंधों के बीच 5 बार जोर से थपथपाएं",
          "ta": "படி 1: தோள்பட்டைகளுக்கு இடையே 5 முறை பலமாக தட்டவும்",
          "te": "దశ 1: భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి",
          "ml": "ഘട്ടം 1: തോൾപ്പലകകൾക്ക് ഇടയിൽ 5 തവണ ശക്തിയായി തട്ടുക",
        },
        "action": {
          "en": "Support chest, lean person forward, and deliver 5 sharp blows between shoulder blades with palm heel.",
          "kn": "ಎದೆಯನ್ನು ಹಿಡಿದು ವ್ಯಕ್ತಿಯನ್ನು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ, ನಿಮ್ಮ ಕೈಯ ಹಿಮ್ಮಡಿಯಿಂದ ಬೆನ್ನಿನ ಮಧ್ಯೆ 5 ಬಾರಿ ತಟ್ಟಿ.",
          "hi": "छाती को सहारा देकर आगे झुकाएं और हथेली के निचले हिस्से से दोनों कंधों के बीच 5 बार थपथपाएं।",
          "ta": "மார்பைத் தாங்கி நபரை முன்னோக்கி சாய்த்து, தோள்பட்டை நடுவில் 5 முறை உள்ளங்கையால் தட்டவும்.",
          "te": "ఛాతీని పట్టుకుని ముందుకు వంచి, అరచేతి మడమతో భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి.",
          "ml": "നെഞ്ചിൽ താങ്ങി മുന്നോട്ട് ചരിച്ച് കൈപ്പത്തി കൊണ്ട് മുതുകിൽ 5 തവണ തട്ടുക.",
        },
        "desc": {
          "en": "Look at Step 1 inset on image. Do not perform if person is coughing forcefully.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಹಂತ 1 ನೋಡಿ. ವ್ಯಕ್ತಿ ತಾನಾಗಿಯೇ ಜೋರಾಗಿ ಕೆಮ್ಮುತ್ತಿದ್ದರೆ ಇದನ್ನು ಮಾಡಬೇಡಿ.",
          "hi": "चित्र में Step 1 देखें। यदि व्यक्ति जोर से खांस रहा हो तो ऐसा न करें।",
          "ta": "படத்தில் Step 1-ஐ பார்க்கவும். நபர் சுயமாக பலமாக இருமினால் இதை செய்ய வேண்டாம்.",
          "te": "చిత్రంలో Step 1 చూడండి. బాధితుడు గట్టిగా దగ్గుతుంటే ఇలా చేయవద్దు.",
          "ml": "ചിത്രത്തിലെ Step 1 കാണുക. ചുമയ്ക്കുന്നുണ്ടെങ്കിൽ ഇത് ചെയ്യരുത്.",
        }
      },
      {
        "title": {
          "en": "Step 2: FIST PLACEMENT JUST ABOVE NAVEL (HEIMLICH)",
          "kn": "ಹಂತ 2: ಹೊಕ್ಕುಳಿನ (Navel) ಮೇಲ್ಭಾಗದಲ್ಲಿ ಮುಷ್ಟಿ ಇಡಿ",
          "hi": "चरण 2: नाभि के ठीक ऊपर मुट्ठी रखें (हाइमलिक)",
          "ta": "படி 2: தொப்புளுக்கு மேலே முஷ்டியை வைக்கவும்",
          "te": "దశ 2: బొడ్డు పైభాగంలో పిడికిలిని ఉంచండి",
          "ml": "ഘട്ടം 2: പൊക്കിളിന് തൊട്ട് മുകളിൽ മുഷ്ടി വെക്കുക",
        },
        "action": {
          "en": "Stand behind person. Place thumb side of your fist against abdomen just above navel.",
          "kn": "ವ್ಯಕ್ತಿಯ ಹಿಂದೆ ನಿಂತುಕೊಳ್ಳಿ. ಹೊಕ್ಕುಳಿನ ಸರಿಯಾಗಿ ಮೇಲ್ಭಾಗದಲ್ಲಿ ನಿಮ್ಮ ಮುಷ್ಟಿಯ ಹೆಬ್ಬೆರಳಿನ ಬದಿಯನ್ನು ಇರಿಸಿ.",
          "hi": "व्यक्ति के पीछे खड़े हों। नाभि के ठीक ऊपर अंगूठे की तरफ से मुट्ठी रखें।",
          "ta": "நபரின் பின்னால் நின்று, தொப்புளுக்கு சற்று மேலே முஷ்டியை வைக்கவும்.",
          "te": "బాధితుడి వెనుక నిలబడి, బొడ్డుకు కొద్దిగా పైభాగంలో పిడికిలిని ఉంచండి.",
          "ml": "വ്യക്തിയുടെ പിന്നിൽ നിന്ന് പൊക്കിളിന് തൊട്ട് മുകളിലായി മുഷ്ടി വെക്കുക.",
        },
        "desc": {
          "en": "Look at Step 2 arrow in image. Stay below ribcage to protect bone structure.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ Step 2 ಗಮನಿಸಿ. ಪಕ್ಕೆಲಬುಗಳ ಕೆಳಭಾಗದಲ್ಲೇ ಮುಷ್ಟಿ ಇರಿಸಿ.",
          "hi": "चित्र में Step 2 तीर देखें। पसलियों से नीचे रखें।",
          "ta": "படத்தில் Step 2 அம்புக்குறியைப் பார்க்கவும். விலா எலும்புகளுக்கு கீழே வைக்கவும்.",
          "te": "చిత్రంలో Step 2 బాణం గుర్తు చూడండి. పక్కటెముకల కింద ఉంచండి.",
          "ml": "ചിത്രത്തിലെ Step 2 അമ്പ് കാണുക. വാരിയെല്ലിന് താഴെയായി വെയ്ക്കുക.",
        }
      },
      {
        "title": {
          "en": "Step 3: SHARP INWARD & UPWARD ABDOMINAL THRUSTS",
          "kn": "ಹಂತ 3: ಒಳಮುಖ & ಮೇಲ್ಮುಖವಾಗಿ ತೀವ್ರವಾಗಿ ಜಗ್ಗಿರಿ",
          "hi": "चरण 3: तेजी से अंदर और ऊपर की ओर झटका दें",
          "ta": "படி 3: உள்நோக்கியும் மேல்நோக்கியும் பலமாக அழுத்தவும்",
          "te": "దశ 3: లోపలికి మరియు పైకి వేగంగా లాగండి",
          "ml": "ഘട്ടം 3: ഉള്ളിലേക്കും മുകളിലേക്കും ശക്തിയായി തള്ളുക",
        },
        "action": {
          "en": "Grasp fist with your other hand. Thrust sharply inward and upward 5 times into the abdomen.",
          "kn": "ಇನ್ನೊಂದು ಕೈಯಿಂದ ಮುಷ್ಟಿಯನ್ನು ಹಿಡಿದು ಒಳಗೆ ಮತ್ತು ಮೇಲ್ಮುಖವಾಗಿ 5 ಬಾರಿ ತೀವ್ರವಾಗಿ ಜಗ್ಗಿರಿ.",
          "hi": "दूसरे हाथ से मुट्ठी पकड़कर तेजी से अंदर और ऊपर की ओर 5 बार झटका दें।",
          "ta": "மற்றொரு கையால் முஷ்டியைப் பிடித்து உள்நோக்கியும் மேல்நோக்கியும் 5 முறை இழுக்கவும்.",
          "te": "మరో చేత్తో పిడికిలిని పట్టుకుని లోపలికి మరియు పైకి 5 సార్లు వేగంగా లాగండి.",
          "ml": "മറ്റേ കൈകൊണ്ട് മുഷ്ടി പിടിച്ച് ഉള്ളിലേക്കും മുകളിലേക്കും 5 തവണ ശക്തിയായി വലിക്കുക.",
        },
        "desc": {
          "en": "Look at Step 3 upward arrows in image. Alternate 5 back blows and 5 thrusts until airway clears.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ Step 3 ಬಾಣಗಳನ್ನು ನೋಡಿ. ವಸ್ತು ಹೊರಬರುವವರೆಗೆ ಇದನ್ನೇ ಮುಂದುವರಿಸಿ.",
          "hi": "चित्र में ऊपर के तीरों को देखें। रुकावट दूर होने तक 5 पीठ पर और 5 पेट पर दोहराएं।",
          "ta": "படத்தில் Step 3-ஐ பார்க்கவும். அடைப்பு நீங்கும் வரை மாறி மாறி செய்யவும்.",
          "te": "చిత్రంలో బాణం గుర్తులు చూడండి. అడ్డంకి తొలగే వరకు ఇలాగే చేయండి.",
          "ml": "ചിത്രത്തിലെ അമ്പുകൾ കാണുക. തടസ്സം മാറുന്നത് വരെ തുടരുക.",
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
          "en": "Check precautions on image: Suspect spinal injury on any crash or fall. Leave helmet on.",
          "kn": "ಚಿತ್ರದಲ್ಲಿರುವ ಮುನ್ನೆಚ್ಚರಿಕೆ ನೋಡಿ: ಅಪಘಾತದಲ್ಲಿ ಕುತ್ತಿಗೆಗೆ ಪೆಟ್ಟಾಗಿರುತ್ತದೆ. ಹೆಲ್ಮೆಟ್ ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ತೆಗೆಯಬೇಡಿ.",
          "hi": "चित्र में सावधानियां देखें: दुर्घटना में रीढ़ की हड्डी में चोट हो सकती है। हेलमेट बिल्कुल न उतारें।",
          "ta": "படத்தில் உள்ள எச்சரிக்கையை பார்க்கவும்: விபத்தில் கழுத்து பாதிக்கப்படலாம். ஹெல்மெட்டை கழற்ற வேண்டாம்.",
          "te": "చిత్రంలో జాగ్రత్తలను చూడండి: ప్రమాదంలో వెన్నుపాముకు గాయమయ్యే ప్రమాదం ఉంది. హెల్మెట్ తీయవద్దు.",
          "ml": "ചിത്രത്തിലെ മുന്നറിയിപ്പ് കാണുക: വീഴ്ചയിലോ അപകടത്തിലോ കഴുത്തിന് ക്ഷതമേൽക്കാം. ഹെൽമെറ്റ് മാറ്റരുത്.",
        },
        "desc": {
          "en": "Look at Step 1 NO sign in image. Twisting the cervical spine can cause instant paralysis.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ Step 1 'NO' ಗುರುತು ನೋಡಿ. ಕುತ್ತಿಗೆ ತಿರುಗಿಸಿದರೆ ಶಾಶ್ವತ ಪಾರ್ಶ್ವವಾಯು ಉಂಟಾಗಬಹುದು.",
          "hi": "चित्र में Step 1 'NO' का निशान देखें। गर्दन हिलने से लकवा हो सकता है।",
          "ta": "படத்தில் Step 1 'NO' குறியை பார்க்கவும். கழுத்து அசைந்தால் நிரந்தர பக்கவாதம் ஏற்படலாம்.",
          "te": "చిత్రంలో Step 1 'NO' గుర్తును చూడండి. మెడ కదిలిస్తే పక్షవాతం రావచ్చు.",
          "ml": "ചിത്രത്തിലെ Step 1 'NO' ചിഹ്നം കാണുക. കഴുത്ത് അനങ്ങിയാൽ തളർവാതം വരാം.",
        }
      },
      {
        "title": {
          "en": "Step 2: MANUAL HEAD IN-LINE STABILIZATION",
          "kn": "ಹಂತ 2: ಎರಡೂ ಕೈಗಳಿಂದ ತಲೆಯನ್ನು ಅಲುಗಾಡದಂತೆ ಹಿಡಿಯಿರಿ",
          "hi": "चरण 2: दोनों हाथों से सिर को स्थिर थामे रखें",
          "ta": "படி 2: தலையை இரு கைகளாலும் அசையாமல் பிடித்துக் கொள்ளவும்",
          "te": "దశ 2: రెండు చేతులతో తలను కదలకుండా పట్టుకోండి",
          "ml": "ഘട്ടം 2: രണ്ട് കൈകൾ കൊണ്ടും തല അനങ്ങാതെ പിടിക്കുക",
        },
        "action": {
          "en": "Kneel at the top of victim's head. Place hands firmly on both sides of head/helmet without pushing or pulling.",
          "kn": "ತಲೆಯ ಬಳಿ ಕುಳಿತು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ಎರಡೂ ಬದಿಗಳಿಂದ ತಲೆಯನ್ನು ಭದ್ರವಾಗಿ ಹಿಡಿದುಕೊಳ್ಳಿ.",
          "hi": "सिर के पीछे बैठें। सिर या हेलमेट के दोनों तरफ हाथ रखकर बिना हिलाए स्थिर रखें।",
          "ta": "தலையின் அருகே அமர்ந்து, தலை அல்லது ஹெல்மெட்டின் இருபுறமும் கைகளை வைத்து பிடிக்கவும்.",
          "te": "బాధితుడి తల వెనుక కూర్చుని, రెండు చేతులతో తలను లేదా హెల్మెట్‌ను కదలకుండా పట్టుకోండి.",
          "ml": "തലയ്ക്ക് സമീപം ഇരുന്ന് രണ്ട് കൈകൾ കൊണ്ടും തലയോ ഹെൽമെറ്റോ അനങ്ങാതെ ഉറപ്പിച്ചു പിടിക്കുക.",
        },
        "desc": {
          "en": "Look at Step 2 dotted spine line in image. Keep head aligned with body until 112 arrives.",
          "kn": "ಚಿತ್ರದಲ್ಲಿ ಚುಕ್ಕೆಗಳ ನೇರ ಗೆರೆ (Step 2) ಗಮನಿಸಿ. ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೆ ತಲೆಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ.",
          "hi": "चित्र में Step 2 की सीधी रेखा देखें। एम्बुलेंस आने तक सिर को इसी तरह थामे रखें।",
          "ta": "படத்தில் Step 2-ன் நேர்கோட்டை பார்க்கவும். ஆம்புலன்ஸ் வரும் வரை தலையை அசையாமல் வைக்கவும்.",
          "te": "చిత్రంలో Step 2 నేరుగా ఉన్న గీతను చూడండి. అంబులెన్స్ వచ్చేవరకు తలను స్థిరంగా ఉంచండి.",
          "ml": "ചിത്രത്തിലെ Step 2 നേർരേഖ കാണുക. ആംബുലൻസ് വരുന്നത് വരെ തല അനക്കാതെ പിടിക്കുക.",
        }
      }
    ],
    "BLEEDING_AND_HELMET": [
      {
        "title": {
          "en": "Step 1: STRICT PROTOCOL - LEAVE HELMET ON & FREEZE NECK",
          "kn": "ಹಂತ 1: ಕಟ್ಟುನಿಟ್ಟಿನ ನಿಯಮ - ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ & ಕುತ್ತಿಗೆ ಅಲುಗಾಡಿಸಬೇಡಿ",
          "hi": "चरण 1: सख्त नियम - हेलमेट बिल्कुल न उतारें और गर्दन को स्थिर रखें",
          "ta": "படி 1: கடுமையான விதி - ஹெல்மெட்டை கழற்றாதீர்கள் & கழுத்தை அசைக்காதீர்கள்",
          "te": "దశ 1: కఠిన నిబంధన - హెల్మెట్ తీయవద్దు & మెడను కదల్చవద్దు",
          "ml": "ഘട്ടം 1: കർശന നിർദ്ദേശം - ഹെൽമെറ്റ് മാറ്റരുത് & കഴുത്ത് അനക്കരുത്",
        },
        "action": {
          "en": "Do not attempt to pull the helmet off. It holds the cervical vertebrae in alignment.",
          "kn": "ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಲು ಪ್ರಯತ್ನಿಸಬೇಡಿ. ಅದು ಕುತ್ತಿಗೆಯ ಮೂಳೆಯನ್ನು ಭದ್ರವಾಗಿರಿಸುತ್ತದೆ.",
          "hi": "हेलमेट खींचने की कोशिश बिल्कुल न करें। यह रीढ़ की हड्डी को स्थिर रखता है।",
          "ta": "ஹெல்மெட்டை கழற்ற வேண்டாம். அது கழுத்து எலும்புகளை அசையாமல் வைக்கிறது.",
          "te": "హెల్మెట్ తీయడానికి ప్రయత్నించవద్దు. ఇది వెన్నుపూసను స్థిరంగా ఉంచుతుంది.",
          "ml": "ഹെൽമെറ്റ് ഊരാൻ ശ്രമിക്കരുത്. ഇത് കഴുത്തിലെ എല്ലുകളെ ഉറപ്പിച്ചു നിർത്തുന്നു.",
        },
        "desc": {
          "en": "See Spinal diagram: Keep head supported on both sides. Moving neck causes instant paralysis.",
          "kn": "ಸ್ಪೈನಲ್ ಚಿತ್ರ ನೋಡಿ: ಎರಡೂ ಬದಿಗಳಿಂದ ತಲೆಯನ್ನು ಹಿಡಿದುಕೊಳ್ಳಿ.",
          "hi": "स्पाइनल चित्र देखें: सिर को दोनों तरफ से थामे रखें।",
          "ta": "ஸ்பைனல் படத்தை பார்க்கவும்: தலையின் இருபுறமும் கைகளை வைத்து பிடிக்கவும்.",
          "te": "స్పైనల్ చిత్రం చూడండి: తలను రెండు వైపులా పట్టుకోండి.",
          "ml": "സ്പൈനൽ ചിത്രം കാണുക: തല ഇരുവശത്തും പിടിക്കുക.",
        }
      },
      {
        "title": {
          "en": "Step 2: APPLY FIRM DIRECT PRESSURE TO WOUND",
          "kn": "ಹಂತ 2: ಗಾಯದ ಮೇಲೆ ನೇರವಾಗಿ ಬಲವಾದ ಒತ್ತಡ ಹಾಕಿ",
          "hi": "चरण 2: घाव पर सीधा और गहरा दबाव बनाएं",
          "ta": "படி 2: காயத்தின் மீது நேரடியாக அழுத்தம் கொடுக்கவும்",
          "te": "దశ 2: గాయంపై నేరుగా గట్టిగా అదిమి పట్టుకోండి",
          "ml": "ഘട്ടം 2: മുറിവിൽ നേരിട്ട് ശക്തമായി അമർത്തുക",
        },
        "action": {
          "en": "Press clean cloth pad onto the bleeding site using full palm force without moving the spine.",
          "kn": "ರೋಗಿಯ ದೇಹ ಅಥವಾ ಕುತ್ತಿಗೆಯನ್ನು ಅಲುಗಾಡಿಸದೆ ಗಾಯದ ಜಾಗಕ್ಕೆ ಶುದ್ಧ ಬಟ್ಟೆಯಿಂದ ಒತ್ತಿ ಹಿಡಿಯಿರಿ.",
          "hi": "व्यक्ति के शरीर या गर्दन को हिलाए बिना साफ कपड़े से घाव पर लगातार दबाव बनाए रखें।",
          "ta": "உடலை அசைக்காமல் சுத்தமான துணியை வைத்து அழுத்தத்தை தொடரவும்.",
          "te": "శరీరాన్ని కదల్చకుండా శుభ్రమైన గుడ్డతో గాయంపై నిరంతర ఒత్తిడిని ఉంచండి.",
          "ml": "ശരീരം അനക്കാതെ വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ അമർത്തിപ്പിടിക്കുക.",
        },
        "desc": {
          "en": "See Bleeding diagram: Keep continuous downward pressure. If soaked, add another layer on top.",
          "kn": "ಬ್ಲೀಡಿಂಗ್ ಚಿತ್ರ ನೋಡಿ: ಸತತವಾಗಿ ಕೆಳಮುಖ ಒತ್ತಡ ಹಾಕಿ. ಬಟ್ಟೆ ನೆನೆದರೆ ಮತ್ತೊಂದು ಬಟ್ಟೆ ಇಡಿ.",
          "hi": "ब्लीडिंग चित्र देखें: लगातार दबाव बनाए रखें। कपड़ा भीगने पर दूसरा ऊपर रखें।",
          "ta": "ப்ளீடிங் படத்தை பார்க்கவும்: அழுத்தத்தைத் தொடரவும்.",
          "te": "రక్తస్రావం చిత్రం చూడండి: నిరంతరం నొక్కి ఉంచండి.",
          "ml": "ബ്ലീഡിംഗ് ചിത്രം കാണുക: നിരന്തരം അമർത്തിപ്പിടിക്കുക.",
        }
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _metronomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545), // 110 BPM
    )..repeat(reverse: true);

    if (widget.protocolKey == "CPR") {
      _startMultiModalMetronome();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrent();
    });
  }

  void _startMultiModalMetronome() {
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 545), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (kIsWeb) {
        js.context.callMethod('eval', ["""
          try {
            if (navigator.vibrate) navigator.vibrate(60);
            var AudioContext = window.AudioContext || window.webkitAudioContext;
            if (AudioContext) {
              if (!window.metronomeAudioCtx) {
                window.metronomeAudioCtx = new AudioContext();
              }
              if (window.metronomeAudioCtx.state === 'suspended') {
                window.metronomeAudioCtx.resume();
              }
              var osc = window.metronomeAudioCtx.createOscillator();
              var gain = window.metronomeAudioCtx.createGain();
              osc.frequency.setValueAtTime(880, window.metronomeAudioCtx.currentTime);
              gain.gain.setValueAtTime(0.2, window.metronomeAudioCtx.currentTime);
              gain.gain.exponentialRampToValueAtTime(0.0001, window.metronomeAudioCtx.currentTime + 0.04);
              osc.connect(gain);
              gain.connect(window.metronomeAudioCtx.destination);
              osc.start();
              osc.stop(window.metronomeAudioCtx.currentTime + 0.05);
            }
          } catch(e) {}
        """]);
      }
    });
  }

  void _speakCurrent() {
    final protocol = _localizedProtocols[widget.protocolKey] ??
        _localizedProtocols["CPR"]!;
    final step = protocol[_currentStepIndex];

    String lang = widget.language;
    String titleText = step["title"]?[lang] ?? step["title"]?["en"] ?? "";
    String actionText = step["action"]?[lang] ?? step["action"]?["en"] ?? "";
    String fullSentence = "$titleText. $actionText";

    if (kIsWeb) {
      String encoded = Uri.encodeComponent(fullSentence);
      String url = "http://127.0.0.1:8000/api/tts?text=$encoded&lang=$lang";
      js.context.callMethod('eval', ["""
        if (window.rapidAidAudio) {
          window.rapidAidAudio.pause();
          window.rapidAidAudio.currentTime = 0;
        }
        window.rapidAidAudio = new Audio('$url');
        window.rapidAidAudio.play().catch(function(err) {
          console.log('Audio autoplay prevented, tap Repeat button:', err);
        });
      """]);
    }
  }

  void _openFullScreenImage(String assetPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
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
    final protocol = _localizedProtocols[widget.protocolKey] ??
        _localizedProtocols["CPR"]!;
    final step = protocol[_currentStepIndex];
    final bool isCpr = widget.protocolKey == "CPR";

    // Switch image on step 1 of BLEEDING_AND_HELMET to bleeding diagram
    String currentAsset = _protocolImages[widget.protocolKey] ?? "assets/images/cpr_guide.png";
    if (widget.protocolKey == "BLEEDING_AND_HELMET" && _currentStepIndex == 1) {
      currentAsset = "assets/images/bleeding_guide.png";
    }

    String lang = widget.language;
    String title = step["title"]?[lang] ?? step["title"]?["en"] ?? "";
    String action = step["action"]?[lang] ?? step["action"]?["en"] ?? "";
    String desc = step["desc"]?[lang] ?? step["desc"]?["en"] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          "Rescue Protocol: ${widget.protocolKey}",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF991B1B),
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              label: const Text(
                "PLAY / REPEAT VOICE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: _speakCurrent,
            ),
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _currentStepIndex > 0
                    ? () {
                        setState(() => _currentStepIndex--);
                        _speakCurrent();
                      }
                    : null,
                child: const Text("Previous Step", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              "${_currentStepIndex + 1} / ${protocol.length}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _currentStepIndex < protocol.length - 1
                    ? () {
                        setState(() => _currentStepIndex++);
                        _speakCurrent();
                      }
                    : null,
                child: const Text("Next Step", style: TextStyle(fontWeight: FontWeight.bold)),
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
            // CPR METRONOME BANNER (SOUND + VIBRATION + VISUAL PULSE)
            if (isCpr)
              ScaleTransition(
                scale: Tween(begin: 0.98, end: 1.03).animate(_metronomeController),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB91C1C),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "METRONOME: 110 BPM (SOUND + VIBRATION + PULSE)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ZOOMABLE INFOGRAPHIC IMAGE CONTAINER WITH HIGH-CONTRAST BACKDROP
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark slate so white text labels stand out
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: Center(
                      child: Image.asset(
                        currentAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Vector fallback if image file is not yet moved to assets
                          return CustomPaint(
                            painter: DedicatedEmergencyPainter(
                              protocolKey: widget.protocolKey,
                              stepIndex: _currentStepIndex,
                              pulseValue: _metronomeController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                        tooltip: "Open Fullscreen Image",
                        onPressed: () => _openFullScreenImage(currentAsset),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pinch, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Pinch or scroll to zoom diagram",
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // STEP GUIDANCE CARD
            Card(
              elevation: 2,
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
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF991B1B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
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