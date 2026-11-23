import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dropoff_map.dart';

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF4EC),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text('🧑🏻‍💻', style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

class BellButton extends StatelessWidget {
  const BellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 21, color: AppColors.ink),
          Positioned(
            top: 10,
            right: 11,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingSearchField extends StatelessWidget {
  const TrackingSearchField({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon:
              const Icon(Icons.search, size: 20, color: AppColors.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: AppColors.orange),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (action != null)
            Row(
              children: [
                Text(action!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600,
                    )),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.orange),
              ],
            ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label,
      {super.key, required this.bg, required this.fg, this.dot});

  final String label;
  final Color bg;
  final Color fg;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class DeliveryHeader extends StatelessWidget {
  const DeliveryHeader({super.key, required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 50),
      decoration: const BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Avatar(),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good afternoon,',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4A3426))),
                  Text('DailyFlutterUI',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
              Spacer(),
              BellButton(),
            ],
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Text('Current Delivery',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4A3426))),
              SizedBox(width: 8),
              Pill('In Transit',
                  bg: AppColors.ink, fg: Colors.white, dot: AppColors.orange),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'AB–889641',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.north_east_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text('21 Oct 2026',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4A3426))),
              Spacer(),
              Text('Est. 26 Oct 2026',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4A3426))),
            ],
          ),
          const SizedBox(height: 10),
          const _ProgressTrack(),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack();

  Widget _done() => Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 13, color: Colors.white),
      );

  Widget _dots() => Expanded(
        child: LayoutBuilder(
          builder: (context, c) {
            final n = (c.maxWidth / 6).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                n,
                (_) => Container(
                  width: 2.5,
                  height: 2.5,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _done(),
        const SizedBox(width: 6),
        _dots(),
        const SizedBox(width: 6),
        _done(),
        const SizedBox(width: 6),
        _dots(),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_shipping_rounded,
              size: 16, color: AppColors.orange),
        ),
        const SizedBox(width: 6),
        _dots(),
        const SizedBox(width: 6),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const _services = [
    ('🚴', 'Ride'),
    ('🚌', 'Transit'),
    ('🚕', 'Car'),
    ('🚚', 'Truck'),
    ('📦', 'Send'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Services'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final s in _services)
                Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(s.$1, style: const TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(height: 8),
                    Text(s.$2,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active shipments
// ---------------------------------------------------------------------------

class _Shipment {
  const _Shipment(this.flags, this.from, this.to, this.order, this.delivered);
  final (String, String) flags;
  final String from;
  final String to;
  final String order;
  final bool delivered;
}

class ActiveShipmentsSection extends StatelessWidget {
  const ActiveShipmentsSection({super.key});

  static const _items = [
    _Shipment(('🇩🇪', '🇫🇷'), 'Berlin', 'Paris', 'Order DE-586340', false),
    _Shipment(('🇮🇹', '🇨🇭'), 'Milan', 'Zurich', 'Order IT-229481', true),
    _Shipment(('🇳🇱', '🇬🇧'), 'Amsterdam', 'London', 'Order NL-771902', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Active Shipments', action: 'View all'),
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ShipmentCard(_items[i]),
          ),
        ),
      ],
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard(this.s);

  final _Shipment s;

  Widget _flag(String f) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(f, style: const TextStyle(fontSize: 18)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 28,
                child: Stack(
                  children: [
                    _flag(s.flags.$1),
                    Positioned(left: 20, child: _flag(s.flags.$2)),
                  ],
                ),
              ),
              const Spacer(),
              s.delivered
                  ? const Pill('Delivered',
                      bg: AppColors.greenSoft, fg: AppColors.green)
                  : const Pill('In Transit',
                      bg: AppColors.peach, fg: AppColors.orange),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(s.from,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.orange),
              ),
              Flexible(
                child: Text(s.to,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(s.order,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// This week
// ---------------------------------------------------------------------------

class ThisWeekSection extends StatelessWidget {
  const ThisWeekSection({super.key});

  static const _bars = [3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 0.3];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('This Week'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _parcelsCard()),
                const SizedBox(width: 12),
                const Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bolt_rounded,
                          iconColor: AppColors.orange,
                          value: '98%',
                          label: 'On time',
                          sub: '2.4 days avg',
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.ink,
                          value: '\$186.40',
                          label: 'Spent',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _parcelsCard() {
    const maxV = 7.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.peachLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    size: 15, color: AppColors.orange),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parcels sent',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('19 – 25 Oct',
                      style: TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Text('32',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              Spacer(),
              Pill('↗ +18%', bg: Colors.white, fg: AppColors.ink),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 0; d < _bars.length; d++)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d == 5)
                        const Text('7',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _bars[d] / maxV),
                        duration: Duration(milliseconds: 700 + d * 80),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Container(
                          width: 10,
                          height: 72 * v + 2,
                          decoration: BoxDecoration(
                            color: d == 5
                                ? AppColors.orange
                                : AppColors.orangeSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_days[d],
                          style: TextStyle(
                            fontSize: 10,
                            color: d == 5 ? AppColors.ink : AppColors.muted,
                            fontWeight:
                                d == 5 ? FontWeight.w700 : FontWeight.w400,
                          )),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.6)),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              if (sub != null)
                Text(sub!,
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent updates
// ---------------------------------------------------------------------------

class RecentUpdatesSection extends StatelessWidget {
  const RecentUpdatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('Recent Updates'),
        _UpdateRow(
          time: '10:24',
          icon: Icons.local_shipping_outlined,
          title: 'Out for delivery',
          sub: 'AB-889641 · 3 stops away',
          color: AppColors.orange,
          active: true,
        ),
        _UpdateRow(
          time: '08:10',
          icon: Icons.warehouse_outlined,
          title: 'Arrived at sorting hub',
          sub: 'DE-586340 · Paris Nord hub',
          color: AppColors.ink,
        ),
        _UpdateRow(
          time: 'Yesterday',
          icon: Icons.check_circle_outline_rounded,
          title: 'Delivered',
          sub: 'IT-229481 · Signed by Lucas',
          color: AppColors.green,
          last: true,
        ),
      ],
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.time,
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    this.active = false,
    this.last = false,
  });

  final String time;
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 58,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(time,
                    style: TextStyle(
                      fontSize: time.length > 5 ? 10 : 12,
                      color: active ? AppColors.ink : AppColors.muted,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ),
            SizedBox(
              width: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    bottom: last ? null : 0,
                    height: last ? 40 : null,
                    child: Container(width: 1.4, color: AppColors.border),
                  ),
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: active ? color : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? AppColors.orangeSoft : AppColors.border,
                    width: active ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(sub,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nearby drop-off
// ---------------------------------------------------------------------------

class NearbyDropOffSection extends StatelessWidget {
  const NearbyDropOffSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Nearby Drop-off', action: 'Map'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(8),
            child: const Column(
              children: [
                DropOffMap(),
                SizedBox(height: 8),
                _DropOffTile(
                  n: 1,
                  name: 'Central Mall Point',
                  address: 'Lot G-12, Ground floor',
                  status: 'Open · Until 22:00',
                  open: true,
                  distance: '0.8 km',
                ),
                _DropOffTile(
                  n: 2,
                  name: 'Metro Station Locker',
                  address: 'Self-service, exit B',
                  status: 'Open · 24 hours',
                  open: true,
                  distance: '1.4 km',
                ),
                _DropOffTile(
                  n: 3,
                  name: 'Riverside Hub',
                  address: 'Unit 3, Riverside Park',
                  status: 'Closed · Opens 08:00',
                  open: false,
                  distance: '2.6 km',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropOffTile extends StatelessWidget {
  const _DropOffTile({
    required this.n,
    required this.name,
    required this.address,
    required this.status,
    required this.open,
    required this.distance,
  });

  final int n;
  final String name;
  final String address;
  final String status;
  final bool open;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: open ? AppColors.ink : AppColors.muted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$n',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(address,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: open ? AppColors.green : AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(status,
                        style: TextStyle(
                          fontSize: 11,
                          color: open ? AppColors.green : AppColors.muted,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ],
            ),
          ),
          Text(distance,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}
