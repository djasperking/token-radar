import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/home_sections.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();
  double _offset = 0;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _offset = _scroll.offset));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // The compact search bar fades in once the big header has scrolled away.
    final compact = ((_offset - 180) / 60).clamp(0.0, 1.0);

    var i = 0;
    Widget stagger(Widget child) => FadeSlideIn(
          delay: Duration(milliseconds: 80 * i++),
          child: child,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            controller: _scroll,
            padding: EdgeInsets.zero,
            children: [
              DeliveryHeader(topPadding: top),
              Transform.translate(
                offset: const Offset(0, -26),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TrackingSearchField(hint: 'Enter tracking number'),
                ),
              ),
              stagger(const ServicesSection()),
              const SizedBox(height: 24),
              stagger(const ActiveShipmentsSection()),
              const SizedBox(height: 24),
              stagger(const ThisWeekSection()),
              const SizedBox(height: 24),
              stagger(const RecentUpdatesSection()),
              const SizedBox(height: 24),
              stagger(const NearbyDropOffSection()),
              const SizedBox(height: 130),
            ],
          ),
          // Compact top bar shown after scrolling.
          IgnorePointer(
            ignoring: compact < 0.5,
            child: Opacity(
              opacity: compact,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.orangeSoft, Color(0x00FBA65D)],
                    stops: [0.75, 1],
                  ),
                ),
                child: const Row(
                  children: [
                    Avatar(size: 40),
                    SizedBox(width: 10),
                    Expanded(
                        child: TrackingSearchField(hint: 'Try "AB-889641"')),
                    SizedBox(width: 10),
                    BellButton(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 10,
            child: Center(
              child: GlassNavBar(
                index: _tab,
                onTap: (v) => setState(() => _tab = v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted, floating "liquid glass" style tab bar.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.receipt_long_outlined, 'Orders'),
    (Icons.account_balance_wallet_outlined, 'Wallet'),
    (Icons.person_outline_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var n = 0; n < _items.length; n++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: n == index
                          ? AppColors.orange.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _items[n].$1,
                          size: 22,
                          color: n == index ? AppColors.orange : AppColors.ink,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[n].$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                n == index ? AppColors.orange : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
