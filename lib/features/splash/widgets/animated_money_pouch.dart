import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Custom Animated Money Pouch Widget
/// Renders the Thaili money pouch with:
///  - Entrance scale animation
///  - Neck loosening / opening animation
///  - Ambient glow
/// (The coin is animated separately in SplashScreen)
class AnimatedMoneyPouch extends StatelessWidget {
  final double pouchScale;
  final double pouchOpenProgress; // 0.0 (closed) → 1.0 (open)
  final double glowProgress;

  const AnimatedMoneyPouch({
    super.key,
    required this.pouchScale,
    required this.pouchOpenProgress,
    required this.glowProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: pouchScale,
      child: SizedBox(
        width: 154,
        height: 154,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Ambient subtle glow halo behind pouch (soft & imperceptible)
            Positioned(
              top: 24,
              child: Opacity(
                opacity: (glowProgress * 0.40).clamp(0.0, 1.0),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryLight.withValues(alpha: 0.14),
                        blurRadius: 36,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.08),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Money Pouch (custom painted)
            CustomPaint(
              size: const Size(120, 130),
              painter: _MoneyPouchPainter(openProgress: pouchOpenProgress),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Thaili Money Pouch Icon — always visible at any size.
/// The painter is designed for a 120×130 canvas, so we render at that native
/// size and let FittedBox scale it down to the requested [size].
class ThailiPouchIcon extends StatelessWidget {
  final double size;
  final double openProgress;

  const ThailiPouchIcon({
    super.key,
    this.size = 24,
    this.openProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 120,
          height: 130,
          child: CustomPaint(
            size: const Size(120, 130),
            painter: _MoneyPouchPainter(openProgress: openProgress),
          ),
        ),
      ),
    );
  }
}

/// Thaili Pouch that periodically spits a tiny golden coin out from its mouth.
/// Drop this in wherever a ThailiPouchIcon is used for a playful micro-animation.
class SpittingPouchIcon extends StatefulWidget {
  /// The display size of the pouch (width & height).
  final double size;
  /// How often the spit animation fires (default: every 4 seconds).
  final Duration interval;

  const SpittingPouchIcon({
    super.key,
    this.size = 40,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<SpittingPouchIcon> createState() => _SpittingPouchIconState();
}

class _SpittingPouchIconState extends State<SpittingPouchIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim;   // coin moves upward
  late Animation<double> _opacityAnim; // fade in then out
  late Animation<double> _xAnim;   // slight side arc

  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _yAnim = Tween<double>(begin: 0, end: -widget.size * 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _xAnim = Tween<double>(begin: 0, end: widget.size * 0.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 45),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _animating = false);
      }
    });

    // Start the repeating timer
    _scheduleSpit();
  }

  void _scheduleSpit() {
    Future.delayed(widget.interval, () {
      if (!mounted) return;
      setState(() => _animating = true);
      _ctrl.forward(from: 0.0).then((_) {
        if (!mounted) return;
        _scheduleSpit();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Coin size is 28% of the pouch size
    final coinSize = widget.size * 0.28;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // The static pouch
        ThailiPouchIcon(size: widget.size),

        // Spit coin particle
        if (_animating)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Positioned(
                // Start near the top-center of the pouch (the mouth)
                top: widget.size * 0.10 + _yAnim.value,
                left: widget.size * 0.5 - coinSize / 2 + _xAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value.clamp(0.0, 1.0),
                  child: Container(
                    width: coinSize,
                    height: coinSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.goldLight,
                          AppTheme.accentGold,
                          AppTheme.accentOrange,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withValues(alpha: 0.55),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: coinSize * 0.55,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _MoneyPouchPainter extends CustomPainter {
  final double openProgress;

  _MoneyPouchPainter({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final neckSpread = 10.0 * openProgress;
    final topY = 32.0 - (4.0 * openProgress);

    // 1. Main Pouch Sack Path
    final pouchPath = Path();
    pouchPath.moveTo(w * 0.32 - neckSpread, topY);
    pouchPath.quadraticBezierTo(
        w * 0.28 - neckSpread, topY - 10, w * 0.36 - (neckSpread * 0.5), topY - 4);
    pouchPath.quadraticBezierTo(w * 0.42, topY + 12, w * 0.35, topY + 24);
    pouchPath.cubicTo(
      w * 0.05, h * 0.50,
      w * 0.10, h * 0.95,
      w * 0.50, h * 0.96,
    );
    pouchPath.cubicTo(
      w * 0.90, h * 0.95,
      w * 0.95, h * 0.50,
      w * 0.65, topY + 24,
    );
    pouchPath.quadraticBezierTo(
        w * 0.58, topY + 12, w * 0.64 + (neckSpread * 0.5), topY - 4);
    pouchPath.quadraticBezierTo(
        w * 0.72 + neckSpread, topY - 10, w * 0.68 + neckSpread, topY);
    pouchPath.close();

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(pouchPath.shift(const Offset(0, 10)), shadowPaint);

    // Pouch body fill — lush teal gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF14B8A6),
          Color(0xFF0D9488),
          Color(0xFF0F766E),
          Color(0xFF115E59),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(pouchPath, bodyPaint);

    // Belly highlight
    final highlightPath = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..cubicTo(w * 0.20, h * 0.70, w * 0.30, h * 0.88, w * 0.45, h * 0.90)
      ..cubicTo(w * 0.33, h * 0.84, w * 0.28, h * 0.68, w * 0.25, h * 0.55);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(highlightPath, highlightPaint);

    // 2. Golden drawstring ribbon
    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(0, topY + 14, w, 12))
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ribbonPath = Path();
    ribbonPath.moveTo(w * 0.36 - (neckSpread * 0.3), topY + 18);
    ribbonPath.quadraticBezierTo(
        w * 0.50, topY + 22 + (openProgress * 2), w * 0.64 + (neckSpread * 0.3), topY + 18);
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Knot
    final knotPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, topY + 20), 4.5, knotPaint);

    // Tassel strings
    final tasselPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, topY + 20),
        Offset(w * 0.44 - (openProgress * 3), topY + 36), tasselPaint);
    canvas.drawLine(Offset(w * 0.50, topY + 20),
        Offset(w * 0.56 + (openProgress * 3), topY + 38), tasselPaint);

    // Bead ends
    canvas.drawCircle(
        Offset(w * 0.44 - (openProgress * 3), topY + 37), 3, knotPaint);
    canvas.drawCircle(
        Offset(w * 0.56 + (openProgress * 3), topY + 39), 3, knotPaint);
  }

  @override
  bool shouldRepaint(covariant _MoneyPouchPainter oldDelegate) =>
      oldDelegate.openProgress != openProgress;
}
