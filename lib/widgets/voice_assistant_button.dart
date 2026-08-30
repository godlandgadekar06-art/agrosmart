import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../theme.dart';

/// Floating mic button for voice interaction. Listens in Marathi (or
/// English, based on current locale), and can speak responses back —
/// important for farmers who are more comfortable speaking than typing/reading.
///
/// This handles the STT/TTS plumbing only. Wire [onCommand] to your own
/// intent-matching (e.g. simple keyword matching against feature names,
/// or a small NLU layer) to route what the farmer says to an action.
class VoiceAssistantButton extends StatefulWidget {
  final String languageCode; // 'mr' or 'en'
  final void Function(String recognizedText) onCommand;

  const VoiceAssistantButton({
    super.key,
    required this.languageCode,
    required this.onCommand,
  });

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _listening = false;

  String get _localeId => widget.languageCode == 'mr' ? 'mr_IN' : 'en_IN';

  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (!available) return;

    setState(() => _listening = true);
    await _speech.listen(
      localeId: _localeId,
      onResult: (result) {
        if (result.finalResult) {
          widget.onCommand(result.recognizedWords);
          setState(() => _listening = false);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _listening = false);
  }

  /// Call this to have the app speak feedback/instructions aloud —
  /// e.g. reading out a crop recommendation or an emergency alert.
  Future<void> speak(String text) async {
    await _tts.setLanguage(widget.languageCode == 'mr' ? 'mr-IN' : 'en-IN');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor:
          _listening ? AppColors.alertRed : AppColors.primaryGreen,
      onPressed: _listening ? _stopListening : _startListening,
      child: Icon(_listening ? Icons.mic : Icons.mic_none, size: 28),
    );
  }
}
