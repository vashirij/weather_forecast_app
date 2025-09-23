import 'package:flutter/material.dart';

class Helpers {
  static void showSnackBar(context, String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? const Color(0xFFD32F2F)
          : const Color(0xFF388E3C),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
