import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../l10n/language_provider.dart';
import 'tutorial_overlay.dart';
import 'tutorial_service.dart';

/// Wrapper che mostra il tutorial al primo accesso
class TutorialWrapper extends ConsumerStatefulWidget {
  final String tutorialId;
  final List<TutorialStep> Function(AppLanguage) stepsBuilder;
  final Widget child;
  
  const TutorialWrapper({
    super.key,
    required this.tutorialId,
    required this.stepsBuilder,
    required this.child,
  });
  
  @override
  ConsumerState<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends ConsumerState<TutorialWrapper> {
  bool _showTutorial = false;
  bool _checked = false;
  
  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }
  
  Future<void> _checkTutorial() async {
    final seen = await TutorialService.hasSeenTutorial(widget.tutorialId);
    if (mounted && !seen) {
      setState(() {
        _showTutorial = true;
        _checked = true;
      });
    } else if (mounted) {
      setState(() => _checked = true);
    }
  }
  
  Future<void> _completeTutorial() async {
    await TutorialService.markTutorialAsSeen(widget.tutorialId);
    if (mounted) {
      setState(() => _showTutorial = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    
    if (!_checked) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        if (_showTutorial)
          TutorialOverlay(
            steps: widget.stepsBuilder(language),
            onComplete: _completeTutorial,
            skipText: switch (language) {
              AppLanguage.italian => 'Salta',
              AppLanguage.english => 'Skip',
              AppLanguage.chinese => '跳过',
            },
          ),
      ],
    );
  }
}
