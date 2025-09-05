import 'package:flutter/material.dart';
import 'package:vero360_app/Pages/Home/Hostel_details.dart';
import 'package:vero360_app/models/hostel_model.dart';
import 'package:vero360_app/services/hostel_service.dart';

class AccomodationPage extends StatefulWidget {
  const AccomodationPage({Key? key}) : super(key: key);

  @override
  _HostelPageState createState() => _HostelPageState();
}

class _HostelPageState extends State<AccomodationPage> {
  late Future<List<Hostel>> _hostels;

  @override
  void initState() {
    super.initState();
    _hostels = HostelService().fetchHostels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostels'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Hostel>>(
        future: _hostels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hostels found'));
          }

          final hostels = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search hostels',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                // Recommended Section
                SectionHeader(
                  title: 'Recently Posted',
                  onSeeAll: () {},
                ),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: hostels.length,
                    itemBuilder: (context, index) {
                      final hostel = hostels[index];
                      return HostelCard(
                        hostel: hostel,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HostelDetailPage(hostel: hostel),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Nearby Section
                SectionHeader(
                  title: 'Nearby Hostels',
                  onSeeAll: () {},
                ),
                ListView.builder(
                  itemCount: hostels.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final hostel = hostels[index];
                    return HostelListTile(
                      hostel: hostel,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HostelDetailPage(hostel: hostel),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }
}

// Hostel Card for horizontal list
class HostelCard extends StatelessWidget {
  final Hostel hostel;
  final VoidCallback onTap;

  const HostelCard({Key? key, required this.hostel, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: Image.network(
                hostel.image.isNotEmpty
                    ? hostel.image
                    : 'https://i.pinimg.com/736x/64/12/10/64121069b5fc37e1fb979f1604ceb675.jpg',
                width: 160,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hostel.houseName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'MWK ${hostel.price} / month',
                    style: const TextStyle(fontSize: 14, color: Colors.teal),
                  ),
                  const SizedBox(height: 4.0),
                  TextButton(
                    onPressed: onTap,
                    child:
                        const Text('See More', style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Hostel List Tile for vertical list
class HostelListTile extends StatelessWidget {
  final Hostel hostel;
  final VoidCallback onTap;

  const HostelListTile({Key? key, required this.hostel, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          hostel.image.isNotEmpty
              ? hostel.image
              : 'https://i.pinimg.com/736x/64/12/10/64121069b5fc37e1fb979f1604ceb675.jpg',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        hostel.houseName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${hostel.location} • MWK ${hostel.price} / month'),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
      onTap: onTap,
    );
  }
}
