import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Servizio per riprodurre suoni di notifica quando arrivano nuovi ordini
class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Riproduce un suono di notifica per nuovo ordine + vibrazione
  Future<void> playNewOrderSound() async {
    try {
      // Vibrazione forte ripetuta
      for (int i = 0; i < 3; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
      }
      
      // Suono di notifica usando un URL di suono gratuito
      await _player.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      // Fallback: solo vibrazione se il suono fallisce
      for (int i = 0; i < 5; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Riproduce un suono più leggero per modifiche ordine
  Future<void> playOrderModifiedSound() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  void dispose() {
    _player.dispose();
  }
}
