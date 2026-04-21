import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme.dart';

class QrAuthScannerScreen extends StatefulWidget {
  const QrAuthScannerScreen({super.key});

  @override
  State<QrAuthScannerScreen> createState() => _QrAuthScannerScreenState();
}

class _QrAuthScannerScreenState extends State<QrAuthScannerScreen> {
  bool _isProcessing = false;

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;

    if (code.startsWith('AE_AUTH:')) {
      setState(() => _isProcessing = true);
      final token = code.split(':')[1];

      try {
        final result = await FirebaseFunctions.instance
            .httpsCallable('exchangeEmployeeLoginToken')
            .call({'token': token});

        final customToken = result.data['customToken'];
        
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired login token'),
              backgroundColor: AppColors.statusRed,
            ),
          );
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN LOGIN QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                }
              }
            },
          ),
          
          // Overlay
          IgnorePointer(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: AppColors.accent,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'ALIGN QR WITHIN THE FRAME',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final boxWidth = cutOutSize;
    final boxHeight = cutOutSize;
    final left = (width - boxWidth) / 2;
    final top = (height - boxHeight) / 2;

    final backgroundPaint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRect(Rect.fromLTWH(left, top, boxWidth, boxHeight)),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path()
      // Top Left
      ..moveTo(left, top + borderLength)
      ..lineTo(left, top)
      ..lineTo(left + borderLength, top)
      // Top Right
      ..moveTo(left + boxWidth - borderLength, top)
      ..lineTo(left + boxWidth, top)
      ..lineTo(left + boxWidth, top + borderLength)
      // Bottom Right
      ..moveTo(left + boxWidth, top + boxHeight - borderLength)
      ..lineTo(left + boxWidth, top + boxHeight)
      ..lineTo(left + boxWidth - borderLength, top + boxHeight)
      // Bottom Left
      ..moveTo(left + borderLength, top + boxHeight)
      ..lineTo(left, top + boxHeight)
      ..lineTo(left, top + boxHeight - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    borderLength: borderLength,
    cutOutSize: cutOutSize,
  );
}
