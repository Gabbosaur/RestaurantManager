import 'package:flutter/material.dart';

/// Step di un tutorial
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  
  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Overlay per mostrare tutorial passo-passo
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final String? skipText;
  
  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.skipText,
  });
  
  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;
  
  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final isLast = _currentStep == widget.steps.length - 1;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    widget.skipText ?? 'Salta',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                step.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                step.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.steps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentStep ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentStep 
                          ? colorScheme.primary 
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Navigation buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Indietro'),
                      ),
                    )
                  else
                    const Spacer(),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isLast ? 'Inizia!' : 'Avanti'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
