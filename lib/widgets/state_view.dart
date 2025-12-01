import 'package:flutter/material.dart';

class StateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const StateView({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
    this.retryLabel,
  });

  factory StateView.error({required String message, VoidCallback? onRetry}) {
    return StateView(
      title: 'Oops!',
      message: message,
      icon: Icons.error_outline_rounded,
      onRetry: onRetry,
      retryLabel: 'Try Again',
    );
  }

  factory StateView.empty({
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return StateView(
      title: 'Nothing Here',
      message: message,
      icon: Icons.search_off_rounded,
      onRetry: onAction,
      retryLabel: actionLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
