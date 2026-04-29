import 'package:flutter/material.dart';

enum AppToastType { success, error, info }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final backgroundColor = switch (type) {
    AppToastType.success => Colors.green.shade700,
    AppToastType.error => Colors.red.shade700,
    AppToastType.info => Colors.black,
  };
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.fixed,
    ),
  );
}
