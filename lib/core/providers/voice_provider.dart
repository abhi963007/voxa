import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceState { idle, listening, processing, error }

class VoiceProvider extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  VoiceState _voiceState = VoiceState.idle;
  String _transcribedText = '';
  String _lastWords = '';
  bool _speechEnabled = false;
  double _soundLevel = 0.0;

  VoiceState get voiceState => _voiceState;
  String get transcribedText => _transcribedText;
  String get lastWords => _lastWords;
  bool get isListening => _voiceState == VoiceState.listening;
  bool get speechEnabled => _speechEnabled;
  double get soundLevel => _soundLevel;

  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        _voiceState = VoiceState.error;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> startListening() async {
    _transcribedText = '';
    _lastWords = '';
    _voiceState = VoiceState.listening;
    notifyListeners();

    await _speechToText.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        _transcribedText = result.recognizedWords;
        notifyListeners();
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _voiceState = VoiceState.processing;
    notifyListeners();

    // Simulate brief processing
    await Future.delayed(const Duration(milliseconds: 500));
    _voiceState = VoiceState.idle;
    notifyListeners();
  }

  void resetState() {
    _voiceState = VoiceState.idle;
    _transcribedText = '';
    _lastWords = '';
    _soundLevel = 0.0;
    notifyListeners();
  }

  /// Parses voice input into task/reminder using rule-based approach (Phase 1)
  Map<String, dynamic>? parseVoiceInput(String input) {
    final lower = input.toLowerCase();

    // Check for reminder intent
    if (lower.contains('remind') ||
        lower.contains('reminder') ||
        lower.contains('alert')) {
      return {
        'type': 'reminder',
        'title': _extractTitle(input),
        'time': _extractTime(lower),
      };
    }

    // Check for task intent
    if (lower.contains('add task') ||
        lower.contains('create task') ||
        lower.contains('add') ||
        lower.contains('todo') ||
        lower.contains('to do') ||
        lower.contains('plan to') ||
        lower.contains('need to') ||
        lower.contains('have to') ||
        lower.contains('finish') ||
        lower.contains('complete')) {
      return {
        'type': 'task',
        'title': _extractTitle(input),
        'time': _extractTime(lower),
        'priority': _extractPriority(lower),
      };
    }

    // Default: treat as task
    return {
      'type': 'task',
      'title': input,
      'time': _extractTime(lower),
      'priority': _extractPriority(lower),
    };
  }

  String _extractTitle(String input) {
    String title = input;

    // Remove trigger phrases
    final triggers = [
      'add task',
      'create task',
      'add a task',
      'remind me to',
      'remind me at',
      'set a reminder',
      'set reminder',
      'add',
      'remind me',
    ];

    for (final trigger in triggers) {
      title = title.toLowerCase().replaceAll(trigger, '').trim();
    }

    // Remove time references
    final timePatterns = [
      RegExp(r'\bat \d+:\d+\s*(am|pm)?\b', caseSensitive: false),
      RegExp(r'\bat \d+\s*(am|pm)\b', caseSensitive: false),
      RegExp(r'\btomorrow\b', caseSensitive: false),
      RegExp(r'\btoday\b', caseSensitive: false),
      RegExp(r'\btonig(ht)?\b', caseSensitive: false),
      RegExp(r'\bthis evening\b', caseSensitive: false),
      RegExp(r'\bin the morning\b', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      title = title.replaceAll(pattern, '').trim();
    }

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return title.isEmpty ? input : title;
  }

  DateTime? _extractTime(String input) {
    final now = DateTime.now();

    // Check for "tonight" or "this evening"
    if (input.contains('tonight') || input.contains('this evening')) {
      return DateTime(now.year, now.month, now.day, 19, 0);
    }

    // Check for "tomorrow"
    final tomorrow = now.add(const Duration(days: 1));
    if (input.contains('tomorrow')) {
      // Check for time part
      final timeMatch = RegExp(r'(\d+)\s*(am|pm)', caseSensitive: false)
          .firstMatch(input);
      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        final period = timeMatch.group(2)!.toLowerCase();
        if (period == 'pm' && hour != 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, 0);
      }
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    }

    // Check for specific time e.g. "7 pm", "7:30 pm"
    final timeRegex = RegExp(
        r'(\d+)(?::(\d+))?\s*(am|pm)',
        caseSensitive: false);
    final match = timeRegex.firstMatch(input);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final period = match.group(3)!.toLowerCase();
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    return null;
  }

  int _extractPriority(String input) {
    if (input.contains('urgent') ||
        input.contains('asap') ||
        input.contains('immediately') ||
        input.contains('critical')) {
      return 2;
    }
    if (input.contains('important') ||
        input.contains('high priority') ||
        input.contains('priority')) {
      return 1;
    }
    return 0;
  }
}
