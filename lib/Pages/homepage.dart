import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:vero360_app/Pages/Accomodation.dart';
import 'package:vero360_app/Pages/Edu.dart';
import 'package:vero360_app/Pages/ExchangeRate.dart';
import 'package:vero360_app/Pages/MerchantApplicationForm.dart';
import 'package:vero360_app/Pages/MobileMoney.dart';
import 'package:vero360_app/Pages/More.dart';
import 'package:vero360_app/Pages/Taxi.dart';
import 'package:vero360_app/Pages/food.dart';
import 'package:vero360_app/Pages/utility.dart';

/// Brand palette
class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const chip = Color(0xFFF2F3F7);
  static const card = Color(0xFFFFFFFF);
  static const bgTop = Color(0xFFFFF4E9);
  static const bgBottom = Color(0xFFFFFFFF);

  // Service gradients (kept for later use)
  static const taxiGrad = [Color(0xFF2EC5CE), Color(0xFF8DE9D9)];
  static const hostelGrad = [Color(0xFF845EF7), Color(0xFFA78BFA)];
  static const apartmentGrad = [Color(0xFFFF8A00), Color(0xFFFFB85C)];
  static const foodGrad = [Color(0xFFFF5D5D), Color(0xFFFF9A9A)];
  static const utilityGrad = [Color(0xFF22C55E), Color(0xFFA7F3D0)];
  static const mmGrad = [Color(0xFF60A5FA), Color(0xFFA5B4FC)];
  static const fxGrad = [Color(0xFF94A3B8), Color(0xFFCBD5E1)];
  static const eduGrad = [Color(0xFFFF8A00), Color(0xFFFFC38A)];
  static const moreGrad = [Color(0xFF111827), Color(0xFF374151)];
}

class Vero360Homepage extends StatefulWidget {
  final String email;
  const Vero360Homepage({super.key, required this.email});

  @override
  State<Vero360Homepage> createState() => _Vero360HomepageState();
}

String _firstNameFromEmail(String? e) {
  if (e == null) return 'there';
  final trimmed = e.trim();
  if (trimmed.isEmpty) return 'there';
  final at = trimmed.indexOf('@');
  final base = at == -1 ? trimmed : trimmed.substring(0, at);
  if (base.isEmpty) return 'there';
  return base[0].toUpperCase() + base.substring(1);
}

class _Vero360HomepageState extends State<Vero360Homepage> {
  final _search = TextEditingController();
  int _promoIndex = 0;
  bool _animateIn = false;

