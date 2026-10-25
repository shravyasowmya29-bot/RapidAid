import io
import re
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List, Dict
from gtts import gTTS

app = FastAPI(title="RapidAid Dispatcher Engine", version="5.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TriageRequest(BaseModel):
    user_speech: str
    language: str = "en"
    country: str = "IN"  # "IN" (112) or "US" (911)
    session_stage: str = "INITIAL"  # INITIAL, CHECK_CONSCIOUSNESS, CHECK_BREATHING, CHECK_BLEEDING, ROAD_SCENE_SAFETY, ROAD_CHECK_SPINE
    emergency_type: Optional[str] = None

def detect_script(text: str) -> str:
    """Accurately detect Indic scripts from raw text."""
    for ch in text:
        code = ord(ch)
        if 0x0C00 <= code <= 0x0C7F:
            return "te"  # Telugu
        if 0x0B80 <= code <= 0x0BFF:
            return "ta"  # Tamil
        if 0x0C80 <= code <= 0x0CFF:
            return "kn"  # Kannada
        if 0x0900 <= code <= 0x097F:
            return "hi"  # Hindi
        if 0x0D00 <= code <= 0x0D7F:
            return "ml"  # Malayalam
    return "en"

# Multilingual Call Handler Assessment Dialogue Trees
DIALOGUES = {
    "WELCOME_PROMPT": {
        "en": "Emergency assistance is available. Please tell me what happened. If someone is in immediate danger, contact your local emergency services now.",
        "kn": "ತುರ್ತು ಸಹಾಯ ಲಭ್ಯವಿದೆ. ಏನಾಗಿದೆ ಎಂದು ತಿಳಿಸಿ. ಯಾರಾದರೂ ತೀವ್ರ ಅಪಾಯದಲ್ಲಿದ್ದರೆ, ತಕ್ಷಣ ತುರ್ತು ಸೇವೆಗೆ ಕರೆ ಮಾಡಿ.",
        "hi": "आपातकालीन सहायता उपलब्ध है। कृपया बताएं क्या हुआ है। यदि कोई तत्काल खतरे में है, तो तुरंत आपातकालीन सेवाओं से संपर्क करें।",
        "ta": "அவசர உதவி தயாராக உள்ளது. என்ன நடந்தது என்று சொல்லுங்கள். உயிருக்கு ஆபத்து என்றால் உடனடியாக அவசர எண்ணை அழைக்கவும்.",
        "te": "అత్యవసర సహాయం అందుబాటులో ఉంది. ఏం జరిగిందో దయచేసి చెప్పండి. ఎవరైనా ప్రాణాపాయంలో ఉంటే వెంటనే అత్యవసర సేవలకు కాల్ చేయండి.",
        "ml": "അടിയന്തിര സഹായം ലഭ്യമാണ്. എന്താണ് സംഭവിച്ചതെന്ന് ദയവായി പറയുക. ആരെങ്കിലും അപകടത്തിലാണെങ്കിൽ ഉടൻ വിളിക്കുക."
    },
    "ASK_CONSCIOUSNESS": {
        "en": "Stay calm, help is on the way. Tap their shoulder firmly: Is the person awake, responding, or conscious?",
        "kn": "ಶಾಂತರಾಗಿರಿ, ಸಹಾಯ ಬರುತ್ತಿದೆ. ಅವರ ಭುಜವನ್ನು ಗಟ್ಟಿಯಾಗಿ ತಟ್ಟಿ: ಆ ವ್ಯಕ್ತಿ ಎಚ್ಚರವಾಗಿದ್ದಾರಾ ಮತ್ತು ಮಾತನಾಡುತ್ತಿದ್ದಾರಾ?",
        "hi": "शांत रहें, मदद रास्ते में है। उनके कंधे को थपथपाएं: क्या व्यक्ति होश में है और प्रतिक्रिया दे रहा है?",
        "ta": "பதற்றமடையாதீர்கள், உதவி வருகிறது. தோள்பட்டையைத் தட்டுங்கள்: நபர் சுயநினைவோடு பதிலளிக்கிறாரா?",
        "te": "ప్రశాంతంగా ఉండండి, సహాయం వస్తోంది. వారి భుజాన్ని తట్టండి: ఆ వ్యక్తి స్పృహలో ఉన్నారా మరియు స్పందిస్తున్నారా?",
        "ml": "ശാന്തരായിരിക്കുക, സഹായം വരുന്നു. തോൾ തട്ടി നോക്കൂ: വ്യക്തിക്ക് ബോധമുണ്ടോ, പ്രതികരിക്കുന്നുണ്ടോ?"
    },
    "ASK_BREATHING": {
        "en": "Look closely at their chest for 5 seconds. Are they breathing normally, or not breathing at all?",
        "kn": "ಅವರ ಎದೆಯನ್ನು 5 ಸೆಕೆಂಡುಗಳ ಕಾಲ ಸೂಕ್ಷ್ಮವಾಗಿ ಗಮನಿಸಿ. ಅವರು ಸಹಜವಾಗಿ ಉಸಿರಾಡುತ್ತಿದ್ದಾರಾ ಅಥವಾ ಉಸಿರಾಟ ನಿಂತಿದೆಯಾ?",
        "hi": "5 सेकंड तक उनकी छाती को ध्यान से देखें। क्या सांस सामान्य चल रही है, या बिल्कुल नहीं चल रही?",
        "ta": "5 வினாடிகள் மார்பை கவனியுங்கள். சுவாசம் சாதாரணமாக உள்ளதா அல்லது முற்றிலும் நின்றுவிட்டதா?",
        "te": "వారి ఛాతీని 5 సెకన్ల పాటు గమనించండి. సాధారణంగా శ్వాస తీసుకుంటున్నారా, లేదా శ్వాస పూర్తిగా ఆగిపోయిందా?",
        "ml": "5 സെക്കൻഡ് നെഞ്ചിലേക്ക് ശ്രദ്ധിക്കുക. ശ്വാസമെടുക്കുന്നുണ്ടോ അതോ ശ്വാസം നിലച്ചോ?"
    },
    "ASK_ROAD_SAFETY": {
        "en": "Do not enter active traffic. Are you and the injured person safe from oncoming vehicles, fuel leaks, or fire?",
        "kn": "ಚಲಿಸುವ ವಾಹನಗಳ ಮಧ್ಯೆ ಹೋಗಬೇಡಿ. ನೀವು ಮತ್ತು ಗಾಯಾಳು ವಾಹನ ಸಂಚಾರ ಅಥವಾ ಬೆಂಕಿಯಿಂದ ಸುರಕ್ಷಿತವಾಗಿದ್ದೀರಾ?",
        "hi": "चलती गाड़ियों के बीच न जाएं। क्या आप और घायल व्यक्ति आने वाले वाहनों, पेट्रोल रिसाव या आग से सुरक्षित हैं?",
        "ta": "போக்குவரத்துக்குள் செல்லாதீர்கள். நீங்களும் காயமடைந்தவரும் வாகனங்கள் மற்றும் தீ விபத்தில் இருந்து பாதுகாப்பாக உள்ளீர்களா?",
        "te": "ట్రాఫిక్‌లోకి వెళ్లవద్దు. మీరు మరియు క్షతగాత్రులు వాహనాలు, ఇంధన లీకేజీ లేదా మంటల నుండి సురక్షితంగా ఉన్నారా?",
        "ml": "വാഹനങ്ങൾക്ക് മുന്നിലേക്ക് പോകരുത്. നിങ്ങളും പരിക്കേറ്റയാളും സുരക്ഷിതമായ സ്ഥലത്താണോ?"
    },
    "ASK_ROAD_NECK_INJURY": {
        "en": "Is the person wearing a helmet, complaining of severe neck or back pain, or unable to move their limbs?",
        "kn": "ವ್ಯಕ್ತಿಯು ಹೆಲ್ಮೆಟ್ ಧರಿಸಿದ್ದಾರಾ, ಕುತ್ತಿಗೆ ಅಥವಾ ಬೆನ್ನು ನೋವು ಎನ್ನುತ್ತಿದ್ದಾರಾ?",
        "hi": "क्या व्यक्ति ने हेलमेट पहना है, या वह गर्दन और पीठ में गंभीर दर्द बता रहा है?",
        "ta": "நபர் ஹெல்மெட் அணிந்துள்ளாரா அல்லது கழுத்து, முதுகு வலியால் துடிக்கிறாரா?",
        "te": "వ్యక్తి హెల్మెట్ ధరించి ఉన్నారా, లేదా మెడ మరియు వెన్నుపాము తీవ్రంగా నొప్పి అని చెబుతున్నారా?",
        "ml": "വ്യക്തി ഹെൽമെറ്റ് ധരിച്ചിട്ടുണ്ടോ, കഴുത്ത് വേദന ഉണ്ടെന്ന് പറയുന്നുണ്ടോ?"
    },
    "ASK_FIRE_TRAPPED": {
        "en": "Fire emergency: Evacuate immediately. Are you or anyone else trapped inside a room or blocked by smoke?",
        "kn": "ಬೆಂಕಿ ಅವಘಡ: ತಕ್ಷಣ ಹೊರಬನ್ನಿ. ನೀವು ಅಥವಾ ಯಾರಾದರೂ ಕೋಣೆಯಲ್ಲಿ ಸಿಲುಕಿಕೊಂಡಿದ್ದೀರಾ ಅಥವಾ ಹೊಗೆ ಆವರಿಸಿದೆಯಾ?",
        "hi": "आग का आपातकाल: तुरंत बाहर निकलें। क्या आप या कोई अन्य व्यक्ति अंदर फंसा हुआ है?",
        "ta": "தீ விபத்து: உடனே வெளியேறுங்கள். யாராவது அறைக்குள் அல்லது புகைக்குள் சிக்கியுள்ளார்களா?",
        "te": "అగ్ని ప్రమాదం: వెంటనే బయటకు వచ్చేయండి. మీరు లేదా ఎవరైనా గదిలో లేదా పొగలో చిక్కుకున్నారా?",
        "ml": "തീപിടുത്തം: ഉടൻ പുറത്തിറങ്ങുക. ആരെങ്കിലും മുറിക്കുള്ളിൽ കുടുങ്ങിയിട്ടുണ്ടോ?"
    },
    "ASK_PERSONAL_SILENT": {
        "en": "Personal danger: Can you speak safely right now, or do you need me to operate in 100% silent mode?",
        "kn": "ವೈಯಕ್ತಿಕ ಭದ್ರತೆ: ನೀವು ಮಾತನಾಡಲು ಸುರಕ್ಷಿತವೇ ಅಥವಾ ನಾನು ಸಂಪೂರ್ಣ ಸೈಲೆಂಟ್ ಮೋಡ್‌ನಲ್ಲಿ ಕಾರ್ಯನಿರ್ವಹಿಸಬೇಕೇ?",
        "hi": "व्यक्तिगत सुरक्षा: क्या आप सुरक्षित रूप से बोल सकते हैं, या आपको पूरी तरह से मूक (साइलेंट) मोड चाहिए?",
        "ta": "தனிநபர் பாதுகாப்பு: நீங்கள் பேச முடியுமா அல்லது சத்தமில்லாத சைலண்ட் மோட் தேவையா?",
        "te": "వ్యక్తిగత రక్షణ: మీరు మాట్లాడటం సురక్షితమేనా, లేదా నేను పూర్తిగా సైలెంట్ మోడ్‌లో ఉండాలా?",
        "ml": "സുരക്ഷാ ഭീഷണി: സംസാരിക്കാൻ കഴിയുമോ അതോ സൈലന്റ് മോഡ് വേണമോ?"
    }
}

DIAGNOSIS_PROTOCOLS = {
    "CPR": {
        "en": "CRITICAL EMERGENCY: The person is unresponsive and not breathing normally. Call 112 immediately. Put the phone on speaker and begin Hands-Only CPR in the center of the chest at 110 beats per minute.",
        "kn": "ಅತ್ಯಂತ ತುರ್ತು: ವ್ಯಕ್ತಿಯು ಪ್ರಜ್ಞಾಹೀನರಾಗಿದ್ದಾರೆ ಮತ್ತು ಉಸಿರಾಡುತ್ತಿಲ್ಲ. ತಕ್ಷಣ 112 ಗೆ ಕರೆ ಮಾಡಿ. ಎದೆಯ ಮಧ್ಯದಲ್ಲಿ ನಿಮಿಷಕ್ಕೆ 110 ರ ಲಯದಲ್ಲಿ ಸಿಪಿಆರ್ (CPR) ಪ್ರಾರಂಭಿಸಿ.",
        "hi": "गंभीर आपातकाल: व्यक्ति बेहोश है और सामान्य सांस नहीं ले रहा है। तुरंत 112 मिलाएं और 110 बीट प्रति मिनट की गति से छाती के बीच में सीपीआर शुरू करें।",
        "ta": "முக்கியமானது: நபர் சுயநினைவின்றி உள்ளார், சுவாசம் இல்லை. உடனே 112 ஐ அழையுங்கள். மார்பின் நடுவில் 110 BPM வேகத்தில் CPR தொடங்குங்கள்.",
        "te": "అత్యవసరం: వ్యక్తి స్పృహలో లేరు మరియు శ్వాస ఆడటం లేదు. వెంటనే 112 కు కాల్ చేయండి. ఛాతీ మధ్యలో నిమిషానికి 110 సార్లు చేతులతో CPR ప్రారంభించండి.",
        "ml": "അടിയന്തിരം: വ്യക്തിക്ക് ബോധമില്ല, ശ്വാസമില്ല. ഉടൻ 112 ലേക്ക് വിളിച്ച് നെഞ്ചിന്റെ മധ്യത്തിൽ 110 BPM വേഗത്തിൽ CPR ചെയ്യുക."
    },
    "BLEEDING": {
        "en": "SEVERE BLEEDING: Take a clean cloth or sterile gauze and press directly onto the wound with firm, continuous palm force. Do NOT lift hands to check. If soaked, add another layer on top.",
        "kn": "ತೀವ್ರ ರಕ್ತಸ್ರಾವ: ಸ್ವಚ್ಛವಾದ ಬಟ್ಟೆಯನ್ನು ಗಾಯದ ಮೇಲಿಟ್ಟು ಅಂಗೈ ಬಲದಿಂದ ಗಟ್ಟಿಯಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. ರಕ್ತ ನಿಂತಿದೆಯೇ ಎಂದು ನೋಡಲು ಕೈ ತೆಗೆಯಬೇಡಿ. ಬಟ್ಟೆ ನೆನೆದರೆ ಮತ್ತೊಂದು ಬಟ್ಟೆಯನ್ನು ಮೇಲಿಡಿ.",
        "hi": "गंभीर रक्तस्राव: साफ कपड़ा घाव पर रखें और पूरी हथेली की ताकत से लगातार दबाए रखें। देखने के लिए हाथ न उठाएं। कपड़ा भीग जाए तो उसके ऊपर दूसरा कपड़ा रखें।",
        "ta": "கடுமையான ரத்தப்போக்கு: சுத்தமான துணியால் காயத்தின் மீது தொடர்ச்சியாக முழு பலத்துடன் அழுத்தவும். கையை எடுக்க வேண்டாம். துணி நனைந்தால் மேலே மற்றொரு துணியை வைக்கவும்.",
        "te": "తీవ్ర రక్తస్రావం: శుభ్రమైన గుడ్డను గాయంపై ఉంచి అరచేతి బలంతో గట్టిగా అదిమి పట్టుకోండి. చూడటానికి చేతిని తీయవద్దు. బట్ట తడిస్తే దానిపైనే మరొకటి ఉంచండి.",
        "ml": "അമിത രക്തസ്രാവം: വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ ശക്തിയായി അമർത്തിപ്പിടിക്കുക. കൈ മാറ്റരുത്. കൂടുതൽ തുണി മുകളിൽ വെച്ച് അമർത്തുക."
    },
    "CHOKING": {
        "en": "AIRWAY BLOCKED: Lean the person forward. Give 5 sharp back blows between the shoulder blades with the heel of your hand. If still choking, give 5 upward abdominal thrusts above the navel.",
        "kn": "ಉಸಿರುಗಟ್ಟುವಿಕೆ: ವ್ಯಕ್ತಿಯನ್ನು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ. ನಿಮ್ಮ ಕೈಯ ಹಿಮ್ಮಡಿಯಿಂದ ಬೆನ್ನಿನ ಮಧ್ಯೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ. ನಂತರ ಹೊಕ್ಕುಳಿನ ಮೇಲ್ಭಾಗದಲ್ಲಿ 5 ಬಾರಿ ಜಗ್ಗಿರಿ.",
        "hi": "गला अवरुद्ध: व्यक्ति को आगे झुकाएं। दोनों कंधों के बीच 5 बार थपथपाएं। यदि राहत न मिले, तो नाभि के ठीक ऊपर 5 बार अंदर और ऊपर की ओर झटका दें।",
        "ta": "தொண்டை அடைப்பு: நபரை முன்னோக்கி சாய்க்கவும். தோள்பட்டை நடுவில் 5 முறை பலமாக தட்டவும். பிறகு தொப்புளுக்கு மேலே 5 முறை மேல்நோக்கி அழுத்தவும்.",
        "te": "గొంతు అడ్డంకి: బాధితుడిని ముందుకు వంచండి. అరచేతి మడమతో భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి. తగ్గకపోతే బొడ్డు పైభాగంలో 5 సార్లు పైకి నొక్కండి.",
        "ml": "തൊണ്ടയിൽ തടസ്സം: മുന്നോട്ട് ചരിച്ച് മുതുകിൽ 5 തവണ തട്ടുക. മാറിയില്ലെങ്കിൽ പൊക്കിളിന് മുകളിൽ 5 തവണ മുകളിലേക്ക് അമർത്തുക."
    },
    "SPINAL_CAUTION": {
        "en": "CRITICAL SPINAL RULE: Strictly DO NOT move the person and DO NOT remove their motorcycle helmet. Kneel at the top of their head and hold both sides firmly to lock their neck.",
        "kn": "ಕಟ್ಟುನಿಟ್ಟಿನ ನಿಯಮ: ವ್ಯಕ್ತಿಯನ್ನು ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ಅಲುಗಾಡಿಸಬೇಡಿ ಮತ್ತು ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ. ತಲೆಯ ಎರಡೂ ಬದಿಗಳಲ್ಲಿ ಕೈಯಿಟ್ಟು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ಭದ್ರವಾಗಿ ಹಿಡಿಯಿರಿ.",
        "hi": "सख्त नियम: व्यक्ति को बिल्कुल न हिलाएं और हेलमेट न उतारें। सिर के दोनों तरफ हाथ रखकर गर्दन को बिल्कुल स्थिर रखें।",
        "ta": "கடுமையான விதி: நபரை அசைக்கவோ ஹெல்மெட்டை கழற்றவோ கூடாது. கழுத்து அசையாமல் இருக்க தலையின் இருபுறமும் கைகளை வைத்து பிடிக்கவும்.",
        "te": "కఠిన నిబంధన: వ్యక్తిని ఎట్టి పరిస్థితుల్లోనూ కదల్చవద్దు మరియు హెల్మెట్ తీయవద్దు. మెడ కదలకుండా రెండు చేతులతో తలను పట్టుకోండి.",
        "ml": "കർശന നിർദ്ദേശം: വ്യക്തിയെ അനക്കുകയോ ഹെൽമെറ്റ് മാറ്റുകയോ ചെയ്യരുത്. കഴുത്ത് അനങ്ങാതിരിക്കാൻ തല ഇരുവശത്തും കൈകൾ വെച്ച് പിടിക്കുക."
    },
    "BLEEDING_AND_HELMET": {
        "en": (
            "CRITICAL DUAL EMERGENCY: "
            "1. LEAVE THE HELMET ON. Strictly DO NOT remove the helmet or twist the neck, as moving it can cause permanent paralysis. "
            "2. CONTROL THE BLEEDING: Take a clean cloth or gauze and apply firm, direct palm pressure on the bleeding wound. "
            "Dial 112 immediately and keep their head completely still."
        ),
        "kn": (
            "ಅತ್ಯಂತ ತುರ್ತು ಸನ್ನಿವೇಶ: "
            "1. ಹೆಲ್ಮೆಟ್ ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ತೆಗೆಯಬೇಡಿ ಮತ್ತು ಕುತ್ತಿಗೆಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ. "
            "2. ರಕ್ತಸ್ರಾವ ತಡೆಯಿರಿ: ಶುದ್ಧ ಬಟ್ಟೆಯನ್ನು ಗಾಯದ ಮೇಲಿಟ್ಟು ಅಂಗೈ ಬಲದಿಂದ ಗಟ್ಟಿಯಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. "
            "ತಕ್ಷಣ 112 ಗೆ ಕರೆ ಮಾಡಿ ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೂ ತಲೆಯನ್ನು ಸ್ಥಿರವಾಗಿಡಿ."
        ),
        "hi": (
            "गंभीर दोहरा आपातकाल: "
            "1. हेलमेट बिल्कुल न उतारें और गर्दन को न हिलाएं, इससे रीढ़ की हड्डी टूट सकती है। "
            "2. खून का बहाव रोकें: घाव पर साफ कपड़ा रखकर पूरी हथेली की ताकत से लगातार दबाएं। "
            "तुरंत 112 मिलाएं और व्यक्ति के सिर को दोनों हाथों से स्थिर रखें।"
        ),
        "ta": (
            "அதிமுக்கிய அவசரநிலை: "
            "1. ஹெல்மெட்டை கழற்ற வேண்டாம் மற்றும் கழுத்தை அசைக்க வேண்டாம். "
            "2. ரத்தப்போக்கை நிறுத்துங்கள்: சுத்தமான துணியை காயத்தின் மீது வைத்து அழுத்தவும். "
            "உடனே அவசர எண்ணை அழைத்து தலையை அசையாமல் பிடித்துக் கொள்ளவும்."
        ),
        "te": (
            "అత్యవసర పరిస్థితి: "
            "1. హెల్మెట్ తీయవద్దు మరియు మెడను అస్సలు కదల్చవద్దు, ఇది వెన్నుపాముకు తీవ్ర నష్టం కలిగిస్తుంది. "
            "2. రక్తస్రావాన్ని ఆపండి: శుభ్రమైన గుడ్డను గాయంపై ఉంచి అరచేతితో గట్టిగా నొక్కి పట్టుకోండి. "
            "వెంటనే 112 కు కాల్ చేసి తలను కదలకుండా ఉంచండి."
        ),
        "ml": (
            "അതീവ ഗുരുതരം: "
            "1. ഹെൽമെറ്റ് മാറ്റരുത്, കഴുത്ത് അനക്കരുത്. "
            "2. രക്തസ്രാവം തടയുക: വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ അമർത്തിപ്പിടിക്കുക. "
            "ഉടൻ സഹായം വിളിക്കുക, തല അനങ്ങാതെ പിടിക്കുക."
        )
    },
    "FIRE_ACTION": {
        "en": "FIRE PROTOCOL: Stay low beneath the smoke line. Cover nose and mouth with a damp cloth if available. Move outside to a clear assembly point and never re-enter.",
        "kn": "ಬೆಂಕಿ ನಿಯಮ: ಹೊಗೆಯಿಂದ ತಪ್ಪಿಸಿಕೊಳ್ಳಲು ನೆಲಕ್ಕೆ ಬಗ್ಗಿ ತೆವಳಿ. ಒದ್ದೆ ಬಟ್ಟೆಯಿಂದ ಮೂಗು ಮುಚ್ಚಿಕೊಳ್ಳಿ. ಕಟ್ಟಡದಿಂದ ದೂರವಿರಿ, ಮರಳಿ ಒಳಗೆ ಹೋಗಬೇಡಿ.",
        "hi": "आग का नियम: धुएं से बचने के लिए फर्श के पास झुककर चलें। गीले कपड़े से मुंह ढकें। तुरंत इमारत से बाहर खुली जगह पर जाएं और दोबारा अंदर न जाएं।",
        "ta": "தீ விதிமுறை: புகைக்கு கீழே தரையோடு தரையாக செல்லவும். ஈரத்துணியால் மூக்கை மூடவும். உடனடியாக கட்டிடத்தை விட்டு வெளியேறி பாதுகாப்பான தூரத்தில் நிற்கவும்.",
        "te": "అగ్ని ప్రమాద నియమం: పొగ తగలకుండా కిందకు వంగి నడవండి. తడి గుడ్డతో ముక్కు కప్పుకోండి. భవనం వెలుపల సురక్షిత ప్రదేశానికి వెళ్లి మళ్లీ లోపలికి వెళ్లకండి.",
        "ml": "തീപിടുത്തം: പുക ശ്വസിക്കാതിരിക്കാൻ നിലത്തുകൂടി നീങ്ങുക. നനഞ്ഞ തുണികൊണ്ട് മൂക്ക് മൂടുക. ഉടൻ കെട്ടിടത്തിന് പുറത്തെത്തി സുരക്ഷിതമായി നിൽക്കുക."
    },
    "SILENT_SAFETY": {
        "en": "SILENT SAFETY ACTIVE: Audio is completely muted. Keep phone hidden, screen brightness down, and barricade doors if possible.",
        "kn": "ಸೈಲೆಂಟ್ ಮೋಡ್ ಆಕ್ಟಿವ್ ಆಗಿದೆ. ಯಾವುದೇ ಧ್ವನಿ ಹೊರಬರುವುದಿಲ್ಲ. ಮೊಬೈಲ್ ಮ್ಯೂಟ್ ಮಾಡಿ ಬಾಗಿಲು ಲಾಕ್ ಮಾಡಿಕೊಳ್ಳಿ.",
        "hi": "साइलेंट सुरक्षा मोड सक्रिय है। कोई ध्वनि उत्पन्न नहीं होगी। फोन छुपा कर रखें और कमरे का दरवाजा अंदर से बंद कर लें।",
        "ta": "சைலண்ட் மோட் இயக்கப்பட்டது. எந்த ஒலியும் வராது. போனை மறைத்து வைத்து கதவுகளை பூட்டிக் கொள்ளவும்.",
        "te": "సైలెంట్ మోడ్ ఆక్టివ్‌లో ఉంది. ఎలాంటి శబ్దం రాదు. ఫోన్‌ను సైలెంట్‌లో ఉంచి గది తలుపులు గట్టిగా వేసుకోండి.",
        "ml": "സൈലന്റ് മോഡ് ഓണാണ്. ശബ്ദം പുറത്തുവരില്ല. ഫോൺ നിശബ്ദമാക്കി വാതിലുകൾ അടച്ചിരിക്കുക."
    }
}

@app.post("/api/analyze-scenario")
def analyze_scenario(req: TriageRequest):
    raw_text = req.user_speech.strip()
    text = raw_text.lower()
    
    # Auto-detect script language
    detected_lang = detect_script(raw_text)
    lang = detected_lang if detected_lang != "en" else req.language
    if lang not in ["en", "hi", "kn", "ta", "te", "ml"]:
        lang = "en"

    # Normalize affirmative / negative / uncertain response variants
    is_yes = bool(re.search(r"\b(yes|yeah|yep|ha|haan|avunu|sari|aam)\b|ಹೌದು|हाँ|ஆம்|అవును|അതെ", text))
    is_no = bool(re.search(r"\b(no|nope|nah|nahi|na|illa|ledu|kaadu)\b|ಇಲ್ಲ|नहीं|இல்லை|లేదు|కాదు|ഇല്ല", text))
    is_not_sure = bool(re.search(r"\b(not sure|don't know|dont know|maybe|unknown)\b|ಗೊತ್ತಿಲ್ಲ|पता नहीं|தெரியாது|తెలియదు|അറിയില്ല", text))

    stage = req.session_stage
    emergency_type = req.emergency_type or "medical"

    # Medical & safety keyword indicators
    cpr_indicators = r"(collapsed|fainted|unconscious|not responding|no pulse|heart attack|heart stroke|ಬಿದ್ದಿದ್ದಾನೆ|ಪ್ರಜ್ಞೆ ಇಲ್ಲ|बेहोश|गिर गया|சுயநினைவு இல்லை|స్పృహ లేదు|అపస్మారక|బోధമില്ല)"
    bleeding_indicators = r"(bleed|blood|cut|wound|stab|spurting|రక్తం|గాయం|ರಕ್ತ|ಗಾಯ|खून|घाव|ரத்தம்|காயம்|ചോര|മുറിവ്)"
    choking_indicators = r"(chok|throat|food stuck|can't breathe|swallowed|ಗಂಟಲು|ಸಿಲುಕಿದೆ|गले में अटक|दम घुट|திணறல்|గొంతు|ఇరుక్కుంది|തൊണ്ട)"
    helmet_indicators = r"(helmet|neck|spine|bike|motorcycle|scooter|crash|road|ಆಕ್ಸಿಡೆಂಟ್|ಅಪಘಾತ|ಹೆಲ್ಮೆಟ್|ಕುತ್ತಿಗೆ|हादसा|एक्सीडेंट|हेलमेट|गर्दन|விபத்து|ஹெல்மெட்|கழுத்து|ప్రమాదం|యాక్సిడెంట్|హెల్మెట్|మెడ|അപകടം|ബൈക്ക്|ഹെൽമെറ്റ്)"
    fire_indicators = r"(fire|smoke|burning|flame|flames|trapped in room|ಬೆಂಕಿ|ಹೊಗೆ|आग|धुआं|தீ|புகை|మంటలు|నిప్పు|పొగ|തീ|പുക)"
    police_indicators = r"(thief|robbery|intruder|attack|weapon|gun|stalker|danger|threat|violence|దొంగ|కత్తి|ಕಳ್ಳ|ದಾಳಿ|हथियार|தாக்குதல்|ആക്രമണം)"

    # --- STATE 1: INITIAL INGESTION ---
    if stage == "INITIAL":
        has_bleeding = bool(re.search(bleeding_indicators, text) and not is_no)
        has_helmet = bool(re.search(helmet_indicators, text))

        # Check for Dual-Emergency (Bleeding + Helmet/Crash)
        if has_bleeding and has_helmet:
            return {
                "resolved_protocol": "BLEEDING_AND_HELMET",
                "spoken_reassurance": DIAGNOSIS_PROTOCOLS["BLEEDING_AND_HELMET"][lang],
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["PRESSURE APPLIED", "CALL 112"],
                "language": lang
            }

        # Check for Choking
        if re.search(choking_indicators, text):
            return {
                "resolved_protocol": "CHOKING",
                "spoken_reassurance": DIAGNOSIS_PROTOCOLS["CHOKING"][lang],
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["RECOVERY COMPLETED", "CALL 112"],
                "language": lang
            }

        # Check for Isolated Bleeding
        if has_bleeding:
            return {
                "resolved_protocol": "BLEEDING",
                "spoken_reassurance": DIAGNOSIS_PROTOCOLS["BLEEDING"][lang],
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["PRESSURE APPLIED", "CALL 112"],
                "language": lang
            }

        # Check for Fire / Trapped
        if re.search(fire_indicators, text):
            return {
                "resolved_protocol": "FIRE_ACTION",
                "spoken_reassurance": DIALOGUES["ASK_FIRE_TRAPPED"][lang],
                "next_stage": "FIRE_TRAP_CHECK",
                "emergency_type": "fire",
                "quick_options": ["YES - TRAPPED", "NO - OUTSIDE SAFE", "NOT SURE"],
                "language": lang
            }

        # Check for Police / Personal Safety
        if re.search(police_indicators, text):
            return {
                "resolved_protocol": None,
                "spoken_reassurance": DIALOGUES["ASK_PERSONAL_SILENT"][lang],
                "next_stage": "POLICE_SILENT_CHECK",
                "emergency_type": "personal_safety",
                "quick_options": ["I CAN SPEAK SAFELY", "SILENT MODE (DO NOT SPEAK)"],
                "language": lang
            }

        # Check for Road Accident
        if has_helmet:
            return {
                "resolved_protocol": None,
                "spoken_reassurance": DIALOGUES["ASK_ROAD_SAFETY"][lang],
                "next_stage": "ROAD_SCENE_SAFETY",
                "emergency_type": "road_accident",
                "quick_options": ["YES - SCENE IS SAFE", "NO - ACTIVE TRAFFIC/FIRE", "NOT SURE"],
                "language": lang
            }

        # Default Medical Assessment Entry: Inquire about Consciousness
        return {
            "resolved_protocol": None,
            "spoken_reassurance": DIALOGUES["ASK_CONSCIOUSNESS"][lang],
            "next_stage": "CHECK_CONSCIOUSNESS",
            "emergency_type": "medical",
            "quick_options": ["YES - AWAKE & TALKING", "NO - UNRESPONSIVE", "NOT SURE"],
            "language": lang
        }

    # --- STATE 2: MEDICAL ASSESSMENT SUB-TREE ---
    if stage == "CHECK_CONSCIOUSNESS":
        if is_no or is_not_sure or re.search(cpr_indicators, text):
            # Person is unresponsive -> Immediately check breathing
            return {
                "resolved_protocol": None,
                "spoken_reassurance": DIALOGUES["ASK_BREATHING"][lang],
                "next_stage": "CHECK_BREATHING",
                "emergency_type": "medical",
                "quick_options": ["BREATHING NORMALLY", "NOT BREATHING / GASPING", "NOT SURE"],
                "language": lang
            }
        else:
            # Person is awake -> Check for severe bleeding
            return {
                "resolved_protocol": None,
                "spoken_reassurance": "Understood. Are they experiencing any severe, spurting bleeding or deep lacerations?",
                "next_stage": "CHECK_BLEEDING",
                "emergency_type": "medical",
                "quick_options": ["YES - SEVERE BLEEDING", "NO BLEEDING", "NOT SURE"],
                "language": lang
            }

    if stage == "CHECK_BREATHING":
        # Absent, gasping, or uncertain breathing triggers CPR
        if is_no or is_not_sure or "gasp" in text or "not" in text:
            return {
                "resolved_protocol": "CPR",
                "spoken_reassurance": DIAGNOSIS_PROTOCOLS["CPR"][lang],
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["AED AVAILABLE", "AMBULANCE ARRIVED"],
                "language": lang
            }
        else:
            return {
                "resolved_protocol": "SPINAL_CAUTION",
                "spoken_reassurance": "They are breathing normally. Help them rest in a position of comfort. Continually monitor consciousness until paramedics arrive.",
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["MONITORING PATIENT", "CALL 112"],
                "language": lang
            }

    # --- STATE 3: ROAD ACCIDENT SUB-TREE ---
    if stage == "ROAD_SCENE_SAFETY":
        if is_no:
            return {
                "resolved_protocol": "SPINAL_CAUTION",
                "spoken_reassurance": "HAZARD WARNING: Do not enter active traffic lanes. Move to safety behind barriers immediately and dial emergency dispatch.",
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["MOVED TO SAFETY", "CALL 112"],
                "language": lang
            }
        return {
            "resolved_protocol": None,
            "spoken_reassurance": DIALOGUES["ASK_ROAD_NECK_INJURY"][lang],
            "next_stage": "ROAD_CHECK_SPINE",
            "emergency_type": "road_accident",
            "quick_options": ["YES - HELMET / NECK PAIN", "NO NECK PAIN", "NOT SURE"],
            "language": lang
        }

    if stage == "ROAD_CHECK_SPINE":
        if is_yes or is_not_sure:
            return {
                "resolved_protocol": "SPINAL_CAUTION",
                "spoken_reassurance": DIAGNOSIS_PROTOCOLS["SPINAL_CAUTION"][lang],
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["HEAD STABILIZED", "CALL 112"],
                "language": lang
            }
        return {
            "resolved_protocol": None,
            "spoken_reassurance": DIALOGUES["ASK_CONSCIOUSNESS"][lang],
            "next_stage": "CHECK_CONSCIOUSNESS",
            "emergency_type": "medical",
            "quick_options": ["YES - CONSCIOUS", "NO - UNCONSCIOUS", "NOT SURE"],
            "language": lang
        }

    # --- STATE 4: FIRE SUB-TREE ---
    if stage == "FIRE_TRAP_CHECK":
        return {
            "resolved_protocol": "FIRE_ACTION",
            "spoken_reassurance": DIAGNOSIS_PROTOCOLS["FIRE_ACTION"][lang],
            "next_stage": "PROTOCOL_ACTIVE",
            "quick_options": ["OUTSIDE SAFE", "FIRE CREW ARRIVED"],
            "language": lang
        }

    # --- STATE 5: PERSONAL SAFETY / POLICE SUB-TREE ---
    if stage == "POLICE_SILENT_CHECK":
        if "silent" in text or is_no:
            return {
                "resolved_protocol": "SILENT_SAFETY",
                "spoken_reassurance": DIAGNOSIS_PROTOCOLS["SILENT_SAFETY"][lang],
                "next_stage": "PROTOCOL_ACTIVE",
                "quick_options": ["SEND LOCATION SMS", "SAFE NOW"],
                "language": lang
            }
        return {
            "resolved_protocol": None,
            "spoken_reassurance": "Active threat protocol: RUN if you can. HIDE if you cannot. Barricade doors, stay low, and silence your device.",
            "next_stage": "PROTOCOL_ACTIVE",
            "quick_options": ["POLICE ARRIVED", "CALL 112"],
            "language": lang
        }

    # Default fallback
    return {
        "resolved_protocol": "CPR",
        "spoken_reassurance": DIAGNOSIS_PROTOCOLS["CPR"][lang],
        "next_stage": "PROTOCOL_ACTIVE",
        "quick_options": ["CALL 112"],
        "language": lang
    }

@app.get("/api/tts")
def voice_stream(text: str = Query(...), lang: str = Query("en")):
    clean_lang = lang if lang in {'en', 'hi', 'kn', 'ta', 'te', 'ml'} else 'en'
    try:
        tts = gTTS(text=text, lang=clean_lang, slow=False)
        buffer = io.BytesIO()
        tts.write_to_fp(buffer)
        buffer.seek(0)
        return StreamingResponse(
            buffer,
            media_type="audio/mp3",
            headers={"Content-Disposition": "inline; filename=speech.mp3"}
        )
    except Exception:
        fallback = gTTS(text=text, lang='en', slow=False)
        buffer = io.BytesIO()
        fallback.write_to_fp(buffer)
        buffer.seek(0)
        return StreamingResponse(
            buffer,
            media_type="audio/mp3",
            headers={"Content-Disposition": "inline; filename=speech.mp3"}
        )

@app.get("/api/health")
def health_check():
    return {"status": "online", "system": "RapidAid Dispatcher Engine"}