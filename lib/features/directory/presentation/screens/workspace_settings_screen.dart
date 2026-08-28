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

  void _showUploadLogoModal(BuildContext context) {
    final urlController = TextEditingController(text: ref.read(authNotifierProvider).organization?.logoUrl ?? '');
    String selectedPreset = urlController.text;

    final List<Map<String, String>> presets = [
      {'name': 'Tech Corp', 'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150'},
      {'name': 'Innovate', 'url': 'https://images.unsplash.com/photo-1599305445671-ac291c95aaa9?w=150'},
      {'name': 'EMS Global', 'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150'},
      {'name': 'Creative Studio', 'url': 'https://images.unsplash.com/photo-1572021335469-31706a17aaef?w=150'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Company Logo & Branding',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter a image URL or choose a preset logo for your organization',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Live Logo Preview
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: selectedPreset.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                selectedPreset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.business_rounded,
                                  size: 40,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : const Icon(Icons.business_rounded, size: 40, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image URL Input
                  TextFormField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Logo Image URL',
                      hintText: 'https://example.com/logo.png',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        selectedPreset = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Logo Preset:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presets.map((preset) {
                        final isSelected = selectedPreset == preset['url'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              urlController.text = preset['url']!;
                              selectedPreset = preset['url']!;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    preset['url']!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.business, size: 30),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset['name']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final url = urlController.text.trim();
                      if (url.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid logo URL or select a preset.')),
                        );
                        return;
                      }

                      await ref.read(authNotifierProvider.notifier).updateOrganizationLogo(url);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Company logo updated successfully!'),
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Company Logo'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final org = authState.organization;

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
                  // Company Logo & Branding Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                          ),
                          child: org?.logoUrl != null && org!.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    org.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.business_rounded, color: AppTheme.primaryColor),
                                  ),
                                )
                              : const Icon(Icons.business_rounded, color: AppTheme.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                org?.name ?? 'Company Branding',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text(
                                'Organization Logo & Thumbnail',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _showUploadLogoModal(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Change Logo', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
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
