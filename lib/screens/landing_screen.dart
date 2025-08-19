import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../features/barbers/customer_ui.dart'; // <- BarbersCustomerScreen


/// ——— Brand palette
class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const chip = Color(0xFFF2F3F7);
  static const card = Color(0xFFFFFFFF);
  static const bgTop = Color(0xFFFFF4E9);
  static const bgBottom = Color(0xFFFFFFFF);

  // Accents per vertical
  static const taxiGrad = [Color(0xFF2EC5CE), Color(0xFF8DE9D9)];
  static const hostelGrad = [Color(0xFF845EF7), Color(0xFFA78BFA)];
  static const apartmentGrad = [Color(0xFFFF8A00), Color(0xFFFFB85C)];
  static const foodGrad = [Color(0xFFFF5D5D), Color(0xFFFF9A9A)];
  static const barberGrad = [Color(0xFF4ADE80), Color(0xFFA7F3D0)];
  static const gymGrad = [Color(0xFF60A5FA), Color(0xFFA5B4FC)];
}

Widget _screenFor(String key) {
  switch (key) {
    case 'taxi':      return const TaxiBookingScreen();
    case 'hostel':    return const HostelFinderScreen();
    case 'apartment': return const ApartmentFinderScreen();
    case 'food':      return const FoodOrderScreen();
    case 'barber':    return const BarbersCustomerScreen(); // <- go to barbershop section (customer UI)
    case 'gym':       return const GymTrainerScreen();
    default:          return const _ComingSoonScreen();
  }
}


/// ======================================================
///                 TAB SHELL (STATEFUL)
/// ======================================================
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _index = 0;
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  Future<bool> _onWillPop() async {
    final nav = _navigatorKeys[_index].currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false; // handled
    }
    if (_index != 0) {
      setState(() => _index = 0); // go Home instead of exiting
      return false;
    }
    return true; // allow system back to exit app
  }

  void _onTabTap(int i) {
    if (i == _index) {
      // pop to root if tapping the current tab
      _navigatorKeys[i].currentState!.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: List.generate(4, (i) {
            return Offstage(
              offstage: _index != i,
              child: Navigator(
                key: _navigatorKeys[i],
                onGenerateRoute: (settings) {
                  Widget page;
                  switch (i) {
                    case 0: page = const _HomeTab(); break;
                    case 1: page = const _ShopTab(); break;
                    case 2: page = const _ServicesTab(); break;
                    case 3: page = const _ProfileTab(); break;
                    default: page = const _HomeTab();
                  }
                  return MaterialPageRoute(builder: (_) => page);
                },
              ),
            );
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTabTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.brandOrange,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: 'Services'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

/// ======================================================
///                    HOME TAB (rich)
/// ======================================================
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final PageController _featured = PageController(viewportFraction: 0.86);
  int _page = 0;
  bool _animateIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _featured.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {int delay = 0}) {
    return AnimatedOpacity(
      opacity: _animateIn ? 1 : 0,
      duration: Duration(milliseconds: 520 + delay),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _animateIn ? Offset.zero : const Offset(0, 0.08),
        duration: Duration(milliseconds: 520 + delay),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

void _openService(BuildContext context, String key) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => _screenFor(key),
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
  ));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0, -1), end: Alignment(0, 1),
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            // HERO
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 260,
              backgroundColor: AppColors.bgTop,
              elevation: 0,
              titleSpacing: 0,
              centerTitle: false,
              title: Row(
                children: [
                  const SizedBox(width: 12),
                  Hero(
                    tag: 'brand-mark',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo_mark.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.eco, color: AppColors.brandOrange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('VeroTech',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.title)),
                ],
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/veggies.jpg', fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFDFF3E0))),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0, -0.7), end: Alignment(0, 1),
                          colors: [Color(0x66FFFFFF), Colors.white],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _animated(const _HeroSearch(), delay: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // STRIP + DIRECTORY + FEATURED + RAILS + WHY + TESTIMONIALS + DEALS + CTA
            SliverToBoxAdapter(child: _space(10)),
                    SliverToBoxAdapter(child: _animated(const _QuickStrip(), delay: 40)),
                    SliverToBoxAdapter(child: _space(6)),
                    SliverToBoxAdapter(child: _animated(_FeaturedCarousel(
                      controller: _featured,
                      onPageChanged: (i) => setState(() => _page = i),
                    ), delay: 80)),
                    SliverToBoxAdapter(child: _Dots(count: 3, index: _page)),
                    SliverToBoxAdapter(child: _space(6)),

                    // ↓↓↓ moved here
                    SliverToBoxAdapter(child: _animated(_ServiceDirectory(
                      onOpen: (k) => _openService(context, k),
                    ), delay: 60)),

            SliverToBoxAdapter(child: _Dots(count: 3, index: _page)),
            SliverToBoxAdapter(child: _space(6)),
            SliverToBoxAdapter(child: _animated(const _NearYou(), delay: 100)),
            SliverToBoxAdapter(child: _space(6)),
            SliverToBoxAdapter(child: _animated(const _BookAgain(), delay: 120)),
            SliverToBoxAdapter(child: _space(6)),
            SliverToBoxAdapter(child: _animated(const _WhyChooseUs(), delay: 140)),
            SliverToBoxAdapter(child: _space(6)),
            SliverToBoxAdapter(child: _animated(const _Testimonials(), delay: 160)),
            SliverToBoxAdapter(child: _space(8)),
            SliverToBoxAdapter(child: _animated(const _DealsStrip(), delay: 180)),
            SliverToBoxAdapter(child: _space(16)),
            SliverToBoxAdapter(child: _animated(_CTAButtons(), delay: 200)),
            SliverToBoxAdapter(child: _space(24)),
          ],
        ),
      ),
    );
  }

  Widget _space(double h) => SizedBox(height: h);
}

