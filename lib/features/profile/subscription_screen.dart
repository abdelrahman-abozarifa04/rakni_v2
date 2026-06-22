import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/core/models/subscription_model.dart';
import 'package:rakni_v2/core/models/vehicle_model.dart';
import 'package:rakni_v2/core/models/user_model.dart';
import 'package:rakni_v2/core/services/firestore_service.dart';
import 'package:rakni_v2/core/services/parking_hardware_api_service.dart';
import 'package:rakni_v2/features/profile/my_vehicles_screen.dart';
import 'package:rakni_v2/features/profile/subscription_confirmation_dialog.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  UserModel? _userModel;
  List<VehicleModel> _vehicles = [];
  Subscription? _activeSubscription;
  VehicleModel? _selectedVehicleForSub;

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'monthly_premium',
      name: 'Monthly Premium',
      pricePerMonth: 150.0,
      dailyRate: 5.0,
      durationDays: 30,
      description: 'Ideal for daily commuters who want hassle-free entries.',
      features: [
        'Unlimited parking entries',
        'Priority parking spots',
        'Instant gate opening via AI Recognition',
        '24/7 Premium Support',
      ],
      type: SubscriptionType.MONTHLY,
    ),
    SubscriptionPlan(
      id: 'quarterly_saver',
      name: 'Quarterly Saver',
      pricePerMonth: 120.0, // 360 total
      dailyRate: 4.0,
      durationDays: 90,
      description: 'Save 20% compared to the monthly subscription.',
      features: [
        'Unlimited parking entries',
        'Priority parking spots',
        'Instant gate opening via AI Recognition',
        '15% discount on extra services',
        '24/7 Premium Support',
      ],
      type: SubscriptionType.QUARTERLY,
    ),
    SubscriptionPlan(
      id: 'annual_ultimate',
      name: 'Annual Ultimate',
      pricePerMonth: 90.0, // 1080 total
      dailyRate: 3.0,
      durationDays: 365,
      description: 'Our best value plan with the maximum discount.',
      features: [
        'Unlimited parking entries',
        'Priority parking spots',
        'Instant gate opening via AI Recognition',
        '30% discount on extra services',
        'Dedicated VIP Account Manager',
      ],
      type: SubscriptionType.YEARLY,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await FirestoreService.instance.getUserModel(uid);
      final vehiclesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .get();
      final vehicles = vehiclesSnap.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();

      final plates = vehicles.map((v) => v.plateNumber).toList();
      final activeSub = await ParkingHardwareApiService.instance
          .checkActiveSubscription(plates);

      setState(() {
        _userModel = user;
        _vehicles = vehicles;
        _activeSubscription = activeSub;
        if (_vehicles.isNotEmpty) {
          // Default to first vehicle, or the default one if set
          _selectedVehicleForSub = _vehicles.firstWhere(
            (v) => v.isDefault,
            orElse: () => _vehicles.first,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[SubscriptionScreen] Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSubscriptionSheet(SubscriptionPlan plan) {
    if (_userModel == null) return;
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a vehicle first before subscribing.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionConfirmationDialog(
        plan: plan,
        vehicle: _selectedVehicleForSub!,
        user: _userModel!,
      ),
    ).then((success) {
      if (success == true) {
        _loadData();
      }
    });
  }

  void _showCancelSubscriptionConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 10),
            Text(
              'Cancel Subscription',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your active subscription? '
          'Please note that you will immediately lose your remaining premium benefits, and no refunds will be issued for any unused days.',
          style: TextStyle(color: AppColors.white.withAlpha(180), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Plan',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelSubscription();
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    if (_activeSubscription == null) return;
    setState(() => _isLoading = true);
    try {
      final success = await ParkingHardwareApiService.instance
          .cancelSubscription(_activeSubscription!.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription canceled successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirestoreService.instance.sendAppNotification(
            uid,
            title: 'Subscription Canceled',
            body: 'Your premium subscription has been canceled.',
            type: 'subscription_canceled',
            settingKey: 'setting_push_notifications',
          );
        }
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel subscription. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[SubscriptionScreen] Error canceling subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Subscription',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _activeSubscription != null
                  ? _buildActiveState()
                  : _buildSubscribeState(),
            ),
    );
  }

  // ─── STATE B: ACTIVE SUBSCRIPTION ──────────────────────────────────────────
  Widget _buildActiveState() {
    final sub = _activeSubscription!;
    final totalDays = sub.endDate.difference(sub.startDate).inDays;
    final remainingDays = sub.endDate.difference(DateTime.now()).inDays;
    final percentRemaining = totalDays > 0 ? (remainingDays / totalDays).clamp(0.0, 1.0) : 0.0;

    // Find the corresponding plan details to list features
    final planDetails = _plans.firstWhere(
      (p) => p.type == sub.subscriptionType,
      orElse: () => _plans.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Header Badge
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondary.withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'RAKNI PREMIUM MEMBER',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Active Plan Detail Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.fieldStroke),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    planDetails.name,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Subscribed Vehicle: ${sub.plateNumber}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time Remaining',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$remainingDays days left',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentRemaining,
                  backgroundColor: AppColors.background,
                  color: AppColors.secondary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: AppColors.fieldStroke),
              const SizedBox(height: 16),
              _buildActiveInfoRow(
                Icons.calendar_today_outlined,
                'Start Date',
                '${sub.startDate.year}-${sub.startDate.month.toString().padLeft(2, '0')}-${sub.startDate.day.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 12),
              _buildActiveInfoRow(
                Icons.event_outlined,
                'Renewal Date',
                '${sub.endDate.year}-${sub.endDate.month.toString().padLeft(2, '0')}-${sub.endDate.day.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 12),
              _buildActiveInfoRow(
                Icons.payments_outlined,
                'Price Rate',
                '${sub.monthlyFee.toStringAsFixed(0)} EGP/month (Only ${(sub.monthlyFee / 30).toStringAsFixed(1)} EGP/day)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Benefits Title
        Text(
          'Your Premium Benefits',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // List Benefits
        ...planDetails.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    feature,
                    style: TextStyle(
                      color: AppColors.white.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _showCancelSubscriptionConfirmation,
            icon: const Icon(Icons.cancel_outlined, size: 20),
            label: const Text(
              'Cancel Subscription',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildActiveInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ─── STATE A: SUBSCRIBE OPTIONS ────────────────────────────────────────────
  Widget _buildSubscribeState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscribe to Rakni Premium',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock priority slots, automatic entry/exit scanners, and special daily rates.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Vehicle Selector
        if (_vehicles.isNotEmpty) ...[
          Text(
            'Select Vehicle for Subscription',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fieldStroke),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VehicleModel>(
                value: _selectedVehicleForSub,
                dropdownColor: AppColors.surface,
                icon: Icon(Icons.keyboard_arrow_down, color: AppColors.white),
                style: TextStyle(color: AppColors.white, fontSize: 15),
                isExpanded: true,
                onChanged: (VehicleModel? newVehicle) {
                  if (newVehicle != null) {
                    setState(() => _selectedVehicleForSub = newVehicle);
                  }
                },
                items: _vehicles.map((v) {
                  return DropdownMenuItem<VehicleModel>(
                    value: v,
                    child: Text(
                      '${v.brand} ${v.model} (${v.plateNumber})',
                      style: TextStyle(color: AppColors.white),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ] else ...[
          // No vehicles warning
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(
                      'No Vehicles Found',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'You must register at least one vehicle in your profile before you can purchase a subscription.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyVehiclesScreen()),
                      ).then((_) => _loadData());
                    },
                    child: const Text(
                      'Add Vehicle Now',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Plans list
        ..._plans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final hasVehicle = _vehicles.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fieldStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Only ${plan.dailyRate.toStringAsFixed(0)} EGP/day',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.fieldStroke),
          const SizedBox(height: 16),

          // Features
          ...plan.features.map((feat) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      feat,
                      style: TextStyle(color: AppColors.white.withAlpha(180), fontSize: 13),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: hasVehicle ? () => _showSubscriptionSheet(plan) : null,
              child: Text(
                'Subscribe for ${plan.pricePerMonth.toStringAsFixed(0)} EGP/mo',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
