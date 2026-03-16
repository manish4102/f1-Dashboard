import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _failed = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Fallback in case web decoding/asset path fails.
    _fallback = Timer(const Duration(seconds: 5), () {
      if (!_ready) setState(() => _failed = true);
    });

    try {
      final c = VideoPlayerController.asset('assets/videos/splash.mp4');
      _c = c;

      await c.initialize();

      // Autoplay policy: MUST be muted on web for reliable autoplay.
      await c.setVolume(0.0);
      await c.setLooping(false);

      setState(() => _ready = true);

      // Start playback
      await c.play();

      // When finished, go next
      c.addListener(() {
        final v = c.value;
        if (v.isInitialized && !v.isPlaying && v.position >= v.duration) {
          widget.onDone();
        }
      });
    } catch (_) {
      setState(() => _failed = true);
    } finally {
      _fallback?.cancel();
    }
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _ready && c != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  )
                : const SizedBox.expand(),
          ),

          // If it fails or takes too long, show a simple continue UI.
          if (!_ready)
            Positioned.fill(
              child: Center(
                child: _failed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Loading intro…",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: widget.onDone,
                            child: const Text("Continue"),
                          ),
                        ],
                      )
                    : const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            ),

          // Optional skip button
          Positioned(
            right: 18,
            top: 18,
            child: TextButton(
              onPressed: widget.onDone,
              child: const Text("Skip", style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}