import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class F1LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final Duration minDuration;

  const F1LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.minDuration = const Duration(seconds: 3),
  });

  @override
  State<F1LoadingOverlay> createState() => _F1LoadingOverlayState();
}

class _F1LoadingOverlayState extends State<F1LoadingOverlay> {
  bool _minDurationPassed = false;

  @override
  void didUpdateWidget(F1LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startLoading();
    }
  }

  void _startLoading() {
    _minDurationPassed = false;
    Future.delayed(widget.minDuration, () {
      if (mounted) {
        setState(() {
          _minDurationPassed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: LoadingAnimationWidget.newtonCradle(
                    color: const Color(0xFFE10600),
                    size: 500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
