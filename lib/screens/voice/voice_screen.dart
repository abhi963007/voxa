import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/providers/voice_provider.dart';
import '../../core/providers/task_provider.dart';
import 'package:intl/intl.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _waveController;
  late AnimationController _orbController;

  bool _hasResult = false;
  Map<String, dynamic>? _parsedResult;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _waveController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final voiceProvider = context.read<VoiceProvider>();
    if (!voiceProvider.speechEnabled) {
      await voiceProvider.initSpeech();
    }
    await voiceProvider.startListening();
  }

  Future<void> _stopAndParse() async {
    final voiceProvider = context.read<VoiceProvider>();
    await voiceProvider.stopListening();

    final text = voiceProvider.transcribedText;
    if (text.isNotEmpty) {
      final result = voiceProvider.parseVoiceInput(text);
      setState(() {
        _hasResult = true;
        _parsedResult = result;
      });
    }
  }

  Future<void> _confirmAction() async {
    if (_parsedResult == null) return;
    final taskProvider = context.read<TaskProvider>();
    final type = _parsedResult!['type'];

    if (type == 'task') {
      await taskProvider.addTask(
        title: _parsedResult!['title'],
        dueTime: _parsedResult!['time'],
        priority: _parsedResult!['priority'] ?? 0,
        addedViaVoice: true,
      );
    } else if (type == 'reminder') {
      await taskProvider.addReminder(
        title: _parsedResult!['title'],
        scheduledTime: _parsedResult!['time'] ??
            DateTime.now().add(const Duration(hours: 1)),
        addedViaVoice: true,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _TopBar(),

            const Spacer(flex: 1),

            // Voice Orb
            _VoiceOrb(
              ringController: _ringController,
              waveController: _waveController,
              orbController: _orbController,
              isListening: voiceProvider.isListening,
              soundLevel: voiceProvider.soundLevel,
            ),

            const SizedBox(height: 36),

            // Transcript
            _TranscriptArea(
              text: voiceProvider.transcribedText,
              isListening: voiceProvider.isListening,
            ),

            const SizedBox(height: 20),

            // Parsed result preview
            if (_hasResult && _parsedResult != null)
              _ParsedResultCard(
                result: _parsedResult!,
                onConfirm: _confirmAction,
                onEdit: () => setState(() {
                  _hasResult = false;
                  _parsedResult = null;
                }),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

            const Spacer(flex: 2),

            // Controls
            _ControlBar(
              isListening: voiceProvider.isListening,
              onStop: _stopAndParse,
              hasResult: _hasResult,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            'voxa',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurfaceVariant,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _VoiceOrb extends StatelessWidget {
  final AnimationController ringController;
  final AnimationController waveController;
  final AnimationController orbController;
  final bool isListening;
  final double soundLevel;

  const _VoiceOrb({
    required this.ringController,
    required this.waveController,
    required this.orbController,
    required this.isListening,
    required this.soundLevel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ringController, orbController]),
      builder: (context, child) {
        final scale = 1.0 + (soundLevel.abs() / 100) * 0.15;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ring 1
            Opacity(
              opacity: (1 - ringController.value).clamp(0.0, 0.6),
              child: Transform.scale(
                scale: 1 + ringController.value * 0.8,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Ring 2
            Opacity(
              opacity: ((1 - ((ringController.value + 0.33) % 1.0))
                  .clamp(0.0, 0.6)),
              child: Transform.scale(
                scale: 1 + ((ringController.value + 0.33) % 1.0) * 0.8,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Ring 3
            Opacity(
              opacity: ((1 - ((ringController.value + 0.66) % 1.0))
                  .clamp(0.0, 0.4)),
              child: Transform.scale(
                scale: 1 + ((ringController.value + 0.66) % 1.0) * 0.8,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
            // Core orb
            Transform.scale(
              scale: isListening ? scale : 1.0,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.primaryDim,
                      AppColors.primary,
                      Color(0xFF5B21B6),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: isListening
                    ? _Waveform(controller: waveController)
                    : const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 56),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Waveform extends StatelessWidget {
  final AnimationController controller;
  const _Waveform({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(7, (i) {
              final phase = (controller.value + i * 0.15) % 1.0;
              final height = 8 + 30 * math.sin(phase * math.pi);
              return Container(
                width: 4,
                height: height.abs(),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Colors.white, AppColors.accentLight],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _TranscriptArea extends StatelessWidget {
  final String text;
  final bool isListening;

  const _TranscriptArea({required this.text, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            if (text.isNotEmpty)
              Text(
                '"$text"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                  height: 1.5,
                ),
              )
            else
              Text(
                'Speak now...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            if (isListening)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentLight,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(end: const Offset(1.5, 1.5), duration: 600.ms)
                      .then()
                      .scale(end: const Offset(1.0, 1.0), duration: 600.ms),
                  const SizedBox(width: 8),
                  Text(
                    'Listening...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.accentLight,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ParsedResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const _ParsedResultCard({
    required this.result,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final type = result['type'] as String;
    final title = result['title'] as String;
    final time = result['time'] as DateTime?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'reminder'
                      ? Icons.notifications_rounded
                      : Icons.check_circle_outline_rounded,
                  color: AppColors.primaryLight,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  type == 'reminder' ? 'Creating reminder' : 'Adding task',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.label_outline,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (time != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEE, MMM d · h:mm a').format(time),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDim],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final bool isListening;
  final VoidCallback onStop;
  final bool hasResult;

  const _ControlBar({
    required this.isListening,
    required this.onStop,
    required this.hasResult,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isListening ? onStop : null,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.surfaceContainerHigh,
              border: Border.all(
                color: isListening
                    ? AppColors.error
                    : AppColors.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.stop_rounded,
              color: isListening ? AppColors.error : AppColors.onSurfaceVariant,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!hasResult)
          Text(
            "or say 'cancel' to dismiss",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

