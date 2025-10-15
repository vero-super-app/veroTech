import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:vero360_app/Accomodation.dart';

import 'package:vero360_app/Pages/Edu.dart';
import 'package:vero360_app/Pages/ExchangeRate.dart';
import 'package:vero360_app/Pages/MobileMoney.dart';
import 'package:vero360_app/Pages/More.dart';
import 'package:vero360_app/Pages/Taxi.dart';
import 'package:vero360_app/Pages/food.dart';
import 'package:vero360_app/Pages/utility.dart';
import 'package:vero360_app/models/Latest_model.dart';
import 'package:vero360_app/services/latest_Services.dart';

class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const brandOrangeSoft = Color(0xFFFFEAD1);
  static const brandOrangePale = Color(0xFFFFF4E6);

  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const chip = Color(0xFFF9F5EF);
  static const card = Color(0xFFFFFFFF);
  static const bgBottom = Color(0xFFFFFFFF);
}

/// ─────────────────────────────────────────────
/// SECTION HEADER GAPS (tweak these numbers)
/// ─────────────────────────────────────────────
const double kGapAfterQuickServices = 6; // <-- adjust gap under "Discover our Quick Services"
const double kGapAfterNearby = 6;        // <-- adjust gap under "Best Places Nearby"

class Vero360Homepage extends StatefulWidget {
  final String email;
  const Vero360Homepage({super.key, required this.email});
  @override
  State<Vero360Homepage> createState() => _Vero360HomepageState();
}

String _firstNameFromEmail(String? e) {
  if (e == null) return 'there';
  final t = e.trim();
  if (t.isEmpty) return 'there';
  final base = t.contains('@') ? t.split('@').first : t;
  return base.isEmpty ? 'there' : (base[0].toUpperCase() + base.substring(1));
}

class _Vero360HomepageState extends State<Vero360Homepage> {
  final _search = TextEditingController();
  int _promoIndex = 0;
  bool _animateIn = false;

  final List<_Promo> _promos = const [
    _Promo(
      title: 'Save 30% OFF',
      subtitle: 'first 2 Orders',
      code: 'Use code FOOD30',
      image: 'assets/happy.jpg',
      bg: Color(0xFFFDF2E9),
      tint: AppColors.brandOrange,
    ),
    _Promo(
      title: 'Free Delivery',
      subtitle: 'all week long',
      code: 'Use code FREEDEL',
      image: 'assets/Queens-Tavern-Steak.jpg',
      bg: Color(0xFFFFF4E6),
      tint: AppColors.brandOrange,
    ),
    _Promo(
      title: 'Vero Ride ',
      subtitle: 'Ride • 15% off',
      code: 'Use code GO15',
      image: 'assets/uber-cabs-1024x576.webp',
      bg: Color(0xFFFFF0E1),
      tint: AppColors.brandOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = 'Hi, ${_firstNameFromEmail(widget.email)} 👋';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFBF6), AppColors.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 79, 16, 0),
                child: Column(
                  children: [
                    const _BrandBar(appName: 'Vero360', logoPath: 'assets/logo_mark.png'),
                    const SizedBox(height: 12),
                    _TopSection(
                      animateIn: _animateIn,
                      greeting: greeting,
                      searchController: _search,
                      onSearchTap: _onSearchTap,
                    ),
                  ],
                ),
              ),
            ),

            // Promos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _PromoCarousel(
                  promos: _promos,
                  onIndex: (i) => setState(() => _promoIndex = i),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _Dots(count: _promos.length, index: _promoIndex)),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // Quick strip
            const SliverToBoxAdapter(child: _QuickStrip()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Services — unified grid
            SliverToBoxAdapter(
              child: _Section(
                title: 'Discover our Quick Services',
                tight: true,
                gapAfterTitle: kGapAfterQuickServices, // <-- tiny adjustable gap here
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _UnifiedServicesGrid(
                    onOpen: (key) => _Vero360HomepageState._openServiceStatic(context, key),
                  ),
                ),
              ),
            ),

            // Near you
            const SliverToBoxAdapter(child: _NearYouCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Deals
            const SliverToBoxAdapter(child: _DealsStrip()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Latest arrivals
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 16, 16),
                child: const LatestArrivalsSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search location tapped')),
    );
  }

  static void _openServiceStatic(BuildContext context, String key) {
    Widget page;
    switch (key) {
      case 'food':
        page = FoodPage();
        break;
      case 'grocery':
        page = FoodPage();
        break;
      case 'courier':
        page = const UtilityPage();
        break;
      case 'taxi':
        page = const TaxiPage();
        break;
      case 'send_money':
        page = const MobilemoneyPage();
        break;
      case 'home_cleaning':
        page = const UtilityPage();
        break;
      case 'Vero Chat':
        page = const EducationPage();
        break;
      case 'hospital':
        page = const UtilityPage();
        break;
      case 'gym':
      case 'barbershop':
      case 'salon':
      case 'Hair Salon':
        page = const MorePage();
        break;
      case 'hostels':
      case 'hotels':
      case 'accommodation':
        page = const AccomodationPage();
        break;
      case 'mobile_money':
        page = const MobilemoneyPage();
        break;
      case 'fx':
        page = const ExchangeRateScreen();
        break;
      default:
        page = const MorePage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/// BRAND BAR
class _BrandBar extends StatelessWidget {
  final String appName;
  final String logoPath;
  const _BrandBar({required this.appName, required this.logoPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.brandOrange, Color(0xFFFFB85C)]),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                logoPath,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco, size: 22, color: AppColors.brandOrange),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('Vero360', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.title)),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: const Icon(Icons.notifications_active_outlined, color: AppColors.title),
        ),
        const SizedBox(width: 4),
        const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.brandOrangePale,
          child: Icon(Icons.person_outline, size: 18, color: AppColors.brandOrange),
        ),
      ],
    );
  }
}

