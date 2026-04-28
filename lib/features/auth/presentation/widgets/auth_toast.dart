import 'package:flutter/material.dart';

void showAuthErrorToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.fixed,
    ),
  );
}
