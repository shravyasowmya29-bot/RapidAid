import io
import re
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List
from gtts import gTTS

app = FastAPI(title="RapidAid EMD Dispatch Engine", version="6.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class EMDRequest(BaseModel):
    user_speech: str
    language: str = "en"
    country: str = "IN"  # "IN" (112) or "US" (911)
    session_stage: str = "INITIAL"
    emergency_card: Optional[str] = None

def detect_script(text: str) -> str:
    for ch in text:
        code = ord(ch)
        if 0x0C00 <= code <= 0x0C7F: return "te"
        if 0x0B80 <= code <= 0x0BFF: return "ta"
        if 0x0C80 <= code <= 0x0CFF: return "kn"
        if 0x0900 <= code <= 0x097F: return "hi"
        if 0x0D00 <= code <= 0x0D7F: return "ml"
    return "en"

# Strict Dispatcher Pre-Arrival Phrasing (Zero Filler Words)
DISPATCHER_SCRIPTS = {
    "SPEAKER_REMINDER": {
        "en": "Put your phone on speakerphone right now and place it next to the patient. Tell me: Is the person awake or responding?",
        "kn": "ನಿಮ್ಮ ಫೋನ್ ಅನ್ನು ಈಗಲೇ ಸ್ಪೀಕರ್‌ನಲ್ಲಿ ಇರಿಸಿ ಮತ್ತು ವ್ಯಕ್ತಿಯ ಪಕ್ಕದಲ್ಲಿಡಿ. ತಿಳಿಸಿ: ವ್ಯಕ್ತಿ ಎಚ್ಚರವಾಗಿದ್ದಾರಾ?",
        "hi": "फोन को तुरंत स्पीकर पर डालें और मरीज के पास रखें। बताएं: क्या मरीज होश में है?",
        "ta": "போனை உடனே ஸ்பீக்கரில் போட்டு நபர் அருகில் வைக்கவும். சொல்லுங்கள்: நபர் சுயநினைவோடு உள்ளாரா?",
        "te": "ఫోన్‌ను ఇప్పుడే స్పీకర్‌లో పెట్టి బాధితుడి పక్కన ఉంచండి. చెప్పండి: ఆ వ్యక్తి స్పృహలో ఉన్నారా?",
        "ml": "ഫോൺ ഇപ്പോൾ തന്നെ സ്പീക്കറിലാക്കി രോഗിയുടെ അടുത്ത് വെയ്ക്കുക. പറയൂ: ബോധമുണ്ടോ?"
    },
    "ASK_BREATHING": {
        "en": "Look closely at their chest for 5 seconds. Are they breathing normally, or making gasping or snoring sounds?",
        "kn": "5 ಸೆಕೆಂಡುಗಳ ಕಾಲ ಎದೆಯನ್ನು ಸೂಕ್ಷ್ಮವಾಗಿ ಗಮನಿಸಿ. ಉಸಿರಾಟ ಸಹಜವಾಗಿದೆಯೇ ಅಥವಾ ಗೊರಕೆಯಂತಹ ಶಬ್ದ ಬರುತ್ತಿದೆಯೇ?",
        "hi": "5 सेकंड तक छाती को ध्यान से देखें। क्या सांस सामान्य है, या खर्राटे जैसी आवाज आ रही है?",
        "ta": "5 வினாடிகள் மார்பை கவனியுங்கள். சுவாசம் இயல்பாக உள்ளதா அல்லது குறட்டை போன்ற சத்தம் வருகிறதா?",
        "te": "ఛాతీని 5 సెకన్ల పాటు గమనించండి. శ్వాస సాధారణంగా ఉందా, లేదా గురక శబ్దం వస్తోందా?",
        "ml": "5 സെക്കൻഡ് നെഞ്ചിലേക്ക് ശ്രദ്ധിക്കുക. സാധാരണ ശ്വാസമെടുക്കുന്നുണ്ടോ അതോ കിതയ്ക്കുകയാണോ?"
    },
    "CARD_9_CPR": {
        "en": "Those are agonal gasps, not normal breathing. We must start CPR now. Place heel of hand on center of chest between nipples, lock elbows, and push hard and fast at 110 beats per minute.",
        "kn": "ಇದು ಸಹಜ ಉಸಿರಾಟವಲ್ಲ. ತಕ್ಷಣ ಸಿಪಿಆರ್ (CPR) ಪ್ರಾರಂಭಿಸಬೇಕು. ಎದೆಯ ಮಧ್ಯದಲ್ಲಿ ಕೈಯಿಟ್ಟು ಮೊಣಕೈ ಮಣಿಸದೆ 110 ರ ಲಯದಲ್ಲಿ ಬಲವಾಗಿ ಒತ್ತಿರಿ.",
        "hi": "यह सामान्य सांस नहीं है। हमें तुरंत सीपीआर शुरू करना होगा। छाती के बीच में हथेली रखें, कोहनी सीधी रखें और 110 बीट प्रति मिनट की गति से जोर से दबाएं।",
        "ta": "இது இயல்பான சுவாசம் இல்லை. உடனே CPR தொடங்க வேண்டும். மார்பின் நடுவில் கையை வைத்து முழங்கைகளை மடக்காமல் 110 BPM வேகத்தில் அழுத்தவும்.",
        "te": "ఇది సాధారణ శ్వాస కాదు. వెంటనే CPR ప్రారంభించాలి. ఛాతీ మధ్యలో చేతిని ఉంచి మోచేతులు వంచకుండా నిమిషానికి 110 సార్లు గట్టిగా నొక్కండి.",
        "ml": "ഇത് സാധാരണ ശ്വാസമല്ല. ഉടൻ CPR തുടങ്ങണം. നെഞ്ചിന്റെ മധ്യത്തിൽ കൈവെച്ച് കൈകൾ വളയ്ക്കാതെ 110 BPM വേഗത്തിൽ ശക്തമായി അമർത്തുക."
    },
    "CARD_30_BLEEDING": {
        "en": "Take a clean cloth or shirt. Press down as hard as you can directly on the wound with both hands. Do NOT lift hands to check. If soaked, put another cloth on top.",
        "kn": "ಸ್ವಚ್ಛವಾದ ಬಟ್ಟೆಯನ್ನು ಗಾಯದ ಮೇಲಿಟ್ಟು ಎರಡೂ ಕೈಗಳಿಂದ ಬಲವಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. ರಕ್ತ ನೋಡಲು ಕೈ ತೆಗೆಯಬೇಡಿ. ಬಟ್ಟೆ ನೆನೆದರೆ ಮತ್ತೊಂದು ಬಟ್ಟೆಯನ್ನು ಮೇಲಿಡಿ.",
        "hi": "साफ कपड़ा घाव पर रखें और दोनों हाथों की पूरी ताकत से लगातार दबाए रखें। देखने के लिए हाथ न उठाएं। कपड़ा भीग जाए तो उसके ऊपर दूसरा कपड़ा रखें।",
        "ta": "சுத்தமான துணியை காயத்தின் மீது வைத்து இரு கைகளாலும் முழு பலத்துடன் அழுத்தவும். கையை எடுக்க வேண்டாம். துணி நனைந்தால் மேலே மற்றொரு துணியை வைக்கவும்.",
        "te": "శుభ్రమైన గుడ్డను గాయంపై ఉంచి రెండు చేతులతో గట్టిగా అదిమి పట్టుకోండి. చూడటానికి చేతిని తీయవద్దు. బట్ట తడిస్తే దానిపైనే మరొకటి ఉంచండి.",
        "ml": "വൃത്തിയുള്ള തുണികൊണ്ട് മുറിവിൽ ഇരു കൈകളും ഉപയോഗിച്ച് ശക്തിയായി അമർത്തിപ്പിടിക്കുക. കൈ മാറ്റരുത്. തുണി നനഞ്ഞാൽ മുകളിൽ അടുത്ത തുണി വെക്കുക."
    },
    "BLEEDING_AND_HELMET": {
        "en": "CRITICAL: Strictly DO NOT remove the helmet or twist the neck, as this causes permanent paralysis. Press a clean cloth firmly on the bleeding wound and keep the head completely still.",
        "kn": "ಕಟ್ಟುನಿಟ್ಟಿನ ನಿಯಮ: ಹೆಲ್ಮೆಟ್ ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ತೆಗೆಯಬೇಡಿ ಮತ್ತು ಕುತ್ತಿಗೆ ಅಲುಗಾಡಿಸಬೇಡಿ. ಬಟ್ಟೆಯಿಂದ ಗಾಯವನ್ನು ಒತ್ತಿ ಹಿಡಿದು ತಲೆಯನ್ನು ಅಲುಗಾಡದಂತೆ ಇರಿಸಿ.",
        "hi": "सख्त नियम: हेलमेट बिल्कुल न उतारें और गर्दन को न हिलाएं, इससे लकवा हो सकता है। घाव पर कपड़ा दबाएं और सिर को स्थिर रखें।",
        "ta": "ஹெல்மெட்டை கழற்ற வேண்டாம், கழுத்தை அசைக்க வேண்டாம். காயத்தின் மீது துணியை வைத்து அழுத்தி, தலையை அசையாமல் பிடிக்கவும்.",
        "te": "హెల్మెట్ తీయవద్దు, మెడను కదల్చవద్దు. గాయంపై గుడ్డతో గట్టిగా నొక్కుతూ తలను కదలకుండా పట్టుకోండి.",
        "ml": "ഹെൽമെറ്റ് മാറ്റരുത്, കഴുത്ത് അനക്കരുത്. മുറിവിൽ തുണിവെച്ച് അമർത്തി തല അനങ്ങാതെ പിടിക്കുക."
    },
    "CARD_11_CHOKING": {
        "en": "Airway blocked. Lean them forward. Deliver 5 sharp back blows between the shoulder blades with heel of hand. If still blocked, give 5 upward abdominal thrusts above the navel.",
        "kn": "ಉಸಿರುಗಟ್ಟುವಿಕೆ: ವ್ಯಕ್ತಿಯನ್ನು ಮುಂದಕ್ಕೆ ಬಗ್ಗಿಸಿ ಬೆನ್ನಿನ ಮಧ್ಯೆ 5 ಬಾರಿ ಬಲವಾಗಿ ತಟ್ಟಿ. ನಂತರ ಹೊಕ್ಕುಳಿನ ಮೇಲ್ಭಾಗದಲ್ಲಿ 5 ಬಾರಿ ಮೇಲ್ಮುಖವಾಗಿ ಜಗ್ಗಿರಿ.",
        "hi": "गला अवरुद्ध है। आगे झुकाएं और दोनों कंधों के बीच 5 बार थपथपाएं। राहत न मिले तो नाभि के ठीक ऊपर 5 बार अंदर और ऊपर की ओर झटका दें।",
        "ta": "தொண்டை அடைப்பு: முன்னோக்கி சாய்த்து தோள்பட்டை நடுவில் 5 முறை தட்டவும். பிறகு தொப்புளுக்கு மேலே 5 முறை மேல்நோக்கி அழுத்தவும்.",
        "te": "గొంతు అడ్డంకి: ముందుకు వంచి భుజాల మధ్య 5 సార్లు గట్టిగా కొట్టండి. తగ్గకపోతే బొడ్డు పైభాగంలో 5 సార్లు పైకి నొక్కండి.",
        "ml": "തൊണ്ടയിൽ തടസ്സം: മുന്നോട്ട് ചരിച്ച് മുതുകിൽ 5 തവണ തട്ടുക. മാറിയില്ലെങ്കിൽ പൊക്കിളിന് മുകളിൽ 5 തവണ മുകളിലേക്ക് അമർത്തുക."
    },
    "CARD_12_SEIZURE": {
        "en": "Active Seizure: Do NOT hold them down and do NOT put anything in their mouth. Clear hard furniture away and place a folded jacket gently under their head.",
        "kn": "ಫಿಟ್ಸ್/ಸೆಳವು: ವ್ಯಕ್ತಿಯನ್ನು ಹಿಡಿದಿಡಬೇಡಿ ಮತ್ತು ಬಾಯಿಗೆ ಏನನ್ನೂ ಹಾಕಬೇಡಿ. ಸುತ್ತಲಿನ ವಸ್ತುಗಳನ್ನು ದೂರ ಸರಿಸಿ ತಲೆಯ ಕೆಳಗೆ ಮೃದುವಾದ ಬಟ್ಟೆ ಇಡಿ.",
        "hi": "दौरा: व्यक्ति को जबरन न पकड़ें और मुंह में कुछ न डालें। आसपास से कठोर वस्तुएं हटाएं और सिर के नीचे मुड़ा हुआ कपड़ा रखें।",
        "ta": "வலிப்பு: நபரை அழுத்திப் பிடிக்காதீர்கள், வாயில் எதையும் வைக்காதீர்கள். கூர்மையான பொருட்களை அகற்றி தலைக்கு அடியில் மென்மையான துணியை வைக்கவும்.",
        "te": "ఫిట్స్: బాధితుడిని బలవంతంగా పట్టుకోవద్దు మరియు నోట్లో ఏమీ పెట్టవద్దు. చుట్టుపక్కల వస్తువులను తొలగించి తల కింద మెత్తటి గుడ్డ ఉంచండి.",
        "ml": "ഫിക്സ്: രോഗിയെ ബലമായി പിടിക്കരുത്, വായിൽ ഒന്നും വെക്കരുത്. തറയിലെ തടസ്സങ്ങൾ മാറ്റി തലയ്ക്കടിയിൽ തുണി വെക്കുക."
    },
    "CARD_28_STROKE": {
        "en": "Stroke Assessment: Check FAST. Smile: Is one side of the face drooping? Arms: Can they raise both arms? Speech: Is their speech slurred?",
        "kn": "ಪಾರ್ಶ್ವವಾಯು (Stroke) ಪರೀಕ್ಷೆ: ಮುಖದ ಒಂದು ಬದಿ ವಾಲಿದೆಯೇ? ಎರಡೂ ಕೈಗಳನ್ನು ಎತ್ತಲು ಸಾಧ್ಯವೇ? ಮಾತು ತೊದಲುತ್ತಿದೆಯೇ?",
        "hi": "स्ट्रोक जांच (FAST): क्या चेहरे का एक हिस्सा लटक रहा है? क्या दोनों हाथ उठा पा रहे हैं? क्या बोली लड़खड़ा रही है?",
        "ta": "பக்கவாதம்: முகம் ஒருபுறம் கோணுகிறதா? இரு கைகளையும் உயர்த்த முடிகிறதா? பேச்சு குழறுகிறதா?",
        "te": "పక్షవాతం (FAST): ముఖం ఒకవైపు వాలిపోయిందా? రెండు చేతులు ఎత్తగలుగుతున్నారా? మాట స్పష్టంగా లేదా?",
        "ml": "സ്ട്രോക്ക്: മുഖം ഒരു വശത്തേക്ക് കോടുന്നുണ്ടോ? ഇരു കൈകളും ഉയർത്താമോ? സംസാരത്തിൽ കുഴച്ചിലുണ്ടോ?"
    }
}

@app.post("/api/analyze-scenario")
def analyze_scenario(req: EMDRequest):
    raw_text = req.user_speech.strip()
    text = raw_text.lower()
    
    detected_lang = detect_script(raw_text)
    lang = detected_lang if detected_lang != "en" else req.language
    if lang not in ["en", "hi", "kn", "ta", "te", "ml"]:
        lang = "en"

    is_yes = bool(re.search(r"\b(yes|yeah|yep|ha|haan|avunu|sari|aam)\b|ಹೌದು|हाँ|ஆம்|అవును|ಅതെ", text))
    is_no = bool(re.search(r"\b(no|nope|nah|nahi|na|illa|ledu|kaadu)\b|ಇಲ್ಲ|नहीं|இல்லை|లేదు|కాదు|ഇല്ല", text))
    is_not_sure = bool(re.search(r"\b(not sure|don't know|dont know|maybe|unknown)\b|ಗೊತ್ತಿಲ್ಲ|पता नहीं|தெரியாது|తెలియదు|അറിയില്ല", text))

    stage = req.session_stage

    # Regex indicators for primary complaints
    agonal_indicators = r"(gasp|snoring|weird sound|agonal|struggling|breathing stopped|not breathing|ಉಸಿರಾಡುತ್ತಿಲ್ಲ|गैसपिंग|सांस बंद|சுவாசம் இல்லை|శ్వాస లేదు)"
    bleeding_indicators = r"(bleed|blood|cut|wound|stab|spurting|రక్తం|గాయం|ರಕ್ತ|ಗಾಯ|खून|घाव|ரத்தம்|காயம்|ചോര|മുറിവ്)"
    helmet_indicators = r"(helmet|neck|spine|bike|crash|motorcycle|scooter|ಆಕ್ಸಿಡೆಂಟ್|ಹೆಲ್ಮೆಟ್|हादसा|हेलमेट|விபத்து|ஹெல்மெட்|యాక్సిడెంట్|హెల్మెట్|ബൈക്ക്|ഹെൽമെറ്റ്)"
    choking_indicators = r"(chok|throat|food stuck|can't breathe|swallowed|ಗಂಟಲು|गले में अटक|दम घुट|திணறல்|గొంతు|തൊണ്ട)"
    seizure_indicators = r"(seizure|convulsion|shaking|fits|epilepsy|ಫಿಟ್ಸ್|ಸೆಳವು|दौरा|झटके|வலிப்பு|ఫిట్స్|കുഴഞ്ഞു)"
    stroke_indicators = r"(stroke|paralysis|droop|slurred|numbness|face drop|ಪಾರ್ಶ್ವವಾಯು|लकवा|பக்கவாதம்|పక్షవాతం|സ്ട്രോക്ക്)"

    # --- IMMEDIATE OVERRIDE: Check for Dual Emergency ---
    has_bleeding = bool(re.search(bleeding_indicators, text) and not is_no)
    has_helmet = bool(re.search(helmet_indicators, text))
    if has_bleeding and has_helmet:
        return {
            "resolved_protocol": "BLEEDING_AND_HELMET",
            "spoken_reassurance": DISPATCHER_SCRIPTS["BLEEDING_AND_HELMET"][lang],
            "next_stage": "ACTIVE_COACHING",
            "quick_options": ["PRESSURE APPLIED", "MEDICS ARRIVED", "CALL 112"],
            "language": lang
        }

    # --- IMMEDIATE OVERRIDE: Choking ---
    if re.search(choking_indicators, text):
        return {
            "resolved_protocol": "CHOKING",
            "spoken_reassurance": DISPATCHER_SCRIPTS["CARD_11_CHOKING"][lang],
            "next_stage": "ACTIVE_COACHING",
            "quick_options": ["OBJECT EXPELLED", "UNCONSCIOUS", "CALL 112"],
            "language": lang
        }

    # --- IMMEDIATE OVERRIDE: Active Seizures ---
    if re.search(seizure_indicators, text):
        return {
            "resolved_protocol": "SEIZURE",
            "spoken_reassurance": DISPATCHER_SCRIPTS["CARD_12_SEIZURE"][lang],
            "next_stage": "ACTIVE_COACHING",
            "quick_options": ["SHAKING STOPPED", "CALL 112"],
            "language": lang
        }

    # --- IMMEDIATE OVERRIDE: Stroke ---
    if re.search(stroke_indicators, text):
        return {
            "resolved_protocol": "STROKE",
            "spoken_reassurance": DISPATCHER_SCRIPTS["CARD_28_STROKE"][lang],
            "next_stage": "ACTIVE_COACHING",
            "quick_options": ["SYMPTOMS PRESENT", "NORMAL", "CALL 112"],
            "language": lang
        }

    # --- EMD STAGE 1: CASE ENTRY (Consciousness Check) ---
    if stage == "INITIAL":
        if re.search(agonal_indicators, text) or "unconscious" in text or "collapsed" in text or "fainted" in text:
            return {
                "resolved_protocol": None,
                "spoken_reassurance": DISPATCHER_SCRIPTS["ASK_BREATHING"][lang],
                "next_stage": "CHECK_BREATHING",
                "quick_options": ["NORMAL BREATHING", "GASPING / NO BREATHING", "NOT SURE"],
                "language": lang
            }
        if has_bleeding:
            return {
                "resolved_protocol": "BLEEDING",
                "spoken_reassurance": DISPATCHER_SCRIPTS["CARD_30_BLEEDING"][lang],
                "next_stage": "ACTIVE_COACHING",
                "quick_options": ["PRESSURE APPLIED", "BLEEDING SOAKED THROUGH", "CALL 112"],
                "language": lang
            }
        return {
            "resolved_protocol": None,
            "spoken_reassurance": DISPATCHER_SCRIPTS["SPEAKER_REMINDER"][lang],
            "next_stage": "CHECK_CONSCIOUSNESS",
            "quick_options": ["YES - AWAKE & TALKING", "NO - UNRESPONSIVE", "NOT SURE"],
            "language": lang
        }

    # --- EMD STAGE 2: CONSCIOUSNESS ASSESSMENT ---
    if stage == "CHECK_CONSCIOUSNESS":
        if is_no or is_not_sure or "unresponsive" in text:
            return {
                "resolved_protocol": None,
                "spoken_reassurance": DISPATCHER_SCRIPTS["ASK_BREATHING"][lang],
                "next_stage": "CHECK_BREATHING",
                "quick_options": ["NORMAL BREATHING", "NOT BREATHING / GASPING", "NOT SURE"],
                "language": lang
            }
        else:
            return {
                "resolved_protocol": None,
                "spoken_reassurance": "Understood. Is there severe bleeding, difficulty speaking, or chest pain?",
                "next_stage": "CHECK_COMPLAINT",
                "quick_options": ["SEVERE BLEEDING", "CHEST PAIN", "SLURRED SPEECH", "SAFE RESTING"],
                "language": lang
            }

    # --- EMD STAGE 3: BREATHING ASSESSMENT (Agonal Gasp Detection) ---
    if stage == "CHECK_BREATHING":
        if is_no or is_not_sure or re.search(agonal_indicators, text) or "gasp" in text:
            return {
                "resolved_protocol": "CPR",
                "spoken_reassurance": DISPATCHER_SCRIPTS["CARD_9_CPR"][lang],
                "next_stage": "ACTIVE_COACHING",
                "quick_options": ["START 110 BPM CPR", "THEY ARE VOMITING", "MEDICS ARRIVED"],
                "language": lang
            }
        else:
            return {
                "resolved_protocol": "SPINAL_CAUTION",
                "spoken_reassurance": "Normal breathing confirmed. Place them on their side in the recovery position. Do not leave them alone. Unlock the front door for paramedics.",
                "next_stage": "ACTIVE_COACHING",
                "quick_options": ["RECOVERY POSITION", "CALL 112"],
                "language": lang
            }

    # --- EMD STAGE 4: COMPLICATION HANDLING (Vomiting during CPR) ---
    if "vomit" in text or "gurgling" in text:
        return {
            "resolved_protocol": "SPINAL_CAUTION",
            "spoken_reassurance": "Stop compressions right now! Roll the person like a log onto their side facing you. Clear out their mouth with your fingers so they do not choke. Tell me when the mouth is clear.",
            "next_stage": "AIRWAY_CLEARED_CHECK",
            "quick_options": ["MOUTH IS CLEAR - RESUME CPR"],
            "language": lang
        }

    if stage == "AIRWAY_CLEARED_CHECK":
        return {
            "resolved_protocol": "CPR",
            "spoken_reassurance": "Roll them flat on their back again immediately. Hands back in the center of the chest. Resume pumping hard and fast at 110 beats per minute!",
            "next_stage": "ACTIVE_COACHING",
            "quick_options": ["START 110 BPM CPR", "MEDICS ARRIVED"],
            "language": lang
        }

    # Default fallback
    return {
        "resolved_protocol": "CPR",
        "spoken_reassurance": DISPATCHER_SCRIPTS["CARD_9_CPR"][lang],
        "next_stage": "ACTIVE_COACHING",
        "quick_options": ["START CPR", "CALL 112"],
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
        return StreamingResponse(buffer, media_type="audio/mp3", headers={"Content-Disposition": "inline; filename=speech.mp3"})
    except Exception:
        fallback = gTTS(text=text, lang='en', slow=False)
        buffer = io.BytesIO()
        fallback.write_to_fp(buffer)
        buffer.seek(0)
        return StreamingResponse(buffer, media_type="audio/mp3", headers={"Content-Disposition": "inline; filename=speech.mp3"})

@app.get("/api/health")
def health_check():
    return {"status": "online", "mode": "EMD Dispatch Engine"}