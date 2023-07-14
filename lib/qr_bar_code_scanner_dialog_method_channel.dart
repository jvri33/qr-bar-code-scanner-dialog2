import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'qr_bar_code_scanner_dialog_platform_interface.dart';

/// An implementation of [QrBarCodeScannerDialogPlatform] that uses method channels.
class MethodChannelQrBarCodeScannerDialog
    extends QrBarCodeScannerDialogPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('qr_bar_code_scanner_dialog');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  void scanBarOrQrCode(
      {BuildContext? context, required Function(String? code) onScanSuccess}) {
    /// context is required to show alert in non-web platforms
    assert(context != null);

    showGeneralDialog(pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
        context: context!,
        transitionBuilder: (BuildContext context, a1, a2, w) {
            final curvedAnimation = CurvedAnimation(
            parent: a1,
            curve: Curves.fastOutSlowIn);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
            child: Container(
              alignment: Alignment.center,
              child: Container(
                height: 400,
                width: 600,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 228, 253, 240),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(0)),
                ),
                child: ScannerWidget(onScanSuccess: (code) {
                  if (code != null) {
                    Navigator.pop(context);
                    onScanSuccess(code);
               }
                }),
              ))),
            );});
  
}

class ScannerWidget extends StatefulWidget {
  final void Function(String? code) onScanSuccess;

  const ScannerWidget({super.key, required this.onScanSuccess});

  @override
  createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  QRViewController? controller;
  GlobalKey qrKey = GlobalKey(debugLabel: 'scanner');

  bool isScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    /// dispose the controller
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildQrView(context),
          ),
        ),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(0, 115, 99, 1)),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancelar"),
        ),
      ],
    );
  }

  Widget _buildQrView(BuildContext context) {
    double smallestDimension = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    smallestDimension = min(smallestDimension, 550);

    return QRView(
      key: qrKey,
      onQRViewCreated: (controller) {
        _onQRViewCreated(controller);
      },
      overlay: QrScannerOverlayShape(
          borderColor: Colors.black,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: smallestDimension - 140),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((Barcode scanData) async {
      if (!isScanned) {
        isScanned = true;
        widget.onScanSuccess(scanData.code);
      }
    });
  }
}
