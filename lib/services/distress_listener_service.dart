import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart';
import '../services/sos_service.dart';

class DistressListenerService {
  final SpeechToText _speech = SpeechToText();
  final SosService _sosService = SosService();

  bool _isListening = false;
  bool _isArmed = false;
  DateTime? _armTime;
  Timer? _autoDisarmTimer;
  String? _currentLocale; // The locale ID we are currently listening for
  Timer? _tapTimer;
  int _tapCount = 0;
  bool _isNotificationShown = false;

  // Cache for loaded distress phrases by locale code
  final Map<String, List<String>> _distressPhrasesCache = {};

  DistressListenerService();

  /// Loads distress phrases for the given locale from an asset file.
  /// The asset file should be at "assets/data/distress_phrases/{locale}.txt"
  /// Each line in the file is a phrase.
  Future<List<String>> _loadDistressPhrasesForLocale(String locale) async {
    // Return cached version if we have it
    if (_distressPhrasesCache.containsKey(locale)) {
      return _distressPhrasesCache[locale]!;
    }

    try {
      // Try to load the asset file for the locale
      final String assetPath = 'assets/data/distress_phrases/$locale.txt';
      final String content = await rootBundle.loadString(assetPath);
      // Split by newline, trim each line, and ignore empty lines
      final List<String> lines = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      _distressPhrasesCache[locale] = lines;
      return lines;
    } catch (e) {
      // If the file is not found or any other error, return an empty list
      // and we will fall back to English if needed.
      log('Could not load distress phrases for locale $locale: $e');
      return [];
    }
  }

  /// Handles tap events for the 4-tap gesture
  void handleTap() {
    // If already armed, ignore additional taps
    if (_isArmed) {
      return;
    }

    _tapCount++;

    // Reset timer on each tap
    _tapTimer?.cancel();

    // If this is the first tap, start the timer
    if (_tapCount == 1) {
      _tapTimer = Timer(const Duration(seconds: 5), () {
        // Reset tap count after 5 seconds of inactivity
        _tapCount = 0;
      });
    }

    // If we've reached 4 taps, arm the detector
    if (_tapCount >= 4) {
      _tapCount = 0; // Reset counter
      _tapTimer?.cancel(); // Cancel the timer
      _armDistressListener();
    }
  }

  Future<bool> startListening({required String localeId}) async {
    if (!await _speech.initialize(
      onStatus: (val) => log('onSpeechStatus: $val'),
      onError: (val) => log('onSpeechError: $val'),
    )) {
      return false;
    }

    _currentLocale = localeId;
    _isListening = true;

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30), // Listen indefinitely until stopped
        pauseFor: const Duration(seconds: 2), // Wait 2 seconds of silence before stopping
      ),
      onResult: _onSpeechResult,
    );
    return true;
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  void _onSpeechResult(dynamic result) {
    if (!_isListening) return; // We might have stopped listening while waiting for result

    // Try different property names for recognized text
    String? recognizedText = result.recognizedWords;
    if (recognizedText == null || recognizedText.isEmpty) {
      recognizedText = result.text;
    }
    if (recognizedText == null || recognizedText.isEmpty) {
      // Fallback to empty string if neither property works
      recognizedText = '';
    }

    final String recognized = recognizedText.toLowerCase();
    log('Recognized: $recognized');

    // If we don't have a current locale, we can't check phrases.
    if (_currentLocale == null) {
      return;
    }

    // Load the distress phrases for the current locale (from cache or asset)
    _loadDistressPhrasesForLocale(_currentLocale!).then((List<String> phrases) {
      // Check if any phrase matches
      for (final String phrase in phrases) {
        if (recognized.contains(phrase.toLowerCase())) {
          // Found a match! Trigger silent SOS.
          _triggerSilentSos();
          break;
        }
      }

      // If we are still listening and armed, continue listening
      if (_isListening && _isArmed) {
        // Continue listening is handled by the speech_to_text plugin's continuous listening
      }
    });
  }

  void _triggerSilentSos() {
    // Fire and forget - we don't await because we don't want to block the speech listener
    _sosService.triggerSos().then((_) {
      // In a real app, we might show a subtle indicator
      log('Silent SOS triggered');
    }).catchError((e) {
      log('Error triggering SOS: $e');
    });
  }

  /// Call this when the user performs the 4-tap gesture
  void _armDistressListener() {
    _isArmed = true;
    _armTime = DateTime.now();
    _isNotificationShown = false; // Reset notification flag

    // Start auto-disarm timer for exactly 90 seconds (1 minute 30 seconds)
    _autoDisarmTimer?.cancel();
    _autoDisarmTimer = Timer(const Duration(seconds: 90), () {
      _autoDisarm();
    });

    // Start listening in the device's current locale
    // TODO: Replace with actual device locale
    startListening(localeId: 'en');

    // Notify user that listening is armed
    // In a real app, we'd show a snackbar or toast here
    log('Distress listener armed - listening for 90 seconds');
  }

  /// Auto-disarm after 90 seconds
  void _autoDisarm() {
    if (_isArmed) {
      disarm();
      // Show one-time notification that listening has stopped
      if (!_isNotificationShown) {
        _isNotificationShown = true;
        // In a real app, we'd show a snackbar or toast here
        log('Distress listener automatically disarmed after 90 seconds');
      }
    }
  }

  /// Call this to manually disarm (e.g., if user wants to cancel early)
  void disarm() {
    _isArmed = false;
    _armTime = null;
    _autoDisarmTimer?.cancel();
    _tapTimer?.cancel();
    _tapCount = 0;
    stopListening();

    // In a real app, we might show a brief confirmation
    log('Distress listener disarmed');
  }

  bool get isArmed => _isArmed;

  /// Returns true if the armed state is still valid (not auto-disarmed yet)
  bool get isArmedAndActive {
    if (!_isArmed) return false;
    if (_armTime == null) return false;
    return DateTime.now().isBefore(_armTime!.add(const Duration(minutes: 1, seconds: 30)));
  }

  void dispose() {
    disarm();
    // Note: Not calling super.dispose() as this class doesn't extend a State class
  }
}