/// TOP SECTION
class _TopSection extends StatelessWidget {
  final bool animateIn;
  final String greeting;
  final TextEditingController searchController;
  final VoidCallback onSearchTap;

  const _TopSection({
    required this.animateIn,
    required this.greeting,
    required this.searchController,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: animateIn ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedSlide(
        offset: animateIn ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.title)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.brandOrangeSoft),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: const [
                          Icon(Icons.search_rounded, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'what are you looking for?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.body, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pay tapped')),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Promo + carousel plumbing
class _Promo {
  final String title, subtitle, code, image;
  final Color bg, tint;
  const _Promo({required this.title, required this.subtitle, required this.code, required this.image, required this.bg, required this.tint});
}

class _PromoCarousel extends StatelessWidget {
  final List<_Promo> promos;
  final ValueChanged<int> onIndex;
  const _PromoCarousel({required this.promos, required this.onIndex});
  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: promos.length,
      options: CarouselOptions(
        height: 160,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.92,
        onPageChanged: (i, _) => onIndex(i),
      ),
      itemBuilder: (_, i, __) {
        final p = promos[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.bg, Colors.white], begin: const Alignment(-0.6, -1), end: const Alignment(1, 1)),
              border: Border.all(color: AppColors.brandOrangeSoft),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
                    child: Image.asset(
                      p.image,
                      width: 180,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 180,
                        color: const Color(0xFFEDEDED),
                        child: const Center(child: Icon(Icons.image_not_supported_rounded)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 180, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: TextStyle(color: p.tint, fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(p.subtitle, style: const TextStyle(color: AppColors.title, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(p.code, style: const TextStyle(color: AppColors.body, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Order now', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  final int count, index;
  const _Dots({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: active ? 18 : 6,
            decoration: BoxDecoration(
              color: active ? AppColors.brandOrange : const Color(0xFFE1E1E1),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}

/// Quick chips strip
class _QuickStrip extends StatelessWidget {
  const _QuickStrip();
  @override
  Widget build(BuildContext context) {
    final items = const [
      ['⚡', 'Lightning deals'],
      ['🗺️', 'Explore nearby'],
      ['⭐', 'Top rated'],
      ['🛟', 'Support'],
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brandOrangeSoft),
          ),
          child: Center(
            child: Text('${items[i][0]}  ${items[i][1]}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.title)),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

/// UNIFIED grid (quick + super-app) — no vertical gaps between rows
class _UnifiedServicesGrid extends StatelessWidget {
  final void Function(String key) onOpen;
  const _UnifiedServicesGrid({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceLite>[
      // Quick services
      _ServiceLite('food', 'Food', '15 min', 'assets/Queens-Tavern-Steak.jpg', Icons.fastfood_rounded),
      _ServiceLite('taxi', 'Vero Ride', '15 min','assets/uber-cabs-1024x576.webp', Icons.local_taxi_rounded),
      _ServiceLite('mobile_money', 'Vero Pay', '—', 'assets/veropay.png', Icons.account_balance_wallet_rounded),
      _ServiceLite('accommodation', 'Accommodation', '15 min','assets/accomodation.webp', Icons.bed_rounded),
      _ServiceLite('Vero Chat', 'Vero Chat', '—', 'assets/chat.png', Icons.chat),
      _ServiceLite('fx', 'Exchange Rate', '—', 'assets/exchange.png', Icons.currency_exchange_rounded),
      _ServiceLite('home_cleaning', 'Home Cleaning', '18 min','assets/homecleaning.png', Icons.cleaning_services_rounded),
      _ServiceLite('hospital', 'Hospital', '10 min','assets/hospital.png', Icons.local_hospital_rounded),
      // Super-app items (continue same grid)
      _ServiceLite('gym', 'Gym', '—', 'assets/gym.jpg', Icons.fitness_center_rounded),
      _ServiceLite('Hair Salon', 'Hair Salon', '—', 'assets/barber.webp', Icons.content_cut_rounded),
      _ServiceLite('courier', 'vero Courier', '—', 'assets/vero_courier.png', Icons.local_shipping_rounded),
    ];

    final w = MediaQuery.of(context).size.width;
    final ratio = w > 700 ? 1.35 : w > 520 ? 1.32 : 1.28;

    return _ResponsiveGrid(
      items: items,
      onOpen: onOpen,
      childAspectRatio: ratio,
      mainAxisSpacing: 0,
    );
  }
}

/// Shared grid
class _ResponsiveGrid extends StatelessWidget {
  final List<_ServiceLite> items;
  final void Function(String key) onOpen;
  final double childAspectRatio;
  final double mainAxisSpacing;
  const _ResponsiveGrid({
    required this.items,
    required this.onOpen,
    required this.childAspectRatio,
    this.mainAxisSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cross = c.maxWidth > 700 ? 4 : c.maxWidth > 520 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          crossAxisSpacing: 10,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (_, i) => _ServiceLiteTile(
          item: items[i],
          onTap: () => onOpen(items[i].keyId),
        ),
      );
    });
  }
}

class _ServiceLite {
  final String keyId, title, eta, image;
  final IconData icon;
  _ServiceLite(this.keyId, this.title, this.eta, this.image, this.icon);
}

class _ServiceLiteTile extends StatefulWidget {
  final _ServiceLite item;
  final VoidCallback onTap;
  const _ServiceLiteTile({required this.item, required this.onTap});
  @override
  State<_ServiceLiteTile> createState() => _ServiceLiteTileState();
}

class _ServiceLiteTileState extends State<_ServiceLiteTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandOrangeSoft.withOpacity(0.8)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.eta != '—')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrangePale,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.brandOrangeSoft),
                          ),
                          child: Text(item.eta, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.body, fontSize: 10)),
                        ),
                      const Spacer(),
                      Icon(item.icon, size: 16, color: AppColors.title),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 56, maxWidth: 100),
                      child: item.image.isEmpty
                          ? Icon(item.icon, size: 42, color: AppColors.brandOrange)
                          : Image.asset(item.image, height: 56, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(item.icon, size: 42, color: AppColors.brandOrange)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.title)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// NEAR YOU
class _NearYouCarousel extends StatefulWidget {
  const _NearYouCarousel();
  @override
  State<_NearYouCarousel> createState() => _NearYouCarouselState();
}

class _NearYouCarouselState extends State<_NearYouCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ['🚕', 'CityCab', '4.8'],
      ['🍔', 'FoodExpress', '4.6'],
      ['🏨', 'StayHub', '4.7'],
      ['💼', 'UtilityPro', '4.9'],
    ];

    return _Section(
      title: 'Best Places Nearby',
      tight: true,
      gapAfterTitle: kGapAfterNearby, // <-- tiny adjustable gap here
      action: TextButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('See all tapped')),
        ),
        child: const Text('See all', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800)),
      ),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: items.length,
            options: CarouselOptions(
              height: 120,
              viewportFraction: 0.82,
              enlargeCenterPage: true,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              pauseAutoPlayOnTouch: true,
              onPageChanged: (i, _) => setState(() => _index = i),
            ),
            itemBuilder: (_, i, __) {
              final it = items[i];
              return _ProviderCard(emoji: it[0], name: it[1], rating: it[2]);
            },
          ),
          const SizedBox(height: 8),
          _Dots(count: items.length, index: _index),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String emoji, name, rating;
  const _ProviderCard({required this.emoji, required this.name, required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.brandOrangeSoft)),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: AppColors.brandOrangePale, child: Text(emoji, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Row(children: const [Icon(Icons.star, size: 16, color: Color(0xFFFFC107)), SizedBox(width: 2)]),
          ]),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.brandOrange)),
          child: const Text('Open', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

/// DEALS STRIP
class _DealsStrip extends StatelessWidget {
  const _DealsStrip();
  @override
  Widget build(BuildContext context) {
    final deals = const [
      ['🚕', 'Taxi: 20% off night rides'],
      ['🍔', 'Food: free delivery this week'],
      ['🏨', 'Stay: 3 nights, pay 2'],
      ['💳', 'Mobile money: fee-off promos'],
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE2BF), Colors.white]),
            border: Border.all(color: AppColors.brandOrangeSoft),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text('${deals[i][0]}  ${deals[i][1]}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.title))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: deals.length,
      ),
    );
  }
}

