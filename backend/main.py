import io
import re
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from gtts import gTTS

app = FastAPI(title="RapidAid Clinical Engine", version="3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ScenarioAnalysisRequest(BaseModel):
    user_speech: str
    language: str = "en"

# Calming, panic-reducing de-escalation prefaces by language
PANIC_DEESCALATION = {
    "en": "Take a deep breath. Stay calm, help is on the way. I have analyzed the situation. ",
    "kn": "ಆತಂಕಪಡಬೇಡಿ, ದೀರ್ಘವಾಗಿ ಉಸಿರಾಡಿ. ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುತ್ತಿದೆ. ನಾನು ಪರಿಸ್ಥಿತಿಯನ್ನು ವಿಶ್ಲೇಷಿಸಿದ್ದೇನೆ. ",
    "hi": "घबराइए मत, गहरी सांस लें। मदद रास्ते में है। मैंने स्थिति का विश्लेषण कर लिया है। ",
    "ta": "பதற்றமடையாதீர்கள், நிதானமாக இருங்கள். உதவி வந்து கொண்டிருக்கிறது. நான் நிலைமையை ஆராய்ந்துவிட்டேன். ",
    "te": "ఆందోళన చెందకండి, ప్రశాంతంగా ఉండండి. సహాయం వస్తోంది. నేను పరిస్థితిని విశ్లేషించాను. ",
    "ml": "പരിഭ്രാന്തരാകരുത്, ശാന്തരായിരിക്കുക. സഹായം എത്തിക്കൊണ്ടിരിക്കുന്നു. ഞാൻ സാഹചര്യം പരിശോധിച്ചു. "
}

DIAGNOSIS_RESPONSES = {
    "CHOKING": {
        "en": (
            "Take a deep breath. Stay calm. The person's airway is blocked and they are choking. "
            "Here is what to do immediately: First, stand behind them and lean them forward. "
            "Give 5 sharp blows between their shoulder blades using the heel of your hand. "
            "If they still cannot breathe, make a fist and place it just above their navel, below the ribcage. "
            "Grasp your fist with your other hand and pull sharply inward and upward five times. "
            "Keep alternating five back blows and five abdominal thrusts until the object comes out. "
            "Watch the screen for the exact hand position."
        ),
        "kn": (
            "ಆತಂಕಪಡಬೇಡಿ, ಶಾಂತರಾಗಿರಿ. ವ್ಯಕ್ತಿಯ ಗಂಟಲಿನಲ್ಲಿ ವಸ್ತು ಸಿಲುಕಿ ಉಸಿರುಗಟ್ಟುತ್ತಿದೆ. "
            "ತಕ್ಷಣ ಹೀಗೆ ಮಾಡಿ: ಮೊದಲಿಗೆ ಅವರ ಎದೆಯನ್ನು ಒಂದು ಕೈಯಿಂದ ಹಿಡಿದು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ. "
            "ನಿಮ್ಮ ಕೈಯ ಹಿಮ್ಮಡಿಯಿಂದ ಬೆನ್ನಿನ ಮಧ್ಯಭಾಗಕ್ಕೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ. "
            "ಉಸಿರಾಟ ಸರಿಯಾಗದಿದ್ದರೆ, ಅವರ ಹೊಕ್ಕುಳಿನ ಸರಿಯಾಗಿ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಮುಷ್ಟಿ ಇಡಿ. "
            "ಇನ್ನೊಂದು ಕೈಯಿಂದ ಮುಷ್ಟಿಯನ್ನು ಹಿಡಿದು ಒಳಗೆ ಮತ್ತು ಮೇಲ್ಮುಖವಾಗಿ 5 ಬಾರಿ ತೀವ್ರವಾಗಿ ಜಗ್ಗಿರಿ. "
            "ವಸ್ತು ಹೊರಬರುವವರೆಗೂ ಇದನ್ನೇ ಮುಂದುವರಿಸಿ. ಸ್ಕ್ರೀನ್ ಮೇಲೆ ಕೈ ಜೋಡಣೆ ಗಮನಿಸಿ."
        ),
        "hi": (
            "घबराइए मत, शांत रहें। व्यक्ति के गले में कुछ फंसने से दम घुट रहा है। "
            "तुरंत यह कदम उठाएं: पहले व्यक्ति को आगे झुकाएं। "
            "अपनी हथेली के निचले हिस्से से दोनों कंधों के बीच 5 बार जोर से थपथपाएं। "
            "अगर सांस न आए, तो नाभि के ठीक ऊपर मुट्ठी रखें। "
            "दूसरे हाथ से मुट्ठी पकड़कर तेजी से अंदर और ऊपर की ओर 5 बार झटका दें। "
            "जब तक वस्तु बाहर न निकले, यह प्रक्रिया दोहराते रहें। स्क्रीन पर हाथ की स्थिति देखें।"
        ),
        "ta": (
            "பதற்றமடையாதீர்கள், நிதானமாக இருங்கள். நபரின் தொண்டையில் ஏதோ அடைத்து மூச்சு திணறுகிறது. "
            "உடனே இதைச் செய்யுங்கள்: நபரை முன்னோக்கி சாய்க்கவும். "
            "தோள்பட்டைகளின் நடுவில் உள்ளங்கையின் அடியால் 5 முறை பலமாக தட்டவும். "
            "சுவாசம் வரவில்லை என்றால், தொப்புளுக்கு சற்று மேலே முஷ்டியை வைக்கவும். "
            "மற்றொரு கையால் பிடித்து உள்நோக்கியும் மேல்நோக்கியும் 5 முறை வேகமாக இழுக்கவும். "
            "பொருள் வெளியேறும் வரை இதைத் தொடரவும். திரையில் கை வைக்கும் இடத்தை பார்க்கவும்."
        ),
        "te": (
            "ఆందోళన పడకండి, ప్రశాంతంగా ఉండండి. గొంతులో ఏదో ఇరుక్కుని శ్వాస ఆడటం లేదు. "
            "వెంటనే ఇలా చేయండి: బాధితుడిని ముందుకు వంచండి. "
            "అరచేతి మడమతో భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి. "
            "ఇంకా శ్వాస ఆడకపోతే, బొడ్డు పైభాగంలో పిడికిలిని ఉంచండి. "
            "మరో చేత్తో పట్టుకుని లోపలికి మరియు పైకి 5 సార్లు వేగంగా లాగండి. "
            "తడస్సు తొలగే వరకు ఇలాగే చేయండి. స్క్రీన్‌పై చేతి స్థానాన్ని గమనించండి."
        ),
        "ml": (
            "പരിഭ്രാന്തരാകരുത്, ശാന്തരായിരിക്കുക. തൊണ്ടയിൽ എന്തോ കുടുങ്ങി ശ്വാസം മുട്ടുകയാണ്. "
            "ഉടൻ തന്നെ ഇത് ചെയ്യുക: വ്യക്തിയെ മുന്നോട്ട് ചരിക്കുക. "
            "കൈപ്പത്തി കൊണ്ട് മുതുകിൽ തോളിനിടയിൽ 5 തവണ ശക്തിയായി തട്ടുക. "
            "ശ്വാസം കിട്ടിയില്ലെങ്കിൽ, പൊക്കിളിന് തൊട്ട് മുകളിലായി മുഷ്ടി വെക്കുക. "
            "മറ്റേ കൈകൊണ്ട് പിടിച്ച് ഉള്ളിലേക്കും മുകളിലേക്കും 5 തവണ അമർത്തുക. "
            "തടസ്സം മാറുന്നത് വരെ ഇത് തുടരുക. സ്ക്രീനിൽ കൈ വെക്കേണ്ട സ്ഥാനം നോക്കുക."
        ),
    },
    "CPR": {
        "en": (
            "Take a deep breath and stay calm. The person has collapsed and is unresponsive. "
            "Dial 112 immediately and put it on speaker. Place the person flat on their back on the floor. "
            "Put the heel of one hand in the center of their chest between the nipples, lace fingers on top, "
            "keep elbows completely straight, and push hard and fast at least 2 inches deep. "
            "Follow the 110 beats per minute rhythm on screen without stopping until paramedics arrive."
        ),
        "kn": (
            "ಆತಂಕಪಡಬೇಡಿ, ಶಾಂತರಾಗಿರಿ. ವ್ಯಕ್ತಿಯು ಪ್ರಜ್ಞಾಹೀನರಾಗಿದ್ದಾರೆ ಮತ್ತು ಉಸಿರಾಟವಿಲ್ಲ. "
            "ತಕ್ಷಣ 112 ಗೆ ಕರೆ ಮಾಡಿ ಸ್ಪೀಕರ್‌ನಲ್ಲಿಡಿ. ವ್ಯಕ್ತಿಯನ್ನು ಗಟ್ಟಿ ನೆಲದ ಮೇಲೆ ನೇರವಾಗಿ ಮಲಗಿಸಿ. "
            "ಎದೆಯ ಮಧ್ಯಭಾಗದಲ್ಲಿ ಒಂದು ಕೈಯ ಹಿಮ್ಮಡಿ ಇಟ್ಟು, ಇನ್ನೊಂದು ಕೈಯ ಬೆರಳುಗಳನ್ನು ಸೇರಿಸಿ, "
            "ಮೊಣಕೈ ಮಣಿಸದೆ ನಿಮಿಷಕ್ಕೆ 110 ರ ವೇಗದಲ್ಲಿ 2 ಇಂಚು ಆಳಕ್ಕೆ ಒತ್ತಿರಿ. "
            "ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೂ ನಿಲ್ಲಿಸಬೇಡಿ. ಸ್ಕ್ರೀನ್ ನೋಡಿ ಮುಂದುವರಿಯಿರಿ."
        ),
        "hi": (
            "शांत रहें और घबराएं नहीं। व्यक्ति बेहोश है और सांस नहीं ले रहा है। "
            "तुरंत 112 डायल करें और स्पीकर पर रखें। व्यक्ति को सख्त फर्श पर सीधा लिटाएं। "
            "छाती के बीच में हथेली रखें, उंगलियां फंसाएं, कोहनी सीधी रखें और 2 इंच गहरा जोर से दबाएं। "
            "110 बीट प्रति मिनट की गति से लगातार दबाते रहें जब तक एम्बुलेंस न आ जाए।"
        ),
        "ta": (
            "பதற்றமடையாதீர்கள். நபர் சுயநினைவின்றி உள்ளார். "
            "உடனே 112 ஐ அழைத்து ஸ்பீக்கரில் வைக்கவும். நபரை தரையில் நேராக படுக்க வைக்கவும். "
            "மார்பின் நடுவில் கையை வைத்து, விரல்களைப் பூட்டி, முழங்கையை நேராக வைத்து 2 அங்குல ஆழத்திற்கு வேகமாக அழுத்தவும். "
            "ஆம்புலன்ஸ் வரும் வரை நிறுத்த வேண்டாம்."
        ),
        "te": (
            "ప్రశాంతంగా ఉండండి. వ్యక్తి అపస్మారక స్థితిలో ఉన్నారు. "
            "వెంటనే 112 కు కాల్ చేసి స్పీకర్‌లో పెట్టండి. నేలపై పడుకోబెట్టండి. "
            "ఛాతీ మధ్యలో చేతి మడమ ఉంచి, వేళ్లను లాక్ చేసి, మోచేతులు వంచకుండా 2 అంగుళాల లోతుకు వేగంగా నొక్కండి. "
            "అంబులెన్స్ వచ్చేవరకు ఆపకండి."
        ),
        "ml": (
            "പരിഭ്രാന്തരാകരുത്. വ്യക്തിക്ക് ബോധമില്ല. "
            "ഉടൻ 112 ലേക്ക് വിളിച്ച് സ്പീക്കറിലിടുക. തറയിൽ നേരെ കിടത്തുക. "
            "നെഞ്ചിന്റെ മധ്യത്തിൽ കൈപ്പത്തി വെച്ച് വിരലുകൾ കോർത്ത് 2 ഇഞ്ച് താഴ്ചയിൽ വേഗത്തിൽ അമർത്തുക. "
            "ആംബുലൻസ് എത്തുന്നത് വരെ നിർത്തരുത്."
        ),
    },
    "BLEEDING": {
        "en": (
            "Stay calm. There is severe bleeding. "
            "Take a clean cloth or towel and press down directly onto the wound using your full palm force. "
            "Do not lift your hand to check. If blood soaks through, add another cloth on top and keep pressing. "
            "If no bones are broken, raise the injured limb above heart level. Keep holding until help arrives."
        ),
        "kn": (
            "ಶಾಂತರಾಗಿರಿ. ತೀವ್ರ ರಕ್ತಸ್ರಾವವಾಗುತ್ತಿದೆ. "
            "ಒಂದು ಶುದ್ಧ ಬಟ್ಟೆಯನ್ನು ಗಾಯದ ಮೇಲಿಟ್ಟು ನಿಮ್ಮ ಪೂರ್ಣ ಬಲದಿಂದ ಗಟ್ಟಿಯಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. "
            "ರಕ್ತ ನಿಂತಿದೆಯೇ ಎಂದು ನೋಡಲು ಕೈ ತೆಗೆಯಬೇಡಿ. ಬಟ್ಟೆ ನೆನೆದರೆ ಅದರ ಮೇಲೆಯೇ ಮತ್ತೊಂದು ಬಟ್ಟೆ ಇಡಿ. "
            "ಮೂಳೆ ಮುರಿದಿಲ್ಲದಿದ್ದರೆ ಆ ಅಂಗವನ್ನು ಎದೆಯ ಮಟ್ಟಕ್ಕಿಂತ ಮೇಲಕ್ಕೆತ್ತಿ."
        ),
        "hi": (
            "शांत रहें। गंभीर रक्तस्राव हो रहा है। "
            "घाव पर साफ कपड़ा रखें और पूरी हथेली की ताकत से दबाए रखें। "
            "हाथ बिल्कुल न उठाएं। कपड़ा भीग जाए तो उसके ऊपर दूसरा कपड़ा रखें। "
            "हड्डी न टूटी हो तो अंग को दिल के स्तर से ऊपर उठाएं।"
        ),
        "ta": (
            "நிதானமாக இருங்கள். கடுமையான ரத்தப்போக்கு உள்ளது. "
            "சுத்தமான துணியால் காயத்தின் மீது முழு பலத்துடன் அழுத்திப் பிடிக்கவும். "
            "கையை எடுக்க வேண்டாம். எலும்பு முறிவு இல்லை என்றால் காயம்பட்ட பகுதியை இதயத்திற்கு மேல் உயர்த்தவும்."
        ),
        "te": (
            "ప్రశాంతంగా ఉండండి. తీవ్ర రక్తస్రావం జరుగుతోంది. "
            "గాయంపై శుభ్రమైన గుడ్డను ఉంచి పూర్తి బలంతో నొక్కి పట్టుకోండి. "
            "చేతిని తీయవద్దు. ఎముక విరగకపోతే ఆ భాగాన్ని గుండె కంటే పైకి ఎత్తండి."
        ),
        "ml": (
            "ശാന്തരായിരിക്കുക. അമിത രക്തസ്രാവമുണ്ട്. "
            "വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ അമർത്തിപ്പിടിക്കുക. "
            "കൈ മാറ്റരുത്. എല്ലിന് പൊട്ടലില്ലെങ്കിൽ മുറിവേറ്റ ഭാഗം ഉയർത്തി വെയ്ക്കുക."
        ),
    },
    "SPINAL_CAUTION": {
        "en": (
            "Stay completely calm. This is an impact accident. "
            "Strict medical rule: Do not move the person and do not take off their helmet. "
            "Kneel at the top of their head and hold both sides firmly to prevent any neck movement. "
            "Reassure them and keep them still until the 112 ambulance arrives."
        ),
        "kn": (
            "ಶಾಂತರಾಗಿರಿ. ಇದು ಅಪಘಾತದ ಸನ್ನಿವೇಶ. "
            "ಕಟ್ಟುನಿಟ್ಟಿನ ನಿಯಮ: ವ್ಯಕ್ತಿಯನ್ನು ಅಲುಗಾಡಿಸಬೇಡಿ ಮತ್ತು ಹೆಲ್ಮೆಟ್ ತೆಗೆಯಬೇಡಿ. "
            "ತಲೆಯ ಬಳಿ ಕುಳಿತು ಕುತ್ತಿಗೆ ಅಲುಗಾಡದಂತೆ ಎರಡೂ ಬದಿಗಳಿಂದ ತಲೆಯನ್ನು ಭದ್ರವಾಗಿ ಹಿಡಿದುಕೊಳ್ಳಿ. "
            "ಆಂಬ್ಯುಲೆನ್ಸ್ ಬರುವವರೆಗೆ ಅವರನ್ನು ಸಮಾಧಾನಪಡಿಸಿ."
        ),
        "hi": (
            "शांत रहें। यह दुर्घटना का मामला है। "
            "सख्त नियम: व्यक्ति को बिल्कुल न हिलाएं और हेलमेट न उतारें। "
            "सिर के दोनों तरफ हाथ रखकर गर्दन को स्थिर रखें ताकि कोई हलचल न हो। "
            "एम्बुलेंस आने तक व्यक्ति को शांत रखें।"
        ),
        "ta": (
            "அமைதியாக இருங்கள். இது விபத்து. "
            "கடுமையான விதி: நபரை அசைக்கவோ ஹெல்மெட்டை கழற்றவோ கூடாது. "
            "கழுத்து அசையாமல் இருக்க தலையின் இருபுறமும் கைகளை வைத்து பிடிக்கவும். "
            "ஆம்புலன்ஸ் வரும் வரை காத்திருக்கவும்."
        ),
        "te": (
            "ప్రశాంతంగా ఉండండి. ఇది ప్రమాదం. "
            "కఠిన నిబంధన: వ్యక్తిని కదిలించవద్దు మరియు హెల్మెట్ తీయవద్దు. "
            "మెడ కదలకుండా రెండు చేతులతో తలను పట్టుకోండి. "
            "అంబులెన్స్ వచ్చేవరకు స్థిరంగా ఉంచండి."
        ),
        "ml": (
            "ശാന്തരായിരിക്കുക. ഇത് അപകടമാണ്. "
            "കർശന നിർദ്ദേശം: വ്യക്തിയെ അനക്കുകയോ ഹെൽമെറ്റ് മാറ്റുകയോ ചെയ്യരുത്. "
            "കഴുത്ത് അനങ്ങാതിരിക്കാൻ തല ഇരുവശത്തും കൈകൾ വെച്ച് പിടിക്കുക. "
            "ആംബുലൻസ് വരുന്നത് വരെ കാത്തിരിക്കുക."
        ),
    }
}

@app.post("/api/analyze-scenario")
def analyze_scenario(req: ScenarioAnalysisRequest):
    text = req.user_speech.lower()
    lang = req.language if req.language in PANIC_DEESCALATION else "en"

    # 1. First priority: Check for unresponsiveness, collapse, no breathing, or heart emergency
    cpr_pattern = r"(not responding|unresponsive|collapsed|no breath|not breathing|stopped breathing|unconscious|fainted|heart attack|cardiac|pulse|no pulse|ಉಸಿರಾಡುತ್ತಿಲ್ಲ|ಪ್ರಜ್ಞೆ ಇಲ್ಲ|ಬಿದ್ದಿದ್ದಾನೆ|हार्ट|सांस नहीं|बेहोश|சுவாசம் இல்லை|மயக்கம்|స్పృహ లేదు|శ్వాస లేదు|ബോധമില്ല|ശ്വാസമില്ല)"
    
    # 2. Second priority: Airway obstruction / Choking
    choking_pattern = r"(chok|throat|food stuck|can't breathe|unable to breathe|cough|strangle|ಗಂಟಲು|ಸಿಲುಕಿದೆ|दम घुट|गले|திணறல்|గొంతు|തൊണ്ട|ശ്വാസം മുട്ട)"
    
    # 3. Third priority: Severe bleeding
    bleeding_pattern = r"(bleed|blood|cut|wound|hemorrhage|artery|ರಕ್ತ|ಗಾಯ|खून|घाव|ரத்தம்|காயம்|రక్తం|గాయం|ചോര|മുറിവ്)"
    
    # 4. Fourth priority: Vehicle impact / Bike crash (exclude simple fainting / falling down)
    crash_pattern = r"(bike|car|vehicle|motorcycle|scooter|road accident|helmet|head injury|ಗುದ್ದಿದೆ|ಆಕ್ಸಿಡೆಂಟ್|हादसा|विபத்து|ప్రమాదం|അപകടം)"

    if re.search(cpr_pattern, text):
        resolved_protocol = "CPR"
    elif re.search(choking_pattern, text):
        resolved_protocol = "CHOKING"
    elif re.search(bleeding_pattern, text) and not ("no blood" in text or "no bleeding" in text):
        resolved_protocol = "BLEEDING"
    elif re.search(crash_pattern, text):
        resolved_protocol = "SPINAL_CAUTION"
    else:
        # Default safety for any general collapse
        resolved_protocol = "CPR"

    calm_preface = PANIC_DEESCALATION.get(lang, PANIC_DEESCALATION["en"])
    clinical_finding = DIAGNOSIS_RESPONSES[resolved_protocol].get(lang, DIAGNOSIS_RESPONSES[resolved_protocol]["en"])
    full_speech_response = f"{calm_preface} {clinical_finding}"

    return {
        "status": "success",
        "resolved_protocol": resolved_protocol,
        "spoken_reassurance": full_speech_response,
        "language": lang
    }

@app.get("/api/tts")
def voice_stream(text: str = Query(...), lang: str = Query("en")):
    supported_langs = {'en', 'hi', 'kn', 'ta', 'te', 'ml'}
    clean_lang = lang if lang in supported_langs else 'en'
    try:
        tts = gTTS(text=text, lang=clean_lang, slow=False)
        buffer = io.BytesIO()
        tts.write_to_fp(buffer)
        buffer.seek(0)
        return StreamingResponse(buffer, media_type="audio/mp3")
    except Exception:
        fallback = gTTS(text=text, lang='en', slow=False)
        buffer = io.BytesIO()
        fallback.write_to_fp(buffer)
        buffer.seek(0)
        return StreamingResponse(buffer, media_type="audio/mp3")