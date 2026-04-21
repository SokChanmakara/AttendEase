import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme.dart';
import '../attendance_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  String _statusText = 'ALIGN QR CODE WITHIN FRAME';
  String _locationLabel = '-';

  Future<void> _handleBarcode(String value) async {
    if (_isProcessing) return;

    final payload = AttendanceService.parseAttendanceQr(value);
    if (payload == null) {
      _showError('Invalid attendance QR.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'VALIDATING LOCATION...';
      _locationLabel = payload.locationId;
    });

    try {
      final employeeContext = await AttendanceService.loadEmployeeContext();
      if (employeeContext.companyId != payload.companyId) {
        throw FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Scanned QR belongs to a different company.',
        );
      }

      final position = await _resolvePosition();
      try {
        await AttendanceService.checkOut(companyId: employeeContext.companyId);
        _showSuccess('Checked out successfully.');
      } on FirebaseFunctionsException catch (e) {
        if (e.code != 'not-found') {
          rethrow;
        }
        await AttendanceService.checkIn(
          payload: payload,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyM: position.accuracy,
          isMockLocation: position.isMocked,
        );
        _showSuccess('Checked in successfully.');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseFunctionsException catch (e) {
      _showError(e.message ?? 'Attendance action failed.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'ALIGN QR CODE WITHIN FRAME';
        });
      }
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required for attendance.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.statusRed),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.statusGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  _handleBarcode(value);
                  break;
                }
              }
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'QR SCANNER',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      _buildCorner(0, 0),
                      _buildCorner(1, 0),
                      _buildCorner(0, 1),
                      _buildCorner(1, 1),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  _statusText,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LOCATION',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _locationLabel.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SYSTEM',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _isProcessing ? 'PROCESSING' : 'READY',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black38,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(double x, double y) {
    return Positioned(
      left: x == 0 ? -2 : null,
      right: x == 1 ? -2 : null,
      top: y == 0 ? -2 : null,
      bottom: y == 1 ? -2 : null,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(x == 0 && y == 0 ? 4 : 0),
            topRight: Radius.circular(x == 1 && y == 0 ? 4 : 0),
            bottomLeft: Radius.circular(x == 0 && y == 1 ? 4 : 0),
            bottomRight: Radius.circular(x == 1 && y == 1 ? 4 : 0),
          ),
        ),
      ),
    );
  }
}
