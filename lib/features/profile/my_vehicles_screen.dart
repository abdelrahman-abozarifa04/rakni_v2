import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/utils/image_utils.dart';

// Fallback car assets cycled when the user has no uploaded image
const _kCarImages = [
  'assets/images/vehicles.png',
  'assets/images/car_ex_1.png',
  'assets/images/car_ex_2.png',
];

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  // Updated viewportFraction to 1.0 so the new card design fits properly
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;
  late Stream<List<VehicleModel>> _vehiclesStream;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _vehiclesStream = FirestoreService.instance.streamVehicles(_uid!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── Add Vehicle Bottom Sheet ────────────────────────────────────────────────

  void _showAddVehicleSheet() {
    final formKey = GlobalKey<FormState>();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    bool isSaving = false;
    XFile? pickedImage;
    bool showImageError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Vehicle',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Vehicle photo picker ──────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: ctx,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (sheetCtx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.photo_library_rounded,
                                  color: AppColors.secondary),
                              title: const Text('Choose from Gallery',
                                  style:
                                      TextStyle(color: AppColors.white)),
                              onTap: () => Navigator.pop(
                                  sheetCtx, ImageSource.gallery),
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt_rounded,
                                  color: AppColors.secondary),
                              title: const Text('Take a Photo',
                                  style:
                                      TextStyle(color: AppColors.white)),
                              onTap: () => Navigator.pop(
                                  sheetCtx, ImageSource.camera),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                    if (source == null) return;
                    final file = await ImagePicker()
                        .pickImage(source: source, imageQuality: 80);
                    if (file != null) {
                      setModalState(() {
                        pickedImage = file;
                        showImageError = false;
                      });
                    }
                  },
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: pickedImage != null
                            ? AppColors.secondary
                            : (showImageError
                                ? AppColors.error
                                : AppColors.fieldStroke),
                        width: pickedImage != null ? 1.5 : 1,
                      ),
                    ),
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(pickedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                color: AppColors.textSecondary,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                               const Text(
                                'Add Vehicle Photo (Optional)',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Form fields ──────────────────────────────────────────────
                _sheetField(brandCtrl, 'Brand  (e.g. Toyota)',
                    Icons.directions_car_outlined),
                const SizedBox(height: 12),
                _sheetField(
                    modelCtrl, 'Model  (e.g. Camry)', Icons.car_repair_outlined),
                const SizedBox(height: 12),
                _sheetField(plateCtrl, 'Plate Number', Icons.numbers_outlined,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Plate number is required' : null),
                const SizedBox(height: 12),
                _sheetField(colorCtrl, 'Color', Icons.color_lens_outlined),
                const SizedBox(height: 24),

                // ── Save button ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            // Removed mandatory image check
                            final uid = _uid;
                            if (uid == null) return;
                            setModalState(() => isSaving = true);
                            try {
                              final vehicle = VehicleModel(
                                id: '',
                                brand: brandCtrl.text.trim(),
                                model: modelCtrl.text.trim(),
                                plateNumber: plateCtrl.text.trim(),
                                color: colorCtrl.text.trim(),
                                isDefault: false,
                              );
                              await FirestoreService.instance
                                  .addVehicleWithImage(
                                uid,
                                vehicle,
                                imageFile: pickedImage,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vehicle added! 🚗'),
                                    backgroundColor: AppColors.secondary,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppColors.error),
                                );
                              }
                            } finally {
                              setModalState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5),
                          )
                        : const Text('Add Vehicle',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Vehicles',
          style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        actions: [
          GestureDetector(
            onTap: _showAddVehicleSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.secondary.withAlpha(80), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: AppColors.secondary, size: 16),
                  SizedBox(width: 4),
                  Text('Add',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        final uid = _uid;
        if (uid == null) {
          return const Center(
            child: Text('Not logged in',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return StreamBuilder<List<VehicleModel>>(
          stream: _vehiclesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.secondary),
              );
            }
            final vehicles = snapshot.data ?? [];

            if (vehicles.isEmpty) {
              return _EmptyState(onAdd: _showAddVehicleSheet);
            }

            return Column(
              children: [
                const SizedBox(height: 12),
                // ── Vehicle count + page dots ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        '${vehicles.length} vehicle${vehicles.length == 1 ? '' : 's'} registered',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(vehicles.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.secondary
                                  : AppColors.textSecondary.withAlpha(80),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Paged cards ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: vehicles.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      const fallback = 'assets/images/vehicles.png';
                      return _VehicleCard(
                        vehicle: v,
                        fallbackImagePath: fallback,
                        isActive: index == _currentPage,
                        onDelete: () => _confirmDelete(v),
                        onSetDefault:
                            v.isDefault ? null : () => _setDefault(v),
                      );
                    },
                  ),
                ),
                // ── Swipe hint ──
                if (vehicles.length > 1)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 24, top: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_rounded,
                            color: AppColors.textSecondary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Swipe to see all vehicles',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(VehicleModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Vehicle',
            style: TextStyle(color: AppColors.white)),
        content: Text(
          'Remove ${v.brand} ${v.model} (${v.plateNumber})?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final uid = _uid;
      if (uid == null) return;
      try {
        await FirestoreService.instance.deleteVehicle(uid, v.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vehicle removed'),
                backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _setDefault(VehicleModel v) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirestoreService.instance.setDefaultVehicle(uid, v.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.brand} ${v.model} set as default'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (_) {}
  }
}

// ─── Vehicle Card ────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final String fallbackImagePath;
  final bool isActive;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _VehicleCard({
    required this.vehicle,
    required this.fallbackImagePath,
    required this.isActive,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      // Wrap in Align so the PageView doesn't force it to stretch vertically
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, Color(0xFF2F3030)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isActive
                    ? AppColors.secondary.withAlpha(80)
                    : AppColors.fieldStroke,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(30),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: Column(
              // This is the magic property that makes the card tightly wrap its content!
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: brand + default badge ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.brand} ${vehicle.model}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (vehicle.color.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  vehicle.color,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (vehicle.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Car image: user upload OR fallback asset ──
                // Replaced 'Expanded' with a fixed height SizedBox
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 180, // Fixed height keeps the image contained
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: vehicle.imageUrl != null
                          ? (ImageUtils.isBase64Image(vehicle.imageUrl!)
                              ? Image.memory(
                                  ImageUtils.base64ToBytes(vehicle.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    fallbackImagePath,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.network(
                                  vehicle.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    fallbackImagePath,
                                    fit: BoxFit.contain,
                                  ),
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                            : null,
                                        color: AppColors.secondary,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                ))
                          : Image.asset(
                              fallbackImagePath,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),

                // ── Plate Number Badge ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.secondary.withAlpha(120),
                          width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text('🅿',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          vehicle.plateNumber,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Action buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Row(
                    children: [
                      if (onSetDefault != null)
                        Expanded(
                          child: _ActionButton(
                            label: 'Set Default',
                            icon: Icons.star_outline_rounded,
                            color: AppColors.secondary,
                            onTap: onSetDefault!,
                          ),
                        ),
                      if (onSetDefault != null) const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Remove',
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          onTap: onDelete,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(80)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/vehicles.png',
              width: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Vehicles Yet',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add your car to start booking parking spots easily.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Your Vehicle',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}