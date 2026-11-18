import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A configured native unlock check takes precedence over the logo animation.
/// The journal is built only after startup completes.
class JournalStartup extends StatefulWidget {
  const JournalStartup({super.key, this.unlock, required this.builder});

  final Future<bool> Function()? unlock;
  final WidgetBuilder builder;

  @override
  State<JournalStartup> createState() => _JournalStartupState();
}

class _JournalStartupState extends State<JournalStartup>
    with SingleTickerProviderStateMixin {
  late final _animation =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4700),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) setState(() => _ready = true);
      });

  bool _ready = false;
  bool _checking = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.unlock == null && !_ready) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _ready = true;
        _animation.stop();
      } else if (!_animation.isAnimating) {
        _animation.forward();
      }
    }
  }

  Future<void> _unlock() async {
    setState(() {
      _checking = true;
      _failed = false;
    });
    var unlocked = false;
    try {
      unlocked = await widget.unlock!();
    } catch (_) {
      // An unavailable authentication service must leave the journal gated.
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _ready = unlocked;
      _failed = !unlocked;
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.builder(context);
    final theme = Theme.of(context);
    if (widget.unlock == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: Center(
            child: Semantics(
              image: true,
              label: 'Health Journal',
              child: CustomPaint(
                key: const ValueKey('startup-logo'),
                size: const Size.square(152),
                painter: _StartupMonogram(
                  _animation,
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                Text('Health Journal', style: theme.textTheme.headlineSmall),
                if (_failed)
                  Semantics(
                    liveRegion: true,
                    child: const Text('Could not unlock. Try again.'),
                  ),
                FilledButton(
                  onPressed: _checking ? null : _unlock,
                  child: Text(_checking ? 'Unlocking…' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupMonogram extends CustomPainter {
  _StartupMonogram(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  // The same centerlines and round caps as the Android launcher foreground.
  static final _strokes =
      (Path()
            ..moveTo(72, 69)
            ..lineTo(72, 155)
            ..moveTo(72, 112)
            ..lineTo(131, 112)
            ..moveTo(131, 69)
            ..lineTo(131, 151)
            ..cubicTo(131, 174, 146, 187, 165, 187)
            ..cubicTo(184, 187, 195, 173, 195, 151)
            ..lineTo(195, 69))
          .computeMetrics()
          .toList();
  static final _length = _strokes.fold(
    0.0,
    (total, stroke) => total + stroke.length,
  );
  static const _draw = Interval(.05, .59, curve: Curves.easeInOutCubic);
  static const _fade = Interval(.73, .93, curve: Curves.easeInOut);

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 1 - _fade.transform(animation.value);
    var remaining = _length * _draw.transform(animation.value);
    if (opacity == 0 || remaining == 0) return;

    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (opacity < 1) {
      // Composite the overlapping strokes before applying the logo's opacity.
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    } else {
      canvas.save();
    }
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(math.min(size.width, size.height) / 152);
    canvas.translate(-133.5, -128);
    for (final stroke in _strokes) {
      if (remaining <= 0) break;
      canvas.drawPath(
        stroke.extractPath(0, math.min(stroke.length, remaining)),
        ink,
      );
      remaining -= stroke.length;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StartupMonogram oldDelegate) =>
      color != oldDelegate.color || animation != oldDelegate.animation;
}
