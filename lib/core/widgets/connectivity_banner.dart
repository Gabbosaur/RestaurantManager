import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/language_provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Banner che mostra lo stato della connessione
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final pendingCount = ref.watch(pendingActionsCountProvider);
    final language = ref.watch(languageProvider);
    final l10n = AppLocalizations(language);

    // Non mostrare nulla se online e nessuna azione pendente
    if (connectivity == ConnectivityState.online && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Material(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        color: _getBackgroundColor(connectivity, pendingCount),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                _getIcon(connectivity),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getMessage(connectivity, pendingCount, l10n),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (connectivity == ConnectivityState.offline && pendingCount > 0)
                TextButton(
                  onPressed: () => _trySync(ref),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(l10n.retry),
                ),
              if (connectivity == ConnectivityState.syncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ConnectivityState state, int pendingCount) {
    switch (state) {
      case ConnectivityState.offline:
        return Colors.red.shade700;
      case ConnectivityState.syncing:
        return Colors.orange.shade700;
      case ConnectivityState.online:
        return pendingCount > 0 ? Colors.orange.shade700 : Colors.green;
    }
  }

  IconData _getIcon(ConnectivityState state) {
    switch (state) {
      case ConnectivityState.offline:
        return Icons.wifi_off;
      case ConnectivityState.syncing:
        return Icons.sync;
      case ConnectivityState.online:
        return Icons.cloud_upload;
    }
  }

  String _getMessage(ConnectivityState state, int pendingCount, AppLocalizations l10n) {
    switch (state) {
      case ConnectivityState.offline:
        if (pendingCount > 0) {
          return '${l10n.offline} - $pendingCount ${l10n.pendingActions}';
        }
        return l10n.offline;
      case ConnectivityState.syncing:
        return l10n.syncing;
      case ConnectivityState.online:
        if (pendingCount > 0) {
          return '$pendingCount ${l10n.pendingActions}';
        }
        return l10n.online;
    }
  }

  Future<void> _trySync(WidgetRef ref) async {
    await ref.read(connectivityProvider.notifier).checkNow();
    final connectivity = ref.read(connectivityProvider);
    if (connectivity == ConnectivityState.online) {
      await ref.read(syncServiceProvider).syncPendingActions();
    }
  }
}
