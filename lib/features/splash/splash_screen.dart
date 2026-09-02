import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../onboarding/currency_region_screen.dart';
import 'widgets/animated_money_pouch.dart';

/// Step 0: Splash Screen
/// Animation sequence:
///  1. Money pouch scales in with bounce         (0.00 → 0.38)
///  2. Ambient glow fades in                     (0.18 → 0.60)
///  3. Pouch neck loosens / opens                (0.28 → 0.55)
///  4. Gold coin arcs in from TOP-LEFT, flipping (0.20 → 0.72)
///     • Front face: रू symbol
///     • Back face:  Piggy-bank icon
///  5. THAILI wordmark + tagline fade & slide in (0.55 → 0.90)
///
/// Navigates to Onboarding (first launch) or Home (returning user).
class SplashScreen extends StatefulWidget {
  final bool isReturningUser;

  const SplashScreen({
    super.key,
    this.isReturningUser = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _CoinAnimationModel {
  final Animation<Alignment> align;
  final Animation<double> flip;
  final Animation<double> opacity;
  final Animation<double> scale;
  final double baseSize;
  final String symbol;
  final IconData? backIcon;

  _CoinAnimationModel({
    required this.align,
    required this.flip,
    required this.opacity,
    required this.scale,
    required this.baseSize,
    required this.symbol,
    this.backIcon,
  });
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Pouch
  late Animation<double> _pouchScaleAnimation;
  late Animation<double> _pouchOpenAnimation;
  late Animation<double> _glowAnimation;

  // Multiple small coins pouring into Thaili pouch
  final List<_CoinAnimationModel> _coins = [];

  // Text
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  // Button visibility (shown after animation finishes)
  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // Slower, graceful overall duration: 3200ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // ── Pouch entrance (0.00 → 0.28) ───────────────────────────────────
    _pouchScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.linear),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
      ),
    );

    _pouchOpenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // ── 12 Small Coins Cascading INTO the Thaili Pouch ─────────────────
    final coinConfigs = [
      // 1. Top-Left high arc
      (const Alignment(-1.10, -0.75), const Alignment(0.0, -0.18), 0.20, 0.54, 22.0, 'रू', Icons.savings_rounded, 5.0),
      // 2. Top-Right high arc
      (const Alignment(1.10, -0.70), const Alignment(0.02, -0.18), 0.22, 0.56, 24.0, 'रू', Icons.auto_awesome_rounded, -4.5),
      // 3. Upper-Left descent
      (const Alignment(-0.80, -0.95), const Alignment(-0.01, -0.18), 0.25, 0.59, 19.0, '₹', Icons.star_rounded, 4.0),
      // 4. Upper-Right descent
      (const Alignment(0.75, -0.92), const Alignment(0.01, -0.18), 0.28, 0.62, 21.0, 'रू', Icons.savings_rounded, -3.5),
      // 5. Far Mid-Left stream
      (const Alignment(-1.15, -0.35), const Alignment(-0.02, -0.18), 0.31, 0.65, 18.0, '₹', Icons.monetization_on_rounded, 4.5),
      // 6. Far Mid-Right stream
      (const Alignment(1.15, -0.32), const Alignment(0.02, -0.18), 0.34, 0.68, 20.0, 'रू', Icons.auto_awesome_rounded, -4.0),
      // 7. Directly above pouch (high drop)
      (const Alignment(-0.35, -1.08), const Alignment(0.0, -0.18), 0.37, 0.71, 23.0, 'रू', Icons.star_rounded, 3.5),
      // 8. Directly above right
      (const Alignment(0.35, -1.05), const Alignment(0.01, -0.18), 0.40, 0.74, 20.0, '₹', Icons.savings_rounded, -3.0),
      // 9. Diagonal Left swoop
      (const Alignment(-0.95, -0.55), const Alignment(-0.01, -0.18), 0.43, 0.77, 18.0, 'रू', Icons.monetization_on_rounded, 4.0),
      // 10. Diagonal Right swoop
      (const Alignment(0.95, -0.50), const Alignment(0.01, -0.18), 0.46, 0.80, 19.0, 'रू', Icons.auto_awesome_rounded, -3.5),
      // 11. Upper-mid cascading coin
      (const Alignment(-0.60, -0.80), const Alignment(0.0, -0.18), 0.49, 0.83, 21.0, '₹', Icons.star_rounded, 3.0),
      // 12. Final shiny coin pouring in
      (const Alignment(0.60, -0.78), const Alignment(-0.01, -0.18), 0.52, 0.86, 22.0, 'रू', Icons.savings_rounded, -4.0),
    ];