  // Promos for the top slider (image can be any of your assets)
  final List<_Promo> _promos = const [
    _Promo(
      title: 'Save 30% OFF',
      subtitle: 'first 2 Orders',
      code: 'Use code FOOD30',
      image: 'assets/happy.jpg', // change if you prefer
      bg: Color(0xFFF3E8FF),
      tint: Color(0xFFB388FF),
    ),
    _Promo(
      title: 'Free Delivery',
      subtitle: 'all week long',
      code: 'Use code FREEDEL',
      image: 'assets/Queens-Tavern-Steak.jpg',
      bg: Color(0xFFFFF0E1),
      tint: AppColors.brandOrange,
    ),
    _Promo(
      title: 'Ride Deals',
      subtitle: 'Taxi • 15% off',
      code: 'Use code GO15',
      image: 'assets/uber-cabs-1024x576.webp',
      bg: Color(0xFFE7F6FF),
      tint: Color(0xFF60A5FA),
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
    final greeting = 'Hi, ${_firstNameFromEmail(widget.email)}';

    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top padding + “search location + Pay” row + promo slider (like the screenshot)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _TopSection(
                animateIn: _animateIn,
                greeting: greeting,
                searchController: _search,
                onSearchTap: _onSearchTap,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _PromoCarousel(
                promos: _promos,
                onIndex: (i) => setState(() => _promoIndex = i),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Dots(count: _promos.length, index: _promoIndex),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Quick strip (kept)
          const SliverToBoxAdapter(child: _QuickStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Service grid (compact tiles like the screenshot)
          SliverToBoxAdapter(
            child: _Section(
              title: 'Services',
              action: TextButton(
                onPressed: () {},
                child: const Text('Customize',
                    style: TextStyle(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w800)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ServicesGridLite(onOpen: _openService),
              ),
            ),
          ),

          // Near you (now slidable)
          const SliverToBoxAdapter(child: _NearYouCarousel()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Testimonials (kept)
          const SliverToBoxAdapter(child: _Testimonials()),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // Deals strip (kept)
          const SliverToBoxAdapter(child: _DealsStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Latest Arrivals (kept)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _LatestArrivals(),
            ),
          ),

          // CTA (kept)
          const SliverToBoxAdapter(child: _CTA()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  void _onSearchTap() {
    // TODO: open your location picker / search page here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search location tapped')),
    );
  }

  void _openService(String key) {
    Widget page;
    switch (key) {
      case 'food': page = FoodPage(); break;
      case 'grocery': page = FoodPage(); break; // or your grocery page
      case 'courier': page = const UtilityPage(); break;
      case 'taxi': page = const TaxiPage(); break;
      case 'send_money': page = const MobilemoneyPage(); break;
      case 'home_cleaning': page = const UtilityPage(); break;
      case 'medicine': page = const UtilityPage(); break;
      case 'doctor': page = const EducationPage(); break;
      case 'accommodation': page = const AccomodationPage(); break;
      case 'mobile_money': page = const MobilemoneyPage(); break;
      case 'fx': page = const ExchangeRateScreen(); break;
      case 'education': page = const EducationPage(); break;
      default: page = const MorePage();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/// ─────────────────────────────────────────────────────────────────
/// TOP SECTION (search pill + Pay + greeting) — matches the screenshot
/// ─────────────────────────────────────────────────────────────────
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
            // Greeting (subtle, optional)
            Text(
              greeting,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 10),

            // Search pill + Pay chip
            Row(
              children: [
                // Search location pill (InkWell, not an editable TextField to match screenshot)
                Expanded(
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x11000000)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: const [
                          Icon(Icons.search_rounded, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.body,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Pay chip (black)
                InkWell(
                  onTap: () {
                    // TODO: open your Pay flow
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pay tapped')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Pay',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
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

/// Data model for promo
class _Promo {
  final String title;
  final String subtitle;
  final String code;
  final String image;
  final Color bg;
  final Color tint;
  const _Promo({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.image,
    required this.bg,
    required this.tint,
  });
}

/// Promo carousel under the top row (like the screenshot card)
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
              color: p.bg,
              gradient: LinearGradient(
                colors: [p.bg, Colors.white],
                begin: const Alignment(-0.6, -1),
                end: const Alignment(1, 1),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Right image
                Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    child: Image.asset(
                      p.image,
                      width: 180,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 180,
                        color: const Color(0xFFEDEDED),
                        child: const Center(
                          child: Icon(Icons.image_not_supported_rounded),
                        ),
                      ),
                    ),
                  ),
                ),

                // Left copy + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 180, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: TextStyle(
                            color: p.tint,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          )),
                      const SizedBox(height: 2),
                      Text(p.subtitle,
                          style: const TextStyle(
                            color: AppColors.title,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 6),
                      Text(p.code,
                          style: const TextStyle(
                            color: AppColors.body,
                            fontWeight: FontWeight.w700,
                          )),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Order now',
                            style: TextStyle(fontWeight: FontWeight.w900)),
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
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
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
                color:
                    active ? AppColors.brandOrange : const Color(0xFFE1E1E1),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          })),
    );
  }
}

/// Quick chips
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
              borderRadius: BorderRadius.circular(20)),
          child: Center(
              child: Text('${items[i][0]}  ${items[i][1]}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.title))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

/// SERVICES — compact white tiles like the screenshot, with ETA tags
class _ServicesGridLite extends StatelessWidget {
  final void Function(String key) onOpen;
  const _ServicesGridLite({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceLite>[
      _ServiceLite('food', 'Food', '20 min', 'assets/veggies.jpg',
          Icons.fastfood_rounded),
      _ServiceLite('grocery', 'Grocery', '15 min', 'assets/basket.jpg',
          Icons.local_grocery_store_rounded),
      _ServiceLite('courier', 'Courier', '18 min', 'assets/Queens-Tavern-Steak.jpg',
          Icons.local_shipping_rounded),
      _ServiceLite('taxi', 'Taxi', '15 min',
          'assets/uber-cabs-1024x576.webp', Icons.local_taxi_rounded),
      _ServiceLite('send_money', 'Send Money', '—', '', Icons.send_rounded),
      _ServiceLite('home_cleaning', 'Home Cleaning', '18 min', '',
          Icons.cleaning_services_rounded),
      _ServiceLite('medicine', 'Medicine', '20 min', '', Icons.medication_rounded),
      _ServiceLite('doctor', 'Doctor', '10 min', '', Icons.medical_services_rounded),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cross = c.maxWidth > 520 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
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

class _ServiceLiteTile extends StatelessWidget {
  final _ServiceLite item;
  final VoidCallback onTap;
  const _ServiceLiteTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x11000000)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ETA tag
              Row(
                children: [
                  if (item.eta != '—')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(item.eta,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.body,
                              fontSize: 11)),
                    ),
                  const Spacer(),
                  Icon(item.icon, size: 18, color: AppColors.title),
                ],
              ),
              const Spacer(),
              // Illustration / image area
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.image.isEmpty
                      ? Icon(item.icon, size: 44, color: AppColors.brandOrange)
                      : Image.asset(
                          item.image,
                          height: 48,
                          width: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(item.icon,
                              size: 44, color: AppColors.brandOrange),
                        ),
                ),
              ),
              const Spacer(),
              Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AppColors.title)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// NEAR YOU — slidable carousel (center enlarge)
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
      action: TextButton(
        onPressed: () {},
        child: const Text('See all',
            style: TextStyle(
                color: AppColors.brandOrange, fontWeight: FontWeight.w800)),
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
              return _ProviderCard(
                emoji: it[0],
                name: it[1],
                rating: it[2],
              );
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
  const _ProviderCard(
      {required this.emoji, required this.name, required this.rating});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10))
            ]),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0x14FF8A00),
              child: Text(emoji, style: const TextStyle(fontSize: 18))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(children: const [
                  Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                  SizedBox(width: 2),
                ]),
                Text(rating,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.body)),
              ])),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: AppColors.brandOrange),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            child: const Text('Open',
                style: TextStyle(
                    color: AppColors.brandOrange, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
    });
  }
}

