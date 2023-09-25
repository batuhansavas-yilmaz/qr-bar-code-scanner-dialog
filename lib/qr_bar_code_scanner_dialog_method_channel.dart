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
    showCupertinoDialog(
        barrierDismissible: true,
        context: context!,
        builder: (context) {
          return ResponsiveScaledBox(
            width: 450,
            child: Container(
              alignment: Alignment.center,
              child: Card(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white, width: 0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                color: Colors.white,
                elevation: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 400,
                  width: 400,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(2),
                  child: ScannerWidget(onScanSuccess: (code) {
                    if (code != null) {
                      Navigator.pop(context);
                      onScanSuccess(code);
                    }
                  }),
                ),
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

  bool isPressedFlash = false;
  bool isPressed2Camera = false;
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
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(child: child, scale: animation);
                },
                child: Icon(
                  isPressed2Camera ? Icons.camera_front : Icons.camera_rear,
                  key: ValueKey<bool>(isPressed2Camera),
                ),
              ),
              onPressed: () async {
                await controller!.flipCamera();
                setState(() {
                  isPressed2Camera = !isPressed2Camera;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(CupertinoIcons.stop),
            ),
            IconButton(
              onPressed: () async {
                await controller!.toggleFlash();
                setState(() {
                  isPressedFlash = !isPressedFlash;
                });
              },
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(child: child, scale: animation);
                },
                child: Icon(
                  isPressedFlash
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: isPressedFlash ? Colors.yellow : Colors.grey,
                  key: ValueKey<bool>(isPressedFlash),
                ),
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
          borderColor: Color.fromARGB(255, 255, 0, 0),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 6,
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
