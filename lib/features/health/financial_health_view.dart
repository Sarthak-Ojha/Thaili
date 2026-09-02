import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class FinancialHealthView extends StatefulWidget {
  final String currSymbol;

  const FinancialHealthView({
    super.key,
    required this.currSymbol,
  });

  @override
  State<FinancialHealthView> createState() => _FinancialHealthViewState();
}

class _FinancialHealthViewState extends State<FinancialHealthView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gaugeAnimation;
  late Animation<int> _scoreAnimation;

  // We store the last score so we only re-animate if score changes
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _gaugeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scoreAnimation = IntTween(begin: 0, end: 0).animate(_gaugeAnimation);
  }

  void _animateTo(int targetScore) {
    if (targetScore == _lastScore) return;
    _lastScore = targetScore;

    _scoreAnimation =
        IntTween(begin: 0, end: targetScore).animate(_gaugeAnimation);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final txs = appState.transactions;
        final budgets = appState.budgets;
        final goals = appState.goals;

        // ── Offline-first score calculation ──────────────────────────────
        final hasData =
            txs.isNotEmpty || budgets.isNotEmpty || goals.isNotEmpty;
        final spendingScore = txs.isEmpty
            ? 80
            : (appState.initialBalance >= 0 ? 88 : 60);
        final savingScore = goals.isEmpty
            ? 70
            : (goals.any((g) => g.percent > 40) ? 85 : 75);
        final budgetScore = budgets.isEmpty
            ? 75
            : (budgets.every((b) => b.spent <= b.limit) ? 90 : 65);
        const consistencyScore = 80;
        final overallScore = hasData
            ? ((spendingScore + savingScore + budgetScore + consistencyScore) /
                    4)
                .toInt()
            : 75;

        // Trigger gauge animation whenever score changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateTo(overallScore);
        });

        final suggestions = <Map<String, dynamic>>[];
        if (txs.isEmpty && budgets.isEmpty) {
          suggestions.add({
            'color': const Color(0xFF38BDF8),
            'text': 'Log expenses to get real-time health grading.',
          });
        } else {
          if (spendingScore >= 80) {
            suggestions.add({
              'color': const Color(0xFF34D399),
              'text': "You're spending within balanced limits.",
            });
          }
          if (budgets.any((b) => b.limit > 0 && b.spent > b.limit)) {
            suggestions.add({
              'color': const Color(0xFFF59E0B),
              'text': 'One or more categories exceeded budget.',
            });
          }
          if (goals.isNotEmpty) {
            suggestions.add({
              'color': const Color(0xFF38BDF8),
              'text': 'Active progress on your savings targets.',
            });
          }
        }

        return SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Financial Health',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Your personalized wellness score & breakdown',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
              const SizedBox(height: 20),

              // ── Hero Score Card with Arc Gauge ─────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── Arc Gauge centered ────────────────────────────────
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 160,
                          child: CustomPaint(
                            painter: ArcGaugePainter(
                              progress: _gaugeAnimation.value,
                              score: _scoreAnimation.value,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // ── Status Badge ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        overallScore >= 75 ? '✨ Good Health' : '⚠️ Needs Attention',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Offline-first badge ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Calculated locally · Offline-first',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ── Breakdown Grid ─────────────────────────────────────────
              Text(
                'Breakdown',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Spending',
                      spendingScore,
                      const Color(0xFF34D399),
                      cardBg,
                      outlineColor,
                      textColor,
                      subTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Saving',
                      savingScore,
                      const Color(0xFF38BDF8),
                      cardBg,
                      outlineColor,
                      textColor,
                      subTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Budgeting',
                      budgetScore,
                      AppTheme.accentGold,
                      cardBg,
                      outlineColor,
                      textColor,
                      subTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Consistency',
                      consistencyScore,
                      const Color(0xFFA855F7),
                      cardBg,
                      outlineColor,
                      textColor,
                      subTextColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ── Suggestions Section ────────────────────────────────────
              Text(
                'Suggestions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 12),

              if (suggestions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add transactions and budgets to unlock personalised suggestions.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildSuggestionTile(
                      dotColor: s['color'] as Color,
                      text: s['text'] as String,
                      cardBg: cardBg,
                      outlineColor: outlineColor,
                      textColor: textColor,
                    ),
                  ),
                ),

              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    int score,
    Color color,
    Color cardBg,
    Color outlineColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: subTextColor),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor),
              ),
              const SizedBox(width: 2),
              Text(
                ' / 100',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: outlineColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 100,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required Color dotColor,
    required String text,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ArcGaugePainter — 180° semi-circular gauge, red → amber → teal
// ══════════════════════════════════════════════════════════════════════════════
class ArcGaugePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (animation value)
  final int score;       // integer displayed at center

  const ArcGaugePainter({required this.progress, required this.score});

  // Interpolate between three colors based on a [0..1] value
  Color _gaugeColor(double t) {
    const red = Color(0xFFEF4444);
    const amber = Color(0xFFF59E0B);
    const teal = Color(0xFF14B8A6);

    if (t <= 0.5) {
      return Color.lerp(red, amber, t * 2)!;
    } else {
      return Color.lerp(amber, teal, (t - 0.5) * 2)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88; // push arc toward bottom
    final radius = size.width * 0.40;
    final strokeWidth = 14.0;

    // ── Track (background arc) ────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi,       // start at 9 o'clock (left)
      math.pi,       // sweep 180°
      false,
      trackPaint,
    );

    // ── Tick marks ────────────────────────────────────────────────────────
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 4; i++) {
      final angle = math.pi + (i / 4) * math.pi;
      final innerR = radius - strokeWidth * 0.9;
      final outerR = radius + strokeWidth * 0.9;
      final cos = math.cos(angle);
      final sin = math.sin(angle);
      canvas.drawLine(
        Offset(cx + cos * innerR, cy + sin * innerR),
        Offset(cx + cos * outerR, cy + sin * outerR),
        tickPaint,
      );
    }

    // ── Foreground arc (animated) ─────────────────────────────────────────
    final sweepFraction = progress; // 0→1
    final arcColor = _gaugeColor(sweepFraction);

    final fgPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: math.pi,
        endAngle: math.pi + math.pi * sweepFraction.clamp(0.01, 1.0),
        colors: [
          const Color(0xFFEF4444),
          _gaugeColor(sweepFraction * 0.5),
          arcColor,
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      math.pi,
      math.pi * sweepFraction.clamp(0.001, 1.0),
      false,
      fgPaint,
    );

    // ── Glowing end-cap circle ─────────────────────────────────────────────
    if (sweepFraction > 0.02) {
      final endAngle = math.pi + math.pi * sweepFraction;
      final dotX = cx + math.cos(endAngle) * radius;
      final dotY = cy + math.sin(endAngle) * radius;

      // Glow
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth * 0.85,
        Paint()
          ..color = arcColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Core dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth * 0.45,
        Paint()..color = Colors.white,
      );
    }

    // ── Score text ────────────────────────────────────────────────────────
    final scoreTp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(
      canvas,
      Offset(cx - scoreTp.width / 2, cy - scoreTp.height - 6),
    );

    // ── "/100" sub-label ──────────────────────────────────────────────────
    final subTp = TextPainter(
      text: const TextSpan(
        text: '/ 100',
        style: TextStyle(
          color: Colors.white60,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subTp.paint(
      canvas,
      Offset(cx - subTp.width / 2, cy - scoreTp.height + subTp.height - 4),
    );

    // ── Min / Max labels ──────────────────────────────────────────────────
    _drawLabel(canvas, '0', Offset(cx - radius - 6, cy + 4),
        Colors.white38, 11);
    _drawLabel(canvas, '100', Offset(cx + radius - 14, cy + 4),
        Colors.white38, 11);
  }

  void _drawLabel(
      Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(ArcGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.score != score;
}
