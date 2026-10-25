import 'package:flutter/material.dart';

import '../core/strings.dart';

/// Shows a spinner while [loading], an [ErrorPanel] when [error] is set,
/// otherwise [child] wrapped in pull-to-refresh when [onRefresh] is given.
class AsyncBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final String? loadingMessage;
  final Future<void> Function()? onRefresh;
  final Widget child;

  const AsyncBody({
    super.key,
    required this.loading,
    required this.child,
    this.error,
    this.loadingMessage,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return LoadingView(message: loadingMessage);
    if (error != null) return ErrorPanel(message: error!, onRetry: onRefresh);
    if (onRefresh == null) return child;
    return RefreshIndicator(onRefresh: onRefresh!, child: child);
  }
}

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[const SizedBox(height: 16), Text(message!)],
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorPanel({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 42, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: Text(S.retry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder card for empty lists. Kept inside a scrollable so
/// pull-to-refresh still works.
class EmptyCard extends StatelessWidget {
  final String message;
  const EmptyCard(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
