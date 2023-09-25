import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:responsive_framework/responsive_framework.dart';

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
/**
 * Container(
              alignment: Alignment.center,
              child: Container(
                height: 400,
                width: 600,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ScannerWidget(onScanSuccess: (code) {
                  if (code != null) {
                    Navigator.pop(context);
                    onScanSuccess(code);
                  }
                }),
              ),
            ))
 */
    showCupertinoDialog(
        barrierDismissible: true,
        context: context!,
        builder: (context) {
          return ResponsiveScaledBox(
            width: 450,
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              elevation: 1,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 600,
                    width: 600,
                    child: ScannerWidget(onScanSuccess: (code) {
                      if (code != null) {
                        Navigator.pop(context);
                        onScanSuccess(code);
                      }
                    }),
                  ),
                ],
              ),
            ),
          );
        });
  }
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

  bool isPressed = false;
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Stop Scanning"),
            ),
            IconButton(
              onPressed: () async {
                await controller!.toggleFlash();
                setState(() {
                  isPressed = !isPressed;
                });
              },
              icon: isPressed
                  ? Icon(
                      Icons.flash_on_rounded,
                      color: Colors.yellow,
                    )
                  : Icon(
                      Icons.flash_off_rounded,
                      color: Colors.grey,
                    ),
            ),
          ],
        )
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
