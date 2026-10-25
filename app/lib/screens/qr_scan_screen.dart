import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/strings.dart';

/// Result of a scanned Wi-Fi QR code (the standard `WIFI:S:...;T:...;P:...;;`
/// format used by router stickers and Android/iOS "share Wi-Fi" QR codes).
class WifiQrResult {
  final String ssid;
  final String password;
  const WifiQrResult({required this.ssid, required this.password});
}

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final result = _parseWifiQr(raw);
      if (result != null) {
        _handled = true;
        Navigator.of(context).pop(result);
        return;
      }
    }
  }

  /// Parses the standard `WIFI:S:<ssid>;T:<WPA|WEP|nopass>;P:<password>;;`
  /// format. Handles backslash-escaped `;`, `,`, `:`, `\` inside fields.
  static WifiQrResult? _parseWifiQr(String raw) {
    if (!raw.startsWith('WIFI:')) return null;
    final body = raw.substring(5);

    String? ssid;
    String password = '';
    final buffer = StringBuffer();
    String? currentKey;
    var i = 0;
    while (i < body.length) {
      final ch = body[i];
      if (ch == r'\' && i + 1 < body.length) {
        buffer.write(body[i + 1]);
        i += 2;
        continue;
      }
      if (ch == ':' && currentKey == null && buffer.isEmpty) {
        i++;
        continue;
      }
      if (currentKey == null && ch != ';') {
        currentKey = ch;
        i++;
        if (i < body.length && body[i] == ':') i++;
        continue;
      }
      if (ch == ';') {
        final value = buffer.toString();
        if (currentKey == 'S') ssid = value;
        if (currentKey == 'P') password = value;
        buffer.clear();
        currentKey = null;
        i++;
        continue;
      }
      buffer.write(ch);
      i++;
    }

    if (ssid == null || ssid.isEmpty) return null;
    return WifiQrResult(ssid: ssid, password: password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.qrScanTitle)),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                S.qrScanHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
