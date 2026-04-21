import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                debugPrint('Barcode found! ${barcode.rawValue}');
                // Handle successful scan
              }
            },
          ),
          
          // Overlay
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),
                const Spacer(),
                
                // Scanner Frame
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // Corner bits for precision look
                      _buildCorner(0, 0),
                      _buildCorner(1, 0),
                      _buildCorner(0, 1),
                      _buildCorner(1, 1),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                Text(
                  'ALIGN QR CODE WITHIN FRAME',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                
                // Bottom Info
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            'HQ MAN ENTRANCE',
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
                            'PRECISION-SCAN v2.1',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
