import 'package:flutter/material.dart';
import 'empty_state_view.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isRateLimited;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.isRateLimited = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: isRateLimited
          ? Icons.hourglass_top_rounded
          : Icons.cloud_off_rounded,
      title: isRateLimited ? 'Taking a short break' : "Couldn't load photos",
      message: message,
      buttonText: 'Try again',
      buttonIcon: Icons.refresh_rounded,
      onButtonPressed: onRetry,
    );
  }
}
