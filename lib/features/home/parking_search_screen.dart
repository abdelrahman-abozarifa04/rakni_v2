import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/parking_lot_detail_screen.dart';

class ParkingSearchScreen extends StatefulWidget {
  const ParkingSearchScreen({super.key});

  @override
  State<ParkingSearchScreen> createState() => _ParkingSearchScreenState();
}

class _ParkingSearchScreenState extends State<ParkingSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const List<Map<String, dynamic>> _parkingLots = [
    {'name': 'Mall of Arabia', 'address': '6th of October, Giza', 'slots': 42, 'price': 'EGP 10/hr', 'lat': 30.0131, 'lng': 31.2089, 'image': 'assets/images/mall_of_arabia.png'},
    {'name': 'Cairo Festival City', 'address': 'New Cairo, Cairo', 'slots': 18, 'price': 'EGP 15/hr', 'lat': 30.0280, 'lng': 31.4028, 'image': 'assets/images/cfc_mall.png'},
    {'name': 'City Stars', 'address': 'Nasr City, Cairo', 'slots': 76, 'price': 'EGP 8/hr', 'lat': 30.0740, 'lng': 31.3453, 'image': 'assets/images/mall_of_arabia.png'},
    {'name': 'Point 90 Mall', 'address': 'AUC Avenue, New Cairo', 'slots': 35, 'price': 'EGP 12/hr', 'lat': 30.0074, 'lng': 31.4711, 'image': 'assets/images/cfc_mall.png'},
    {'name': 'Waterway', 'address': '5th Settlement, New Cairo', 'slots': 60, 'price': 'EGP 7/hr', 'lat': 30.0200, 'lng': 31.4500, 'image': 'assets/images/mall_of_arabia.png'},
    {'name': 'AUC Campus', 'address': 'New Cairo, Cairo', 'slots': 90, 'price': 'EGP 5/hr', 'lat': 30.0190, 'lng': 31.4400, 'image': 'assets/images/cfc_mall.png'},
    {'name': 'Madinaty', 'address': 'Badr City, Cairo', 'slots': 120, 'price': 'EGP 6/hr', 'lat': 30.1070, 'lng': 31.6400, 'image': 'assets/images/mall_of_arabia.png'},
    {'name': 'Hyde Park', 'address': '5th Settlement, New Cairo', 'slots': 55, 'price': 'EGP 10/hr', 'lat': 30.0100, 'lng': 31.4600, 'image': 'assets/images/cfc_mall.png'},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _parkingLots;
    final q = _query.toLowerCase();
    return _parkingLots.where((lot) =>
      (lot['name'] as String).toLowerCase().contains(q) ||
      (lot['address'] as String).toLowerCase().contains(q)
    ).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Search Parking', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: AppColors.fieldColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.fieldStroke)),
            child: Row(children: [
              const SizedBox(width: 16),
              const Icon(Icons.search, color: AppColors.hintColor, size: 20),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _controller, autofocus: true,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Search for a parking spot...', hintStyle: TextStyle(color: AppColors.hintColor, fontSize: 14), border: InputBorder.none, isDense: true),
                onChanged: (v) => setState(() => _query = v),
              )),
              const SizedBox(width: 16),
            ]),
          ),
        ),
        Expanded(child: results.isEmpty ? _buildEmpty() : _buildResults(results)),
      ]),
    );
  }

  Widget _buildEmpty() => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded, color: AppColors.hintColor, size: 48),
    SizedBox(height: 12),
    Text('No parking lots found', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
  ]));

  Widget _buildResults(List<Map<String, dynamic>> results) => ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: results.length,
    separatorBuilder: (_, __) => const Divider(color: AppColors.fieldStroke, height: 1),
    itemBuilder: (context, i) {
      final lot = results[i];
      return _SearchResultTile(lot: lot, onTap: () => _openDetail(lot));
    },
  );

  void _openDetail(Map<String, dynamic> lot) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ParkingLotDetailScreen(
      name: lot['name'], address: lot['address'], availableSlots: lot['slots'],
      totalSlots: 120, pricePerHour: lot['price'], imagePath: lot['image'],
      latitude: lot['lat'], longitude: lot['lng'],
    )));
  }
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> lot;
  final VoidCallback onTap;
  const _SearchResultTile({required this.lot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.local_parking_rounded, color: AppColors.secondary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lot['name'], style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(lot['address'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${lot['slots']} spots', style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(lot['price'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
      ])),
    );
  }
}
