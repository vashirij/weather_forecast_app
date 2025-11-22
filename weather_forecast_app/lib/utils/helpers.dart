import 'package:flutter/material.dart';

class Helpers {
  // Use a typed BuildContext for clarity and analyzer friendliness.
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? const Color(0xFFD32F2F)
          : const Color(0xFF388E3C),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
