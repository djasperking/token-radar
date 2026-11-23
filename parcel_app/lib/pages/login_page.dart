import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/parcel_logo.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _keepSignedIn = true;
  bool _obscure = true;
  bool _signingIn = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _signingIn = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(topPadding: top),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                    child: _form(),
                  ),
                ),
              ],
            ),
          ),
          if (_signingIn) const _SigningInOverlay(),
        ],
      ),
    );
  }

  Widget _form() {
    var i = 0;
    Duration d() => Duration(milliseconds: 120 + 70 * i++);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: d(),
          child: const Text(
            'Welcome Back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: d(),
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Email or Phone',
              prefixIcon: Icon(Icons.mail_outline_rounded,
                  size: 20, color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: d(),
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            onSubmitted: (_) => _logIn(),
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 20, color: AppColors.muted),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: d(),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _keepSignedIn = !_keepSignedIn),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _keepSignedIn
                            ? AppColors.orange
                            : Colors.transparent,
                        border: Border.all(
                          color: _keepSignedIn
                              ? AppColors.orange
                              : AppColors.border,
                          width: 1.6,
                        ),
                      ),
                      child: _keepSignedIn
                          ? const Icon(Icons.check,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Keep me signed in',
                        style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: d(),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _logIn,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                'Log In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: d(),
          child: const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Or Continue With',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: d(),
          child: const Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  icon: Text('G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4285F4),
                      )),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  label: 'Apple',
                  icon: Icon(Icons.apple, size: 22, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: d(),
          child: const Text.rich(
            TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(fontSize: 13, color: AppColors.muted),
              children: [
                TextSpan(
                  text: 'Sign Up',
                  style: TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: d(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quick Track as Guest',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.orange),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270 + topPadding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE3CF), Color(0xFFFFF1E6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: 10,
            child: FadeSlideIn(
              offset: 40,
              duration: const Duration(milliseconds: 800),
              child: _Courier(),
            ),
          ),
          Positioned(
            left: 20,
            top: topPadding + 18,
            child: const ParcelLogo(size: 19),
          ),
        ],
      ),
    );
  }
}

/// A flat courier illustration: cap, face, uniform and a parcel in hand.
class _Courier extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Torso.
          Positioned(
            left: 60,
            top: 120,
            child: Container(
              width: 150,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFE0453A),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          // Head.
          Positioned(
            left: 92,
            top: 40,
            child: Container(
              width: 84,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFF6C7A1),
                borderRadius: BorderRadius.circular(42),
              ),
              child: const Align(
                alignment: Alignment(0, 0.35),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Eye(),
                    SizedBox(width: 18),
                    _Eye(),
                  ],
                ),
              ),
            ),
          ),
          // Cap.
          Positioned(
            left: 86,
            top: 26,
            child: Container(
              width: 96,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFD63A30),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(48),
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            left: 66,
            top: 58,
            child: Container(
              width: 50,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFB92E25),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Parcels.
          Positioned(
            left: 0,
            top: 120,
            child: Transform.rotate(
              angle: -0.08,
              child: const _Box(width: 112, height: 70),
            ),
          ),
          Positioned(
            left: 16,
            top: 84,
            child: Transform.rotate(
              angle: 0.06,
              child: const _Box(width: 80, height: 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 9,
        decoration: BoxDecoration(
          color: const Color(0xFF3A2A22),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9B577), Color(0xFFC98D4C)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.18,
          color: const Color(0xFFF3D2A6),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});

  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

/// Frosted overlay with a delivery truck and a ticking clock.
class _SigningInOverlay extends StatefulWidget {
  const _SigningInOverlay();

  @override
  State<_SigningInOverlay> createState() => _SigningInOverlayState();
}

class _SigningInOverlayState extends State<_SigningInOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, v, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14 * v, sigmaY: 14 * v),
          child: Container(
            color: Colors.white.withValues(alpha: 0.55 * v),
            child: Opacity(opacity: v, child: child),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => SizedBox(
                  width: 140,
                  height: 110,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 20,
                        bottom: 0,
                        child: Transform.translate(
                          offset: Offset(
                              0, (_c.value < 0.5 ? _c.value : 1 - _c.value) * 4),
                          child: const Icon(Icons.local_shipping_rounded,
                              size: 110, color: Color(0xFFE2463B)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: _Clock(turn: _c.value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Signing you in...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({required this.turn});

  final double turn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2463B), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: turn * 6.2832,
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
