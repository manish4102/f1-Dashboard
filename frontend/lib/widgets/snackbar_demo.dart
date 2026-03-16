import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

enum SnackbarType { success, error, warning, info }

class SnackbarDemo extends StatelessWidget {
  const SnackbarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snackbar Demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              context,
              'Success',
              () => _showSnackbar(context, SnackbarType.success),
            ),
            _buildButton(
              context,
              'Error',
              () => _showSnackbar(context, SnackbarType.error),
            ),
            _buildButton(
              context,
              'Warning',
              () => _showSnackbar(context, SnackbarType.warning),
            ),
            _buildButton(
              context,
              'Info',
              () => _showSnackbar(context, SnackbarType.info),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }

  void _showSnackbar(BuildContext context, SnackbarType type) {
    final contentType = switch (type) {
      SnackbarType.success => ContentType.success,
      SnackbarType.error => ContentType.failure,
      SnackbarType.warning => ContentType.warning,
      SnackbarType.info => ContentType.help,
    };

    final title = switch (type) {
      SnackbarType.success => 'Success',
      SnackbarType.error => 'Error',
      SnackbarType.warning => 'Warning',
      SnackbarType.info => 'Info',
    };

    final message = switch (type) {
      SnackbarType.success => 'Operation completed successfully!',
      SnackbarType.error => 'Something went wrong. Please try again.',
      SnackbarType.warning => 'This action cannot be undone.',
      SnackbarType.info => 'Here is some useful information for you.',
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
}