/// TESTIMONIALS
class _Testimonials extends StatelessWidget {
  const _Testimonials();
  @override
  Widget build(BuildContext context) {
    final items = const [
      ['MB', '“Super fresh and always on time.”'],
      ['TN', '“Prices are fair and the app is smooth.”'],
      ['AK', '“My go-to for weekly groceries!”'],
    ];
    return _Section(
      title: 'What customers say',
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) =>
              _TestimonialCard(initials: items[i][0], quote: items[i][1]),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: items.length,
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String initials, quote;
  const _TestimonialCard({required this.initials, required this.quote});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 10))
          ]),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0x14FF8A00),
            child: Text(initials,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandOrange))),
        const SizedBox(width: 10),
        Expanded(
            child: Text(quote,
                maxLines: 3,
                style: const TextStyle(
                    color: AppColors.body, fontWeight: FontWeight.w600))),
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
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFE2BF), Colors.white]),
              border: Border.all(color: const Color(0x22FF8A00)),
              borderRadius: BorderRadius.circular(14)),
          child: Center(
              child: Text('${deals[i][0]}  ${deals[i][1]}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.title))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: deals.length,
      ),
    );
  }
}

/// LATEST ARRIVALS (kept)
class _LatestArrivals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String>>[
      {'image': 'assets/basket.jpg', 'name': 'Grocery Basket', 'price': '9,500'},
      {'image': 'assets/veggies.jpg', 'name': 'Fresh Veggie Box', 'price': '6,200'},
      {'image': 'assets/happy.jpg', 'name': 'Essentials Combo', 'price': '11,000'},
      {'image': 'assets/Queens-Tavern-Steak.jpg', 'name': 'Family Feast', 'price': '17,800'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Latest Arrivals",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78),
          itemCount: items.length,
          itemBuilder: (_, i) => _ProductCard(
            image: items[i]['image']!,
            name: items[i]['name']!,
            price: items[i]['price']!,
          ),
        ),
        const SizedBox(height: 16),
        const BecomeSellerWidget(),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String image, name, price;
  const _ProductCard({required this.image, required this.name, required this.price});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Image.asset(
              image,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                color: const Color(0xFFEDEDED),
                child: const Center(
                    child: Icon(Icons.image_not_supported_rounded)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const SizedBox(height: 2),
                    Text('MWK $price',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.green)),
                  ])),
              IconButton(
                onPressed: () {
                  _showCardOptions(context, name);
                },
                icon: const Icon(Icons.add_circle, color: AppColors.brandOrange),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showCardOptions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Choose an action',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.green),
            title: const Text('Add to cart'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name added to cart')));
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded,
                color: AppColors.brandOrange),
            title: const Text('More details'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }
}

/// CTA
class _CTA extends StatelessWidget {
  const _CTA();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient:
              const LinearGradient(colors: [Color(0xFFFFE2BF), Colors.white]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22FF8A00)),
        ),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 10,
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.local_mall_outlined, color: AppColors.brandOrange),
            const Text('Ready to explore more?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Get started',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brandOrange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Learn more',
                  style: TextStyle(
                      color: AppColors.brandOrange,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section wrapper
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title)),
            const Spacer(),
            if (action != null) action!,
          ]),
        ),
        child,
      ]),
    );
  }
}

/// Placeholder seller widget (kept)
class BecomeSellerWidget extends StatelessWidget {
  const BecomeSellerWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
              color: const Color(0x14FF8A00),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.store_mall_directory_outlined,
              color: AppColors.brandOrange),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
              'Become a seller — onboard your store and reach more customers.',
              style:
                  TextStyle(color: AppColors.body, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MerchantApplicationForm())),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child:
              const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
