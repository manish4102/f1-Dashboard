import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

enum SnackbarType { success, error, warning, info }

class F1Snackbar {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required SnackbarType type,
  }) {
    final contentType = switch (type) {
      SnackbarType.success => ContentType.success,
      SnackbarType.error => ContentType.failure,
      SnackbarType.warning => ContentType.warning,
      SnackbarType.info => ContentType.help,
    };

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void success(BuildContext context, String message) {
    show(
      context: context,
      title: 'Success',
      message: message,
      type: SnackbarType.success,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context: context,
      title: 'Error',
      message: message,
      type: SnackbarType.error,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context: context,
      title: 'Warning',
      message: message,
      type: SnackbarType.warning,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context: context,
      title: 'Info',
      message: message,
      type: SnackbarType.info,
    );
  }
}
