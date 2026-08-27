import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class WorkspaceSettingsScreen extends ConsumerStatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  ConsumerState<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends ConsumerState<WorkspaceSettingsScreen> {
  final MapController _mapController = MapController();
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  double _geofenceRadius = 200.0;
  String _checkInTime = "09:00";
  String _checkOutTime = "18:00";

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Load existing settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final org = ref.read(authNotifierProvider).organization;
      if (org != null) {
        setState(() {
          _latController.text = org.officeLatitude?.toString() ?? "23.8103";
          _lngController.text = org.officeLongitude?.toString() ?? "90.4125";
          _geofenceRadius = org.geofenceRadius ?? 200.0;
          _checkInTime = org.checkInStartHour ?? "09:00";
          _checkOutTime = org.checkOutStartHour ?? "18:00";
        });
      }
    });
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on your phone.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable in Settings.')),
          );
        }
        return;
      }

      debugPrint("Geolocator: Permissions and service verified. Fetching current location...");
      
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 7),
          ),
        );
        debugPrint("Geolocator: Successfully fetched position: ${position.latitude}, ${position.longitude}");
      } catch (gpsError) {
        debugPrint("Geolocator Error during getCurrentPosition: $gpsError. Attempting fallback to getLastKnownPosition...");
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          debugPrint("Geolocator: Fallback succeeded with last known position: ${position.latitude}, ${position.longitude}");
        } else {
          debugPrint("Geolocator: Fallback failed. Last known position was null.");
          rethrow;
        }
      }

      setState(() {
        _latController.text = position!.latitude.toString();
        _lngController.text = position.longitude.toString();
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current GPS coordinates fetched successfully!')),
        );
      }
    } catch (e, stack) {
      debugPrint("Geolocator Final Exception: $e");
      debugPrint("Geolocator Stacktrace: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isCheckIn) async {
    final initialString = isCheckIn ? _checkInTime : _checkOutTime;
    final parts = initialString.split(":");
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        final formattedString = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        if (isCheckIn) {
          _checkInTime = formattedString;
        } else {
          _checkOutTime = formattedString;
        }
      });
    }
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final lat = double.tryParse(_latController.text) ?? 23.8103;
      final lng = double.tryParse(_lngController.text) ?? 90.4125;

      final success = await ref.read(authNotifierProvider.notifier).updateOrganizationSettings(
            lat,
            lng,
            _geofenceRadius,
            _checkInTime,
            _checkOutTime,
          );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workspace Settings updated successfully.'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(authNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to update settings.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Workspace Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Office GPS Coordinates',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: 'e.g. 23.8103',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: 'e.g. 90.4125',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLocating)
                    const Center(child: CircularProgressIndicator())
                  else
                    OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Get Current Location'),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Builder(
                        builder: (context) {
                          final double lat = double.tryParse(_latController.text) ?? 23.8103;
                          final double lng = double.tryParse(_lngController.text) ?? 90.4125;
                          
                          return FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15.0,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _latController.text = point.latitude.toStringAsFixed(6);
                                  _lngController.text = point.longitude.toStringAsFixed(6);
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.saas.ems.saas_ems',
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: LatLng(lat, lng),
                                    radius: _geofenceRadius,
                                    useRadiusInMeter: true,
                                    color: Colors.blue.withOpacity(0.15),
                                    borderColor: Colors.blue,
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Geofence Radius
                  Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Geofencing Radius (${_geofenceRadius.round()} meters)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _geofenceRadius,
                    min: 50.0,
                    max: 1000.0,
                    divisions: 19,
                    label: '${_geofenceRadius.round()}m',
                    onChanged: (val) {
                      setState(() {
                        _geofenceRadius = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Office Timing Hours
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Standard Office Hours',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text('Check-In Time: $_checkInTime'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text('Check-Out Time: $_checkOutTime'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Workspace Settings'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
