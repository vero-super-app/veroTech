// import 'package:flutter/material.dart';
// import 'package:super_app/Pages/Home/Hostel_details.dart';
// import 'package:super_app/models/hostel_model.dart';
// import 'package:super_app/services/hostel_service.dart';

// class HostelPage extends StatefulWidget {
//   @override
//   _HostelPageState createState() => _HostelPageState();
// }

// class _HostelPageState extends State<HostelPage> {
//   late Future<List<Hostel>> _hostels;

//   @override
//   void initState() {
//     super.initState();
//     _hostels = HostelService().fetchHostels();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Hostels'),
//         centerTitle: true,
//         backgroundColor: Colors.orange,
//       ),
//       body: FutureBuilder<List<Hostel>>(
//         future: _hostels,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No hostels found'));
//           }

//           final hostels = snapshot.data!;

//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Search Bar
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: 'Search hostels',
//                       prefixIcon: Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Recommended Section
//                 SectionHeader(
//                   title: 'Recently Posted',
//                   onSeeAll: () {},
//                 ),
//                 SizedBox(
//                   height: 220,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: hostels.length,
//                     itemBuilder: (context, index) {
//                       final hostel = hostels[index];
//                       return HostelCard(
//                         hostel: hostel,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => HostelDetailPage(hostel: hostel),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//                 // Nearby Section
//                 SectionHeader(
//                   title: 'Nearby Hostels',
//                   onSeeAll: () {},
//                 ),
//                 ListView.builder(
//                   itemCount: hostels.length,
//                   shrinkWrap: true,
//                   physics: NeverScrollableScrollPhysics(),
//                   itemBuilder: (context, index) {
//                     final hostel = hostels[index];
//                     return HostelListTile(
//                       hostel: hostel,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => HostelDetailPage(hostel: hostel),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class SectionHeader extends StatelessWidget {
//   final String title;
//   final VoidCallback onSeeAll;

//   const SectionHeader({
//     required this.title,
//     required this.onSeeAll,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           TextButton(
//             onPressed: onSeeAll,
//             child: Text('See all', style: TextStyle(color: Colors.teal)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class HostelCard extends StatelessWidget {
//   final Hostel hostel;
//   final VoidCallback onTap;

//   const HostelCard({
//     required this.hostel,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       elevation: 4,
//       child: InkWell(
//         onTap: onTap,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
//               child: Image.network(
//                 hostel.image.isNotEmpty ? hostel.image : 'https://i.pinimg.com/736x/64/12/10/64121069b5fc37e1fb979f1604ceb675.jpg',
//                 width: 160,
//                 height: 100,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     hostel.houseName,
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   SizedBox(height: 4.0),
//                   Text(
//                     'MWK ${hostel.price} / month',
//                     style: TextStyle(fontSize: 14, color: Colors.teal),
//                   ),
//                   SizedBox(height: 4.0),
//                   TextButton(
//                     onPressed: onTap,
//                     child: Text('See More', style: TextStyle(color: Colors.teal)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class HostelListTile extends StatelessWidget {
//   final Hostel hostel;
//   final VoidCallback onTap;

//   const HostelListTile({
//     required this.hostel,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: ClipRRect(
//         borderRadius: BorderRadius.circular(8.0),
//         child: Image.network(
//           hostel.image.isNotEmpty ? hostel.image : 'https://i.pinimg.com/736x/64/12/10/64121069b5fc37e1fb979f1604ceb675.jpg',
//           width: 50,
//           height: 50,
//           fit: BoxFit.cover,
//         ),
//       ),
//       title: Text(
//         hostel.houseName,
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//       ),
//       subtitle: Text('${hostel.location} • MWK ${hostel.price} / month'),
//       trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
//       onTap: onTap,
//     );
//   }
// }