// ===== Latest Arrivals =====
class LatestArrivalsSection extends StatefulWidget {
  const LatestArrivalsSection({super.key});
  @override
  State<LatestArrivalsSection> createState() => _LatestArrivalsSectionState();
}

class _LatestArrivalsSectionState extends State<LatestArrivalsSection> {
  final _service = LatestArrivalServices();
  late Future<List<LatestArrivalModels>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchLatestArrivals();
  }

  String _fmtKwacha(int n) {
    final s = n.toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Latest Arrivals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<LatestArrivalModels>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Could not load arrivals.\n${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                );
              }

              final items = snap.data ?? const <LatestArrivalModels>[];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No items yet.', style: TextStyle(color: Colors.red))),
                );
              }

              final width = MediaQuery.of(context).size.width;
              final cols  = width >= 1200 ? 4 : width >= 800 ? 3 : 2;
              final ratio = width >= 1200 ? 0.95 : width >= 800 ? 0.85 : 0.72;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: ratio,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return _ProductCardFromApi(
                    imageUrl: it.imageUrl,
                    name: it.name,
                    priceText: 'MWK ${_fmtKwacha(it.price)}',
                    brandOrange: const Color(0xFFFF8A00),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCardFromApi extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String priceText;
  final Color brandOrange;

  const _ProductCardFromApi({required this.imageUrl, required this.name, required this.priceText, required this.brandOrange});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, prog) => prog == null ? child : const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDEDED), child: const Center(child: Icon(Icons.image_not_supported_rounded))),
                    )
                  : Container(color: const Color(0xFFEDEDED), child: const Center(child: Icon(Icons.image_not_supported_rounded))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(priceText, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green)),
                  ]),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showCardOptions(context, name),
                  icon: Icon(Icons.add_circle, color: brandOrange),
                  tooltip: 'Add / Options',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCardOptions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Choose an action', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.green),
            title: const Text('Add to cart'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added to cart')));
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: brandOrange),
            title: const Text('More details'),
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }
}

/// Section wrapper — when `tight: true`, we put zero bottom padding on the header
/// and insert a small SizedBox you can tune via `gapAfterTitle`.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final bool tight;
  final double gapAfterTitle; // <-- adjustable gap right under the title

  const _Section({
    required this.title,
    required this.child,
    this.action,
    this.tight = false,
    this.gapAfterTitle = 0, // default no extra gap unless you pass a value
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: tight ? 0 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // when tight, no bottom padding — the gap below is controlled by gapAfterTitle
            padding: EdgeInsets.fromLTRB(16, tight ? 0 : 10, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                  ),
                ),
                const Spacer(),
                if (action != null) action!,
              ],
            ),
          ),
          SizedBox(height: gapAfterTitle), // <-- adjust gap here (uses the constants above)
          child,
        ],
      ),
    );
  }
}
