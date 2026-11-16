import 'package:flutter/material.dart';

/// Shrinks its child slightly while pressed, like a pin being pushed in.
/// Uses a Listener, so it never competes with taps or scrolling.
class PressScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const PressScale({super.key, required this.child, this.scale = 0.96});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      onPointerMove: (e) {
        if (e.delta.distance > 4) _set(false); // scrolling, not pressing
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 180),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
