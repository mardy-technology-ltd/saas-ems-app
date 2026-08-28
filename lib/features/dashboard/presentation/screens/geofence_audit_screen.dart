import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../../../../core/services/attendance_service.dart';

class GeofenceAuditScreen extends ConsumerWidget {
  const GeofenceAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final org = authState.organization;
    final attendanceAsync = ref.watch(todayAttendanceStreamProvider);

    final officeLat = org?.officeLatitude ?? 23.8103;
    final officeLng = org?.officeLongitude ?? 90.4125;
    final radiusMeters = org?.geofenceRadius ?? 200.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Geofence Audit Log'),
      ),
      body: attendanceAsync.when(
        data: (records) {
          final insideCount = records.where((r) => r.isWithinGeofence).length;
          final outsideCount = records.where((r) => !r.isWithinGeofence).length;

          // Prepare map markers
          final markers = <Marker>[
            // Office Center Marker
            Marker(
              point: LatLng(officeLat, officeLng),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.business_rounded,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
          ];

          for (var r in records) {
            if (r.latitude != null && r.longitude != null) {
              markers.add(
                Marker(
                  point: LatLng(r.latitude!, r.longitude!),
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.location_on,
                    color: r.isWithinGeofence ? Colors.green : Colors.red,
                    size: 30,
                  ),
                ),
              );
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overview Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Inside Geofence',
                        value: '$insideCount',
                        icon: Icons.g_mobiledata_rounded,
                        color: Colors.green,
                        bgColor: Colors.green.shade50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Outside Geofence',
                        value: '$outsideCount',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                        bgColor: Colors.red.shade50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text('Live GPS Map Visualizer', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                // OpenStreetMap Tile View
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(officeLat, officeLng),
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.saas.ems.saas_ems',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(officeLat, officeLng),
                              radius: radiusMeters,
                              useRadiusInMeter: true,
                              color: Colors.blue.withOpacity(0.15),
                              borderColor: AppTheme.primaryColor,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Check-In Location Audit Records', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                if (records.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No attendance check-in records for today.',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: records.map((record) => _buildAuditRecordTile(record)).toList(),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading geofence audit: $e')),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAuditRecordTile(AttendanceRecord record) {
    final statusColor = record.isWithinGeofence ? Colors.green : Colors.red;
    final statusText = record.isWithinGeofence ? 'INSIDE GEOFENCE' : 'OUTSIDE GEOFENCE';
    final latStr = record.latitude?.toStringAsFixed(4) ?? '23.8103';
    final lngStr = record.longitude?.toStringAsFixed(4) ?? '90.4125';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(
            record.isWithinGeofence ? Icons.location_on : Icons.wrong_location,
            color: statusColor,
          ),
        ),
        title: Text(
          record.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checked In: ${record.checkInTime.hour}:${record.checkInTime.minute.toString().padLeft(2, '0')} • Status: ${record.status.toUpperCase()}',
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'GPS: Lat $latStr, Lng $lngStr',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
