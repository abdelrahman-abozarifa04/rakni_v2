import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/google_maps_loader.dart';

/// Builds [child] (a GoogleMap) only once the Maps SDK is loaded.
/// Shows a spinner while loading and a retry message if it can't load.
class MapsReady extends StatefulWidget {
  final Widget child;

  const MapsReady({super.key, required this.child});

  @override
  State<MapsReady> createState() => _MapsReadyState();
}

class _MapsReadyState extends State<MapsReady> {
  late Future<bool> _ready = ensureGoogleMapsLoaded();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _ready,
      builder: (context, snap) {
        if (snap.data == true) return widget.child;

        return Container(
          color: AppColors.surface,
          alignment: Alignment.center,
          child: snap.connectionState != ConnectionState.done
              ? CircularProgressIndicator(color: AppColors.accent)
              : TextButton.icon(
                  onPressed: () =>
                      setState(() => _ready = ensureGoogleMapsLoaded()),
                  icon: Icon(Icons.refresh, color: AppColors.textSecondary),
                  label: Text(
                    'Map unavailable — tap to retry',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
        );
      },
    );
  }
}
