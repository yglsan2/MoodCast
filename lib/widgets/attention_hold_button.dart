import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/attention_mode_service.dart';
import '../theme/app_colors.dart';

/// Gros bouton « Diwall » : maintenir N s = OK ; relâcher avant = alerte.
class AttentionHoldButton extends StatefulWidget {
  const AttentionHoldButton({
    super.key,
    required this.onAlertTriggered,
    required this.onSafeCancel,
    this.holdSeconds = 3,
    this.size = 220,
    this.discrete = false,
  });

  final Future<void> Function() onAlertTriggered;
  final VoidCallback onSafeCancel;
  final int holdSeconds;
  final double size;
  final bool discrete;

  @override
  State<AttentionHoldButton> createState() => _AttentionHoldButtonState();
}

class _AttentionHoldButtonState extends State<AttentionHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _progress;
  bool _holding = false;
  bool _completedSafe = false;
  bool _busy = false;

  int get _secs => widget.holdSeconds.clamp(2, 10);

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secs),
    )..addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _holding) {
      _onHoldCompletedSafe();
    }
  }

  @override
  void didUpdateWidget(covariant AttentionHoldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdSeconds != widget.holdSeconds) {
      final value = _progress.value;
      _progress.duration = Duration(seconds: _secs);
      if (!_holding) {
        _progress.value = value;
      }
    }
  }

  @override
  void dispose() {
    _progress.removeStatusListener(_onStatus);
    _progress.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_busy) return;
    try {
      setState(() {
        _holding = true;
        _completedSafe = false;
      });
      try {
        AttentionModeService.beginHolding();
      } catch (_) {}
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
      _progress.duration = Duration(seconds: _secs);
      _progress.forward(from: 0);
    } catch (_) {
      _holding = false;
    }
  }

  Future<void> _onPointerUp(PointerUpEvent _) async {
    await _finishHold(releasedEarly: true);
  }

  Future<void> _onPointerCancel(PointerCancelEvent _) async {
    await _finishHold(releasedEarly: true);
  }

  void _onHoldCompletedSafe() {
    if (!_holding || _busy) return;
    setState(() {
      _holding = false;
      _completedSafe = true;
    });
    HapticFeedback.heavyImpact();
    AttentionModeService.markHoldSafeCancelled();
    widget.onSafeCancel();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _progress.value = 0;
        setState(() => _completedSafe = false);
      }
    });
  }

  Future<void> _finishHold({required bool releasedEarly}) async {
    if (!_holding || _busy) return;
    final progress = _progress.value;
    _holding = false;

    if (!releasedEarly || progress >= 0.98 || _completedSafe) {
      setState(() {});
      return;
    }

    _progress.stop();
    setState(() => _busy = true);
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
    try {
      await widget.onAlertTriggered();
    } catch (_) {
      // L’appelant gère l’UI ; on ne laisse pas le bouton bloqué.
    } finally {
      if (mounted) {
        try {
          _progress.value = 0;
          setState(() => _busy = false);
        } catch (_) {
          _busy = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.discrete ? const Color(0xFF5A5558) : AppColors.error;
    final label = _busy
        ? 'Envoi…'
        : _completedSafe
            ? 'Tout va bien'
            : _holding
                ? 'Maintenir…'
                : 'DIWALL';

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final left = (_secs - _progress.value * _secs).ceil().clamp(0, _secs);
            return CustomPaint(
              painter: _RingPainter(
                progress: _progress.value,
                color: accent,
                safe: _completedSafe,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: widget.size * 0.72,
                  height: widget.size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _completedSafe
                        ? AppColors.success
                        : accent.withValues(alpha: _holding ? 0.95 : 0.88),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: _holding ? 28 : 16,
                        spreadRadius: _holding ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _completedSafe ? Icons.check_rounded : Icons.shield_rounded,
                        color: Colors.white,
                        size: widget.size * 0.16,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: widget.size * 0.07,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (_holding && !_completedSafe)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$left s',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: widget.size * 0.055,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.safe,
  });

  final double progress;
  final Color color;
  final bool safe;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = safe ? AppColors.success : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.safe != safe;
}