/// ======================================================
///                 OTHER TABS (state kept)
/// ======================================================
class _ShopTab extends StatelessWidget {
  const _ShopTab();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.title),
        iconTheme: const IconThemeData(color: AppColors.title),
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Shop'),
      ),
      body: ListView.builder(
        key: const PageStorageKey('shop-list'),
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('Featured item #$i'),
            subtitle: const Text('Reserved for products API'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.title),
        iconTheme: const IconThemeData(color: AppColors.title),
        backgroundColor: Colors.white, elevation: 0.5,
        title: const Text('Services'),
      ),
          body: _ServiceDirectory(
        onOpen: (k) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _screenFor(k)),
        ),
      ),

    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.title),
        iconTheme: const IconThemeData(color: AppColors.title),
        backgroundColor: Colors.white, elevation: 0.5,
        title: const Text('Profile'),
      ),
      body: ListView(
        key: const PageStorageKey('profile-list'),
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Your account'),
            subtitle: const Text('Sign in or manage details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Bookings & orders'),
            subtitle: const Text('History from all services'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_outlined),
            title: const Text('Payments'),
            subtitle: const Text('Cards & wallets'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// ======================================================
///                 HOME COMPONENTS (same look)
/// ======================================================
// ───────────────── Hero: Search first, then headline ─────────────────
// ───────────────── Hero: headline only (no search bar) ─────────────────
class _HeroSearch extends StatelessWidget {
  const _HeroSearch();

  @override
  Widget build(BuildContext context) {
    return const _HeadlineCard(); // search removed
  }
}


// ————— Pretty headline block with chips + subtle gradient/zshadow —————
class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.2, -1),
          end: Alignment(0.8, 1),
          colors: [
            Color(0xFFFFF0E1), // soft peach
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FF8A00)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          // Texts + chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline with subtle emphasis on “one app”
                RichText(
                  text: TextSpan(
                    children: const [
                      TextSpan(
                        text: 'Everything you need — ',
                        style: TextStyle(
                          color: AppColors.title,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.15,
                        ),
                      ),
                      TextSpan(
                        text: 'in one app',
                        style: TextStyle(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Groceries, rides, stays, grooming, fitness and more.',
                  style: TextStyle(
                    color: AppColors.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                // Chips row
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TagChip(text: 'Groceries'),
                    _TagChip(text: 'Taxi'),
                    _TagChip(text: 'Food'),
                    _TagChip(text: 'Hostel'),
                    _TagChip(text: 'Apartment'),
                    _TagChip(text: 'Barber'),
                    _TagChip(text: 'Gym'),
                  ],
                ),
              ],
            ),
          ),

          // Decorative badge on the right
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.brandOrange, Color(0xFFFFB85C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandOrange.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: AppColors.title),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.title,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}


class _QuickStrip extends StatelessWidget {
  const _QuickStrip();
  @override
  Widget build(BuildContext context) {
    final items = const [
      ['⚡', 'Lightning deals'], ['🗺️', 'Explore map'], ['⭐', 'Top rated'], ['🛟', 'Support'],
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text('${items[i][0]}  ${items[i][1]}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.title))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8), itemCount: items.length,
      ),
    );
  }
}


// ───────────────── Super App Services (Redesigned) ─────────────────
class _ServiceDirectory extends StatelessWidget {
  final void Function(String key) onOpen;
  const _ServiceDirectory({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceItem>[
      _ServiceItem(
        keyId: 'taxi',
        title: 'Book a Taxi',
        subtitle: 'Fast • Safe • Affordable',
        meta: 'ETA 4–6 min',
        icon: Icons.local_taxi_rounded,
        grad: AppColors.taxiGrad,
      ),
      _ServiceItem(
        keyId: 'food',
        title: 'Order Food',
        subtitle: 'Local favorites • Hot deals',
        meta: 'Free delivery today',
        icon: Icons.fastfood_rounded,
        grad: AppColors.foodGrad,
      ),
      _ServiceItem(
        keyId: 'hostel',
        title: 'Find a Hostel',
        subtitle: 'Clean • Budget stays',
        meta: 'From MWK 7,500',
        icon: Icons.bedroom_child_rounded,
        grad: AppColors.hostelGrad,
      ),
      _ServiceItem(
        keyId: 'apartment',
        title: 'Find an Apartment',
        subtitle: 'Rent • Manage • Pay',
        meta: 'Verified listings',
        icon: Icons.apartment_rounded,
        grad: AppColors.apartmentGrad,
      ),
      _ServiceItem(
        keyId: 'barber',
        title: 'Schedule a Barber',
        subtitle: 'Home visit • In-shop',
        meta: 'Slots today',
        icon: Icons.content_cut_rounded,
        grad: AppColors.barberGrad,
      ),
      _ServiceItem(
        keyId: 'gym',
        title: 'Gym Trainer',
        subtitle: '1:1 sessions • Plans',
        meta: 'Top rated 4.9',
        icon: Icons.fitness_center_rounded,
        grad: AppColors.gymGrad,
      ),
    ];

    return _Section(
      title: 'Super app services',
      action: TextButton(
        onPressed: () {}, // e.g., open a "Customize" modal later
        child: const Text(
          'Customize',
          style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 420;
            final cross = isWide ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18, // a touch taller for the new layout
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _ServiceCard(
                item: items[i],
                onTap: () => onOpen(items[i].keyId),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String keyId;
  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final List<Color> grad;

  _ServiceItem({
    required this.keyId,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.grad,
  });
}

class _ServiceCard extends StatefulWidget {
  final _ServiceItem item;
  final VoidCallback onTap;
  const _ServiceCard({required this.item, required this.onTap});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(20);

    return Semantics(
      button: true,
      label: '${widget.item.title}. ${widget.item.subtitle}. ${widget.item.meta}.',
      child: AnimatedScale(
        scale: _pressed ? 0.98 : (_hover ? 1.01 : 1.0),
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _pressed ? 1.0 : (_hover ? -1.0 : 0.0), 0),
          child: Material(
            color: Colors.transparent,
            child: FocusableActionDetector(
              onShowHoverHighlight: (h) => setState(() => _hover = h),
              onShowFocusHighlight: (f) => setState(() => _focused = f),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: r,
                  gradient: LinearGradient(colors: widget.item.grad),
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.grad.first.withOpacity(_hover || _focused ? 0.35 : 0.25),
                      blurRadius: _hover ? 22 : 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  // optional focus ring
                  border: _focused
                      ? Border.all(color: Colors.white.withOpacity(0.85), width: 1.2)
                      : null,
                ),
                child: InkWell(
                  borderRadius: r,
                  onTap: widget.onTap,
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  child: Stack(
                    children: [
                      // Decorative soft circles (slightly larger on hover)
                      Positioned(
                        right: -18,
                        top: -18,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: _SoftCircle(
                            size: _hover ? 110 : 90,
                            color: Colors.white.withOpacity(0.20),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -24,
                        bottom: -16,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: _SoftCircle(
                            size: _hover ? 140 : 120,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ),

                      // Shine sweep overlay
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _hover ? 0.18 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: r,
                                gradient: const LinearGradient(
                                  begin: Alignment(-1, -1),
                                  end: Alignment(1, 1),
                                  colors: [Colors.white, Colors.transparent],
                                  stops: [0.0, 0.6],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Icon chip (top-left)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(widget.item.icon, color: AppColors.title),
                        ),
                      ),

                      // “Go” button (top-right) with subtle rotation on hover/press
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedRotation(
                          turns: (_hover || _pressed) ? 0.125 : 0.0, // ~45°
                          duration: const Duration(milliseconds: 160),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.arrow_forward_rounded, size: 18),
                            ),
                          ),
                        ),
                      ),

                      // Bottom glass panel with texts
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.65)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                  color: AppColors.title,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.body,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const _AccentBadge(icon: Icons.auto_awesome_rounded),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.item.meta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.title,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _AccentBadge extends StatelessWidget {
  final IconData icon;
  const _AccentBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x14FF8A00),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FF8A00)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandOrange),
          const SizedBox(width: 4),
          const Text(
            'Quick access',
            style: TextStyle(
              color: AppColors.brandOrange,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}


class _ServiceTile extends StatelessWidget {
  final String title, subtitle; final IconData icon; final List<Color> grad; final VoidCallback onTap;
  const _ServiceTile({required this.title, required this.subtitle, required this.icon, required this.grad, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18), onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: grad),
          boxShadow: [BoxShadow(color: grad.first.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 10))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 34, width: 34, decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.title)),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15), maxLines: 2),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  final PageController controller; final ValueChanged<int> onPageChanged;
  const _FeaturedCarousel({required this.controller, required this.onPageChanged, super.key});
  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}
class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _FeaturedCard(image: 'assets/basket.jpg', title: 'Ride Pass', subtitle: 'Save on weekly taxi rides', badge: '-15%', onTap: () {}),
      _FeaturedCard(image: 'assets/veggies.jpg', title: 'Food Fiesta', subtitle: 'Buy 1 Get 1 at select spots', badge: 'BOGO', onTap: () {}),
      _FeaturedCard(image: 'assets/basket.jpg', title: 'Stay Deals', subtitle: 'Hostel & apartment offers', badge: 'Hot', onTap: () {}),
    ];
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: widget.controller, onPageChanged: widget.onPageChanged, itemCount: cards.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(left: i == 0 ? 16 : 8, right: i == cards.length - 1 ? 16 : 8),
          child: cards[i],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String image, title, subtitle, badge; final VoidCallback onTap;
  const _FeaturedCard({required this.image, required this.title, required this.subtitle, required this.badge, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22), onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 22, offset: const Offset(0, 12))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDEDED))),
            Container(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.55)]))),
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.brandOrange, borderRadius: BorderRadius.circular(12)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
            Positioned(
              left: 14, right: 14, bottom: 14,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w600)),
                ])),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.brandOrange,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  child: const Text('Get', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NearYou extends StatelessWidget {
  const _NearYou();
  @override
  Widget build(BuildContext context) {
    final items = const [['🚕', 'CityCab', '4.8'], ['🍔', 'FoodExpress', '4.6'], ['💇‍♂️', 'Blade & Fade', '4.9'], ['🏋️‍♂️', 'FitPro Trainers', '4.7']];
    return _Section(
      title: 'Near you',
      action: TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800))),
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => _ProviderCard(emoji: items[i][0], name: items[i][1], rating: items[i][2]),
          separatorBuilder: (_, __) => const SizedBox(width: 12), itemCount: items.length,
        ),
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
      width: 220,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 10))]),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: const Color(0x14FF8A00), child: Text(emoji, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)), const SizedBox(width: 2),
            Text(rating, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.body)),
          ]),
        ])),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: () {}, style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: AppColors.brandOrange),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          child: const Text('Open', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _BookAgain extends StatelessWidget {
  const _BookAgain();
  @override
  Widget build(BuildContext context) {
    final items = const ['Taxi to work', 'Chicken & chips', 'Barber - Sam', 'Trainer - Ayo'];
    return _Section(
      title: 'Book again',
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => ActionChip(
            label: Text(items[i], style: const TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () {}, backgroundColor: AppColors.chip, side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          separatorBuilder: (_, __) => const SizedBox(width: 8), itemCount: items.length,
        ),
      ),
    );
  }
}

// ───────────────── Why Choose Us (Redesigned) ─────────────────
class _WhyChooseUs extends StatelessWidget {
  const _WhyChooseUs();

  @override
  Widget build(BuildContext context) {
    final items = <_Benefit>[
      _Benefit(
        title: 'Trusted quality',
        subtitle: 'Organic-first sourcing • Verified partners',
        kpiIcon: Icons.star_rounded,
        kpiText: '4.8/5 average',
        footNote: '100k+ ratings',
        icon: Icons.verified_rounded,
        grad: const [Color(0xFF60A5FA), Color(0xFFA5B4FC)],
        checks: const ['Freshness guaranteed', 'Cold-chain where needed'],
      ),
      _Benefit(
        title: 'Fair prices',
        subtitle: 'Transparent fees • No tricks',
        kpiIcon: Icons.savings_rounded,
        kpiText: 'Save up to 20%',
        footNote: 'vs. typical market',
        icon: Icons.payments_rounded,
        grad: const [Color(0xFFFF8A00), Color(0xFFFFB85C)],
        checks: const ['Weekly bundles', 'Ride & food deals'],
      ),
      _Benefit(
        title: 'Support & safety',
        subtitle: 'We’re here every day',
        kpiIcon: Icons.headset_mic_rounded,
        kpiText: '7-day support',
        footNote: 'In-app chat & phone',
        icon: Icons.shield_moon_rounded,
        grad: const [Color(0xFF34D399), Color(0xFFA7F3D0)],
        checks: const ['Secure payments', 'Verified providers'],
      ),
    ];

    return _Section(
      title: 'Why choose us',
      action: TextButton(
        onPressed: () {},
        child: const Text(
          'Our promise',
          style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 420;
            final cross = isWide ? 3 : 1; // 3 on wide, stacked on narrow

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.10,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _BenefitCard(benefit: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _Benefit {
  final String title;
  final String subtitle;
  final IconData kpiIcon;
  final String kpiText;
  final String footNote;
  final IconData icon;
  final List<Color> grad;
  final List<String> checks;

  _Benefit({
    required this.title,
    required this.subtitle,
    required this.kpiIcon,
    required this.kpiText,
    required this.footNote,
    required this.icon,
    required this.grad,
    required this.checks,
  });
}

class _BenefitCard extends StatefulWidget {
  final _Benefit benefit;
  const _BenefitCard({required this.benefit});

  @override
  State<_BenefitCard> createState() => _BenefitCardState();
}

class _BenefitCardState extends State<_BenefitCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final rOuter = BorderRadius.circular(18);

    return Semantics(
      label:
          '${widget.benefit.title}. ${widget.benefit.subtitle}. ${widget.benefit.kpiText}.',
      child: AnimatedScale(
        scale: _pressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: rOuter,
            onTap: () {}, // Optional: open details modal
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Container(
              decoration: BoxDecoration(
                // gradient outline
                gradient: LinearGradient(colors: widget.benefit.grad),
                borderRadius: rOuter,
                boxShadow: [
                  BoxShadow(
                    color: widget.benefit.grad.first.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.2), // outline thickness
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: rOuter,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // icon chip
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.benefit.icon, color: AppColors.title),
                    ),
                    const SizedBox(height: 10),

                    // title + subtitle
                    Text(
                      widget.benefit.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.benefit.subtitle,
                      style: const TextStyle(
                        color: AppColors.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    // KPI pill
                    _KpiPill(
                      icon: widget.benefit.kpiIcon,
                      text: widget.benefit.kpiText,
                    ),
                    const SizedBox(height: 6),

                    // tiny footnote + checks row
                    Text(
                      widget.benefit.footNote,
                      style: const TextStyle(
                        color: AppColors.body,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.benefit.checks
                          .map((t) => _CheckChip(text: t))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _KpiPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FF8A00),
        border: Border.all(color: const Color(0x22FF8A00)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.brandOrange),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.brandOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  final String text;
  const _CheckChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: AppColors.title),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.title,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


class _BadgeTile extends StatelessWidget {
  final IconData icon; final String title, body;
  const _BadgeTile({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA))),
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 34, width: 34, decoration: BoxDecoration(color: const Color(0x14FF8A00), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.brandOrange)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.body, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => _TestimonialCard(initials: items[i][0], quote: items[i][1]),
          separatorBuilder: (_, __) => const SizedBox(width: 12), itemCount: items.length,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 10))]),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: const Color(0x14FF8A00),
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandOrange))),
        const SizedBox(width: 10),
        Expanded(child: Text(quote, maxLines: 3, style: const TextStyle(color: AppColors.body, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _DealsStrip extends StatelessWidget {
  const _DealsStrip();
  @override
  Widget build(BuildContext context) {
    final deals = const [
      ['🚕', 'Taxi: 20% off night rides'],
      ['🍔', 'Food: free delivery this week'],
      ['🏨', 'Hostel: stay 3 nights, pay 2'],
      ['🏋️‍♂️', 'Trainer: 1st session free'],
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE2BF), Colors.white]),
            border: Border.all(color: const Color(0x22FF8A00)), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text('${deals[i][0]}  ${deals[i][1]}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.title))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10), itemCount: deals.length,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title; final Widget child; final Widget? action;
  const _Section({required this.title, required this.child, this.action});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.title)),
            const Spacer(), if (action != null) action!,
          ]),
        ),
        child,
      ]),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count; final int index;
  const _Dots({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.brandOrange : const Color(0xFFE1E1E1),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      })),
    );
  }
}

