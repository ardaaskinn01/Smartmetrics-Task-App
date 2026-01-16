import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/service_locator.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        
        final result = await ServiceLocator.qrService.verifyQr(code);
        
        if (!mounted) return;

        await _showResultDialog(result);
        
        setState(() => _isProcessing = false);
        return; 
      }
    }
  }

  Future<void> _showResultDialog(Map<String, dynamic> result) async {
    final bool success = result['success'];
    final int? statusCode = result['statusCode'];
    final String message = result['message'] ?? (success ? 'İşlem Başarılı!' : 'İşlem Başarısız');
    
    Color color;
    IconData icon;
    String title;

    if (success) {
      color = Colors.green;
      icon = Icons.check_circle;
      title = "Başarılı";
    } else {
      if (statusCode == 409) {
        color = Colors.orange;
        icon = Icons.warning;
        title = "Kullanılmış Kod";
      } else if (statusCode == 404) {
        color = Colors.red;
        icon = Icons.error;
        title = "Kod Bulunamadı";
      } else {
        color = Colors.redAccent;
        icon = Icons.error_outline;
        title = "Hata";
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
        content: Text(
          message, 
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Tara'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: colorScheme.secondary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Kodu kare içine hizalayın',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
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
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10.0,
    this.overlayColor = const Color(0x88000000),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(Rect.fromLTWH(
          rect.left, rect.top, rect.width, rect.height))
      ..addRect(Rect.fromLTWH(
          rect.left + 10, rect.top + 10, rect.width - 20, rect.height - 20))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;
    final left = width / 2 - cutOutWidth / 2;
    final top = height / 2 - cutOutHeight / 2 - cutOutBottomOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromLTWH(
      left,
      top,
      cutOutWidth,
      cutOutHeight,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    
    path.moveTo(left, top + borderLength);
    path.lineTo(left, top + borderRadius);
    path.arcToPoint(Offset(left + borderRadius, top), radius: Radius.circular(borderRadius));
    path.lineTo(left + borderLength, top);

    path.moveTo(left + cutOutWidth - borderLength, top);
    path.lineTo(left + cutOutWidth - borderRadius, top);
    path.arcToPoint(Offset(left + cutOutWidth, top + borderRadius), radius: Radius.circular(borderRadius));
    path.lineTo(left + cutOutWidth, top + borderLength);

    path.moveTo(left + cutOutWidth, top + cutOutHeight - borderLength);
    path.lineTo(left + cutOutWidth, top + cutOutHeight - borderRadius);
    path.arcToPoint(Offset(left + cutOutWidth - borderRadius, top + cutOutHeight), radius: Radius.circular(borderRadius));
    path.lineTo(left + cutOutWidth - borderLength, top + cutOutHeight);

    path.moveTo(left + borderLength, top + cutOutHeight);
    path.lineTo(left + borderRadius, top + cutOutHeight);
    path.arcToPoint(Offset(left, top + cutOutHeight - borderRadius), radius: Radius.circular(borderRadius));
    path.lineTo(left, top + cutOutHeight - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
