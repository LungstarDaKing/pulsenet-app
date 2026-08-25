import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _spokenWords = '';
  String _lastWords = '';
  String _firstAidAdvice = 'Tap the mic and say a first aid situation (e.g., "choking", "bleeding")';

  // Simple keyword -> advice map
  final Map<String, String> _firstAidMap = {
    "cpr": "CPR (Cardiopulmonary Resuscitation):\n1. Check responsiveness and breathing.\n2. If not breathing, call 112 and start chest compressions.\n3. Place hands in center of chest, push hard and fast (100-120 compressions/min).\n4. After 30 compressions, give 2 rescue breaths if trained.\n5. Continue until help arrives.",
    "choking": "Choking (Conscious Adult/Child):\n1. Encourage coughing if they can speak or cough.\n2. If cannot speak/breathe, give 5 back blows between shoulder blades.\n3. If still blocked, give 5 abdominal thrusts (Heimlich maneuver).\n4. Alternate 5 back blows and 5 abdominal thrusts until object is expelled or person becomes unconscious.\n5. If unconscious, call 112 and start CPR.",
    "bleeding": "Severe Bleeding:\n1. Apply direct pressure on wound with clean cloth or bandage.\n2. If bleeding continues, add more cloth and press harder.\n3. If limb injury and bleeding doesn't stop, consider a tourniquet (only as last resort).\n4. Keep victim lying still and warm.\n5. Call 112.",
    "burn": "Burns:\n1. Cool the burn with cool (not cold) running water for 10-20 minutes.\n2. Remove jewelry or tight clothing before swelling.\n3. Cover with sterile non-stick dressing or clean cloth.\n4. Do not apply ice, butter, or ointments.\n5. For severe burns (large area, face, hands, feet, genitals), call 112.",
    "stroke": "Stroke (Think F.A.S.T.):\nF - Face drooping: Ask to smile, check if one side droops.\nA - Arm weakness: Ask to raise both arms, check if one drifts down.\nS - Speech difficulty: Ask to repeat a simple phrase, check for slurring.\nT - Time to call 112 immediately if any signs present.\nNote time when symptoms started.",
    "anaphylaxis": "Severe Allergic Reaction (Anaphylaxis):\n1. Administer epinephrine auto-injector (EpiPen) if available.\n2. Call 112 immediately.\n3. Have person lie flat with legs raised unless vomiting or breathing difficulty.\n4. If breathing stops, begin CPR.\n5. Second dose may be needed after 5-15 minutes if symptoms persist.",
    "fracture": "Suspected Fracture:\n1. Keep the injured area still and supported.\n2. Apply ice wrapped in cloth to reduce swelling.\n3. Do not try to straighten the bone.\n4. Seek medical attention promptly (call 112 if severe).\n5. If open wound, cover with sterile dressing and apply pressure around (not on) the wound.",
    "heatstroke": "Heat Stroke:\n1. Call 112 immediately.\n2. Move person to cool, shaded area.\n3. Remove excess clothing.\n4. Cool rapidly with ice packs to neck, armpits, groin, or immerse in cool water.\n5. Fan while wetting skin.\n6. Do NOT give fluids if unconscious or vomiting.",
    "seizure": "Seizure:\n1. Stay calm, time the seizure.\n2. Clear area of hard/sharp objects.\n3. Cushion head, do NOT restrain or put anything in mouth.\n4. Turn person onto side if possible to keep airway clear.\n5. Stay with them until fully awake.\n6. Call 112 if seizure lasts >5 minutes, repeat seizures, or if injured, diabetic, or pregnant.",
    "poisoning": "Suspected Poisoning:\n1. Call 112 or poison control immediately.\n2. Do NOT induce vomiting unless instructed.\n3. Identify the poison if possible (container, symptoms).\n4. Follow emergency operator instructions.\n5. If chemical on skin, rinse with water for 15+ minutes.",
    "drowning": "Drowning Rescue:\n1. Ensure your own safety first.\n2. Get person out of water.\n3. Check responsiveness and breathing.\n4. If not breathing, give 2 rescue breaths then start CPR.\n5. If breathing but unconscious, place in recovery position.\n6. Continue until help arrives.\n7. Even if they seem fine, seek medical evaluation (secondary drowning risk).",
    "hypothermia": "Hypothermia:\n1. Call 112.\n2. Move person to warm, dry place.\n3. Remove wet clothing.\n4. Warm core first (chest, neck, head, groin) using blankets, warm compresses.\n5. Do NOT apply direct heat (hot water, heating pad) to limbs.\n6. Give warm sweet drinks only if conscious and able to swallow.",
    "asthma": "Asthma Attack:\n1. Help person sit upright and stay calm.\n2. Assist with their rescue inhaler (usually blue) if available: 1 puff, wait 30 sec, second puff if needed.\n3. If no improvement after a few doses or worsening, call 112.\n4. Loosen tight clothing.\n5. Monitor breathing until help arrives.",
    "snakebite": "Snake Bite:\n1. Call 112.\n2. Keep victim still and calm to slow venom spread.\n3. Keep bitten area at or below heart level.\n4. Remove constrictive items (jewelry, tight clothing).\n5. DO NOT cut, suck, or apply tourniquet.\n6. Cover wound with loose, sterile bandage.\n7. Try to remember snake color/shape for ID, but do not risk another bite.",
    "electric shock": "Electric Shock:\n1. DO NOT touch victim if still in contact with source.\n2. Turn off power source if possible, or use non-conductive object to push wire away.\n3. Check responsiveness and breathing.\n4. If not breathing, start CPR and call 112.\n5. Even if they seem fine, seek medical attention (internal injuries possible).\n6. Check for entry and exit wounds.",
    "spinal injury": "Suspected Spinal Injury:\n1. DO NOT move person unless in immediate danger.\n2. Call 112 immediately.\n3. Keep head and neck aligned, prevent twisting.\n4. If wearing helmet, do NOT remove unless necessary for airway.\n5. Monitor breathing and be ready to perform CPR if needed.",
    "labor": "Labor / Pregnancy Emergency:\n1. Call 112 if contractions are <5 minutes apart, water breaks, bleeding, severe pain, or decreased fetal movement.\n2. Have person lie on left side to improve blood flow.\n3. Time contractions.\n4. Do NOT give anything to eat or drink.\n5. Prepare for birth: clean towels, warm water.\n6. If baby comes, do not pull; let it emerge naturally.\n7. Keep baby warm, place on mother's chest.",
    "nosebleed": "Nosebleed:\n1. Sit upright, lean slightly forward (do NOT tilt head back).\n2. Pinch the soft part of nose just below the bridge for 10-15 minutes.\n3. Breathe through mouth.\n4. Apply ice pack to bridge of nose if helpful.\n5. If bleeding doesn't stop after 20 minutes or follows injury, seek medical care.",
    "fainting": "Fainting (Syncope):\n1. Position person on their back.\n2. If no injury, elevate legs about 12 inches.\n3. Loosen tight clothing.\n4. Check breathing; if not breathing, start CPR.\n5. When conscious, give fluids if able to swallow.\n6. If caused by injury or doesn't recover quickly, seek medical care.",
    "mental health crisis": "Mental Health Crisis:\n1. Stay calm, listen without judgment.\n2. Ask directly if they are thinking about suicide.\n3. If yes or in crisis, call 112 immediately.\n4. Stay with them until help arrives.\n5. Do not leave them alone.\n6. Remove access to weapons, medications, or other means of self-harm.",
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) => debugPrint('Speech status: $val'),
      onError: (val) => debugPrint('Speech error: $val'),
    );
    if (!available) {
      setState(() {
        _firstAidAdvice = 'Speech recognition not available on this device.';
      });
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      if (!available) {
        setState(() => _firstAidAdvice = 'Speech recognition failed to start.');
        return;
      }
      setState(() {
        _isListening = true;
        _spokenWords = '';
        _lastWords = '';
      });
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _onSpeechResult(dynamic result) {
    // Try different property names for recognized text
    String? recognizedText = result.recognizedWords;
    if (recognizedText == null || recognizedText.isEmpty) {
      recognizedText = result.text;
    }
    if (recognizedText == null || recognizedText.isEmpty) {
      // Fallback to empty string if neither property works
      recognizedText = '';
    }

    setState(() {
      _spokenWords = recognizedText ?? '';
    });
    // Process final result
    if (result.finalResult) {
      setState(() {
        _lastWords = _spokenWords;
      });
      _processSpeech(_spokenWords);
    }
  }

  void _processSpeech(String spoken) {
    final lower = spoken.toLowerCase().trim();
    String? advice;
    // Check for exact or contained match
    _firstAidMap.forEach((key, value) {
      if (lower.contains(key)) {
        advice = value;
      }
    });
    if (advice != null) {
      setState(() {
        _firstAidAdvice = advice!;
      });
    } else {
      setState(() {
        _firstAidAdvice = "I didn't recognize that. Try: CPR, choking, bleeding, burn, stroke, etc.\nIf uncertain, call 112 now.";
      });
    }
  }

  void _clearSpeech() {
    setState(() {
      _spokenWords = '';
      _lastWords = '';
      _firstAidAdvice = 'Tap the mic and say a first aid situation';
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Assistant'),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Display what was heard
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You said:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastWords.isNotEmpty ? _lastWords : '(listening...)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Advice display
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Text(
                        _firstAidAdvice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Mic button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : Colors.grey[800],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.white70,
                      size: 36,
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isListening ? 'Listening...' : 'Tap to speak',
                  style: TextStyle(
                    color: _isListening ? Colors.red : Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _clearSpeech,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }
}