class _CTAButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE2BF), Colors.white]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22FF8A00)),
        ),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 10, spacing: 10, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.local_mall_outlined, color: AppColors.brandOrange),
            const Text('Ready to get started?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandOrange, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandOrange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Sign in', style: TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================================================
///             PLACEHOLDER SERVICE SCREENS
/// ======================================================
class TaxiBookingScreen extends StatelessWidget {
  const TaxiBookingScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Book a Taxi', colorGrad: AppColors.taxiGrad, icon: Icons.local_taxi_rounded);
}
class HostelFinderScreen extends StatelessWidget {
  const HostelFinderScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Find a Hostel', colorGrad: AppColors.hostelGrad, icon: Icons.bedroom_child_rounded);
}
class ApartmentFinderScreen extends StatelessWidget {
  const ApartmentFinderScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Find an Apartment', colorGrad: AppColors.apartmentGrad, icon: Icons.apartment_rounded);
}
class FoodOrderScreen extends StatelessWidget {
  const FoodOrderScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Order Food', colorGrad: AppColors.foodGrad, icon: Icons.fastfood_rounded);
}
class BarberBookingScreen extends StatelessWidget {
  const BarberBookingScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Schedule a Barber', colorGrad: AppColors.barberGrad, icon: Icons.content_cut_rounded);
}
class GymTrainerScreen extends StatelessWidget {
  const GymTrainerScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Gym Trainer', colorGrad: AppColors.gymGrad, icon: Icons.fitness_center_rounded);
}
class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
    title: 'Coming soon', colorGrad: const [Color(0xFF94A3B8), Color(0xFFCBD5E1)], icon: Icons.hourglass_bottom_rounded);
}

class _StubScaffold extends StatelessWidget {
  final String title; final List<Color> colorGrad; final IconData icon;
  const _StubScaffold({required this.title, required this.colorGrad, required this.icon, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.title),
        iconTheme: const IconThemeData(color: AppColors.title),
        backgroundColor: Colors.white, elevation: 0.5, title: Text(title),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: colorGrad)),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.layers, color: Colors.white, size: 64),
            SizedBox(height: 12),
            Text('Design your flow here',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            SizedBox(height: 6),
            Text('Reserved for NestJS API wiring.\nHook up data & actions.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