    for (final cfg in coinConfigs) {
      final startAlign = cfg.$1;
      final endAlign = cfg.$2;
      final startTime = cfg.$3;
      final endTime = cfg.$4;
      final baseSize = cfg.$5;
      final symbol = cfg.$6;
      final backIcon = cfg.$7;
      final flipRounds = cfg.$8;

      final alignAnim = AlignmentTween(begin: startAlign, end: endAlign).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeInOutCubic),
        ),
      );

      final flipAnim = Tween<double>(begin: 0.0, end: flipRounds * pi).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.linear),
        ),
      );

      final opacityAnim = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 18,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: 64,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 18,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, (endTime + 0.04).clamp(0.0, 1.0), curve: Curves.linear),
        ),
      );

      final scaleAnim = Tween<double>(begin: 1.0, end: 0.35).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeInCubic),
        ),
      );

      _coins.add(
        _CoinAnimationModel(
          align: alignAnim,
          flip: flipAnim,
          opacity: opacityAnim,
          scale: scaleAnim,
          baseSize: baseSize,
          symbol: symbol,
          backIcon: backIcon,
        ),
      );
    }

    // ── Text fade & slide ───────────────────────────────────────────────
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.94, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.94, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward().then((_) {
      if (!mounted) return;
      if (widget.isReturningUser) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _navigateToNextScreen();
        });
      } else {
        setState(() => _showButton = true);
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final targetScreen = widget.isReturningUser
        ? const HomeScreen()
        : const CurrencyRegionScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity:
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildGetStartedButton() {
    if (widget.isReturningUser) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _showButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeIn,
      child: AnimatedSlide(
        offset: _showButton ? Offset.zero : const Offset(0, 0.25),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(top: 36.0),
          child: SizedBox(
            width: 230,
            height: 52, // Refined height: 52px for modern, sleek feel
            child: ElevatedButton(
              onPressed: _showButton ? _navigateToNextScreen : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 2,
                shadowColor: AppTheme.primaryLight.withValues(alpha: 0.25),
              ),
              child: const Center(
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Flipping Coin Widget with 3D horizontal rotation simulation
  Widget _buildFlippingCoin({
    required double flipAngle,
    required double opacity,
    required double scale,
    required double baseSize,
    String? symbol,
    IconData? backIcon,
  }) {
    if (opacity <= 0.01) return const SizedBox.shrink();

    final cosVal = cos(flipAngle);
    final isFront = cosVal >= 0;
    final scaleX = (cosVal.abs()).clamp(0.05, 1.0);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Transform(
          transform: Matrix4.diagonal3Values(scaleX, 1.0, 1.0),
          alignment: Alignment.center,
          child: Container(
            width: baseSize,
            height: baseSize,
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
                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFEF3C7),
                width: 1.2,
              ),
            ),
            child: Center(
              child: isFront
                  ? Text(
                      symbol ?? 'रू',
                      style: TextStyle(
                        color: const Color(0xFF78350F),
                        fontWeight: FontWeight.w900,
                        fontSize: baseSize * 0.38,
                        height: 1.0,
                      ),
                    )
                  : Icon(
                      backIcon ?? Icons.savings_rounded,
                      color: const Color(0xFF78350F),
                      size: baseSize * 0.44,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.background : AppTheme.backgroundLight;
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background ambient teal glow (top-left) - subtle & calm ─
          Positioned(
            top: -90,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: isDark ? 0.06 : 0.03),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary
                        .withValues(alpha: isDark ? 0.05 : 0.02),
                    blurRadius: 90,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // ── Gold ambient glow (bottom-right) - subtle & calm ─────────
          Positioned(
            bottom: -70,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    AppTheme.accentGold.withValues(alpha: isDark ? 0.04 : 0.02),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold
                        .withValues(alpha: isDark ? 0.04 : 0.02),
                    blurRadius: 70,
                    spreadRadius: 45,
                  ),
                ],
              ),
            ),
          ),

          // ── Main content: pouch + wordmark ───────────────────────────
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated money pouch
                      AnimatedMoneyPouch(
                        pouchScale: _pouchScaleAnimation.value,
                        pouchOpenProgress: _pouchOpenAnimation.value,
                        glowProgress: _glowAnimation.value,
                      ),

                      const SizedBox(height: 36),

                      // Brand wordmark + tagline
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: Column(
                            children: [
                              // THAILI wordmark
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'THAILI',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6.0,
                                      color: textColor,
                                      shadows: [
                                        Shadow(
                                          color: AppTheme.primaryLight
                                              .withValues(alpha: 0.18),
                                          blurRadius: 18,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Gold dot accent
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accentGold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Tagline
                              Text(
                                'Your money, your way.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.2,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Get Started button (fades in after animation)
                      _buildGetStartedButton(),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── 12 Cascading Small Coins Streaming into Thaili Pouch ────
          ..._coins.map((coin) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Align(
                  alignment: coin.align.value,
                  child: _buildFlippingCoin(
                    flipAngle: coin.flip.value,
                    opacity: coin.opacity.value,
                    scale: coin.scale.value,
                    baseSize: coin.baseSize,
                    symbol: coin.symbol,
                    backIcon: coin.backIcon,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
