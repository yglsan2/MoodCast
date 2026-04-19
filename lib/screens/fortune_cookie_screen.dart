import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import '../services/fortune_cookie_service.dart';
import '../services/storage_service.dart';

/// Écran « biscuit chinois » : 1 biscuit par jour, clic → le biscuit s’anime et se fend en deux, message apparaît.
class FortuneCookieScreen extends StatefulWidget {
  const FortuneCookieScreen({super.key});

  @override
  State<FortuneCookieScreen> createState() => _FortuneCookieScreenState();
}

class _FortuneCookieScreenState extends State<FortuneCookieScreen>
    with TickerProviderStateMixin {
  /// Message déjà ouvert aujourd’hui (depuis le stockage).
  String? _todayMessage;
  /// True si l’utilisateur a déjà ouvert son biscuit aujourd’hui.
  bool _canOpenToday = true;
  /// En cours d’animation de fente.
  bool _isAnimating = false;
  /// Message qui vient d’être tiré (pendant / après animation).
  String? _revealedMessage;

  late AnimationController _splitController;
  late AnimationController _messageController;
  late Animation<double> _splitAnimation;
  late Animation<double> _messageOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _splitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _splitAnimation = CurvedAnimation(
      parent: _splitController,
      curve: Curves.easeOutCubic,
    );
    _messageOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _messageController, curve: Curves.easeOut),
    );
    _loadTodayState();
  }

  Future<void> _loadTodayState() async {
    final alreadyOpened = await StorageService.hasAlreadyOpenedFortuneToday();
    String? message;
    if (alreadyOpened) {
      message = await StorageService.getLastFortuneMessage();
    }
    if (mounted) {
      setState(() {
        _canOpenToday = !alreadyOpened;
        _todayMessage = message;
      });
    }
  }

  @override
  void dispose() {
    _splitController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? get _displayMessage => _revealedMessage ?? _todayMessage;

  void _onCookieTap() {
    if (!_canOpenToday || _isAnimating) return;
    final fortune = FortuneCookieService.drawFortune();
    setState(() {
      _isAnimating = true;
      _revealedMessage = fortune;
    });
    StorageService.saveTodayFortune(fortune);
    _splitController.forward(from: 0).then((_) {
      _messageController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _canOpenToday = false;
            _todayMessage = fortune;
          });
        }
      });
    });
  }

  void _share() {
    final msg = _displayMessage;
    if (msg == null) return;
    Clipboard.setData(ClipboardData(text: '🍪 « $msg » — Biscuit chinois MoodCast'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copié ! Collez-le où vous voulez pour le partager.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🍪 Biscuit chinois',
        gradient: AppColors.gradientAccent,
      ),
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Text(
                  'Un biscuit par jour. Cliquez sur le biscuit : il se fend et révèle votre fortune.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (!_canOpenToday && _todayMessage != null && _revealedMessage == null) ...[
                  _buildCookieOpenedPlaceholder(),
                  const SizedBox(height: 20),
                  _buildFortuneCard(_todayMessage!),
                  const SizedBox(height: 12),
                  Text(
                    'Prochain biscuit demain',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Copier / Partager'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ] else if (_displayMessage != null) ...[
                  _buildCookieSplitAnimation(),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _messageOpacityAnimation,
                    child: _buildFortuneCard(_displayMessage!),
                  ),
                  if (!_canOpenToday)
                    const SizedBox(height: 12),
                  if (!_canOpenToday)
                    Text(
                      'Prochain biscuit demain',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text('Copier / Partager'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildCookieTapTarget(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCookieTapTarget() {
    return GestureDetector(
      onTap: _onCookieTap,
      behavior: HitTestBehavior.opaque,
      child: _CookieSplitWidget(
          splitProgress: 0,
          scale: 1,
          size: 180,
      ),
    );
  }

  Widget _buildCookieSplitAnimation() {
    return AnimatedBuilder(
      animation: _splitAnimation,
      builder: (context, child) {
        final t = _splitAnimation.value;
        final scale = t < 0.12 ? 1 + 0.1 * (t / 0.12) : 1.1 - 0.1 * ((t - 0.12) / 0.88);
        final splitProgress = t < 0.12 ? 0.0 : (t - 0.12) / 0.88;
        return _CookieSplitWidget(
          splitProgress: splitProgress,
          scale: scale,
          size: 180,
        );
      },
    );
  }

  Widget _buildCookieOpenedPlaceholder() {
    return _CookieSplitWidget(splitProgress: 1, scale: 1, size: 130);
  }

  Widget _buildFortuneCard(String message) {
    return FeelGoodCard(
      margin: EdgeInsets.zero,
      gradient: AppColors.gradientAccent,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'Votre fortune',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Biscuit qui se fend en deux : [splitProgress] 0 = fermé, 1 = ouvert ; [scale] pour l’anticipation.
class _CookieSplitWidget extends StatelessWidget {
  const _CookieSplitWidget({
    required this.splitProgress,
    required this.scale,
    required this.size,
  });

  final double splitProgress;
  final double scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: size * 1.5,
        height: size * 1.35,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _CookieHalf(
              side: _HalfSide.left,
              splitProgress: splitProgress,
              size: size,
            ),
            _CookieHalf(
              side: _HalfSide.right,
              splitProgress: splitProgress,
              size: size,
            ),
          ],
        ),
      ),
    );
  }
}

enum _HalfSide { left, right }

class _CookieHalf extends StatelessWidget {
  const _CookieHalf({
    required this.side,
    required this.splitProgress,
    required this.size,
  });

  final _HalfSide side;
  final double splitProgress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final angle = splitProgress * (math.pi / 2.2);
    final rotate = side == _HalfSide.left ? -angle : angle;
    final translate = splitProgress * radius * 0.55;
    final dx = side == _HalfSide.left ? -translate : translate;
    final tilt = splitProgress * 0.08;
    final dy = side == _HalfSide.left ? tilt * size : -tilt * size;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rotate,
        child: CustomPaint(
          size: Size(size, size),
          painter: _HalfCookiePainter(isLeft: side == _HalfSide.left),
        ),
      ),
    );
  }
}

class _HalfCookiePainter extends CustomPainter {
  _HalfCookiePainter({required this.isLeft});

  final bool isLeft;

  static const Color _colorBase = Color(0xFFE8C97A);
  static const Color _colorLight = Color(0xFFF5E6C8);
  static const Color _colorShadow = Color(0xFFC9A962);
  static const Color _colorCrack = Color(0xFFB8954A);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    final path = Path();
    if (isLeft) {
      path.moveTo(center.dx, center.dy);
      path.arcTo(Rect.fromCircle(center: center, radius: r), math.pi / 2, math.pi, false);
    } else {
      path.moveTo(center.dx, center.dy);
      path.arcTo(Rect.fromCircle(center: center, radius: r), -math.pi / 2, math.pi, false);
    }
    path.close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_colorLight, _colorBase, _colorShadow],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.save();
    canvas.translate(3, 5);
    canvas.drawPath(path, Paint()..color = _colorShadow.withValues(alpha: 0.2));
    canvas.restore();

    canvas.drawPath(path, Paint()..shader = gradient);

    canvas.drawPath(
      path,
      Paint()
        ..color = _colorShadow.withValues(alpha: 0.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    final crackPath = Path();
    crackPath.moveTo(center.dx - (isLeft ? 0 : r * 0.25), center.dy);
    crackPath.lineTo(center.dx + (isLeft ? r * 0.25 : 0), center.dy);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = _colorCrack
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
