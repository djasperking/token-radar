import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/parcel_logo.dart';
import 'login_page.dart';

/// Top-down courier riding through city streets; the camera pulls back and
/// turns, then the wordmark fades in and the app moves on to login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final camera = Curves.easeInOutCubic.transform((t / 0.7).clamp(0.0, 1.0));
          final text = Curves.easeOut.transform(((t - 0.5) / 0.3).clamp(0.0, 1.0));
          final sceneShift = -60.0 * camera;
          return Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, sceneShift),
                  child: CustomPaint(
                    painter: _StreetsPainter(
                      progress: t,
                      rotation: -0.62 * camera,
                      zoom: 1.35 - 0.4 * camera,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.42),
                child: Opacity(
                  opacity: text,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - text)),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ParcelLogo(size: 34, showIcon: false),
                        SizedBox(height: 10),
                        Text(
                          'Send, track and deliver anything\naround your city — in a few taps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  _StreetsPainter({
    required this.progress,
    required this.rotation,
    required this.zoom,
  });

  final double progress;
  final double rotation;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(zoom);

    // The world scrolls downward so the rider appears to drive forward.
    final travel = progress * 260;

    // Main road the rider is on.
    final road = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00E9E9EC), Color(0xFFE6E6EA), Color(0xFFE6E6EA)],
        stops: [0, 0.35, 1],
      ).createShader(const Rect.fromLTWH(-30, -420, 60, 900));
    canvas.drawRect(const Rect.fromLTWH(-30, -420, 60, 900), road);

    // Thin block outlines around the road.
    final line = Paint()
      ..color = const Color(0xFFD9D9DE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.translate(0, travel % 220);
    for (var i = -3; i <= 3; i++) {
      final y = i * 220.0;
      canvas.drawLine(Offset(-160, y), Offset(-46, y), line);
      canvas.drawLine(Offset(46, y + 60), Offset(170, y + 60), line);
      canvas.drawLine(Offset(-46, y - 80), Offset(-46, y + 40), line);
      canvas.drawLine(Offset(46, y - 20), Offset(46, y + 120), line);
      canvas.drawLine(Offset(-120, y - 60), Offset(-60, y + 20), line);
    }
    canvas.restore();

    // Fade the edges into white.
    final fade = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0), Colors.white],
        stops: const [0.55, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 260));
    canvas.drawCircle(Offset.zero, 600, fade);

    _drawScooter(canvas, progress);
    canvas.restore();
  }

  void _drawScooter(Canvas canvas, double t) {
    final wobble = math.sin(t * math.pi * 6) * 0.04;
    canvas.save();
    canvas.rotate(wobble);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -26, 30, 64), const Radius.circular(12)),
      shadow,
    );

    // Front wheel / fairing.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -34, 10, 16), const Radius.circular(5)),
      Paint()..color = const Color(0xFF2B2B30),
    );
    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-13, -24, 26, 40), const Radius.circular(12)),
      Paint()..color = const Color(0xFFE2343B),
    );
    // Handlebars.
    canvas.drawLine(
      const Offset(-19, -16),
      const Offset(19, -16),
      Paint()
        ..color = const Color(0xFF2B2B30)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Rider helmet.
    canvas.drawCircle(const Offset(0, -6), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(0, -6), 9 * 0.62, Paint()..color = const Color(0xFFC0262D));
    // Delivery box.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, 12, 24, 22), const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, 12, 24, 22), const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFDADADF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StreetsPainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.zoom != zoom;
}
