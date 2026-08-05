import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:receipt_fold/common/utils.dart';

double _translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x *
          canvasSize.width /
          (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation270deg:
      return canvasSize.width -
          x *
              canvasSize.width /
              (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        default:
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

double _translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y *
          canvasSize.height /
          (Platform.isIOS ? imageSize.height : imageSize.width);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}

class BarcodeDetectorPainter extends CustomPainter {
  final List<Barcode> barcodes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  const BarcodeDetectorPainter(
    this.barcodes,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = Color(0x99000000);

    for (final Barcode barcode in barcodes) {
      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: 16,
          textDirection: TextDirection.ltr,
        ),
      );
      builder.pushStyle(
        ui.TextStyle(color: Colors.lightGreenAccent, background: background),
      );
      builder.addText('${barcode.displayValue}');
      builder.pop();

      final left = _translateX(
        barcode.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = _translateY(
        barcode.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = _translateX(
        barcode.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      // final bottom = translateY(
      //   barcode.boundingBox.bottom,
      //   size,
      //   imageSize,
      //   rotation,
      //   cameraLensDirection,
      // );
      //
      // // Draw a bounding rectangle around the barcode
      // canvas.drawRect(
      //   Rect.fromLTRB(left, top, right, bottom),
      //   paint,
      // );

      final List<Offset> cornerPoints = <Offset>[];
      for (final point in barcode.cornerPoints) {
        final double x = _translateX(
          point.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final double y = _translateY(
          point.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

        cornerPoints.add(Offset(x, y));
      }

      // Add the first point to close the polygon
      cornerPoints.add(cornerPoints.first);
      canvas.drawPoints(PointMode.polygon, cornerPoints, paint);

      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(width: (right - left).abs())),
        Offset(
          Platform.isAndroid && cameraLensDirection == CameraLensDirection.front
              ? right
              : left,
          top,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(BarcodeDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.barcodes != barcodes;
  }
}

class TextRecognizerPainter extends CustomPainter {
  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  const TextRecognizerPainter(
    this.recognizedText,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = Color(0x99000000);

    for (final textBlock in recognizedText.blocks) {
      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: 16,
          textDirection: TextDirection.ltr,
        ),
      );
      builder.pushStyle(
        ui.TextStyle(color: Colors.lightGreenAccent, background: background),
      );
      builder.addText(textBlock.text);
      builder.pop();

      final left = _translateX(
        textBlock.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = _translateY(
        textBlock.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = _translateX(
        textBlock.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      // final bottom = translateY(
      //   textBlock.boundingBox.bottom,
      //   size,
      //   imageSize,
      //   rotation,
      //   cameraLensDirection,
      // );
      //
      // canvas.drawRect(
      //   Rect.fromLTRB(left, top, right, bottom),
      //   paint,
      // );

      final List<Offset> cornerPoints = <Offset>[];
      for (final point in textBlock.cornerPoints) {
        double x = _translateX(
          point.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        double y = _translateY(
          point.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

        if (Platform.isAndroid) {
          switch (cameraLensDirection) {
            case CameraLensDirection.front:
              switch (rotation) {
                case InputImageRotation.rotation0deg:
                case InputImageRotation.rotation90deg:
                  break;
                case InputImageRotation.rotation180deg:
                  x = size.width - x;
                  y = size.height - y;
                  break;
                case InputImageRotation.rotation270deg:
                  x = _translateX(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  );
                  y =
                      size.height -
                      _translateY(
                        point.x.toDouble(),
                        size,
                        imageSize,
                        rotation,
                        cameraLensDirection,
                      );
                  break;
              }
              break;
            case CameraLensDirection.back:
              switch (rotation) {
                case InputImageRotation.rotation0deg:
                case InputImageRotation.rotation270deg:
                  break;
                case InputImageRotation.rotation180deg:
                  x = size.width - x;
                  y = size.height - y;
                  break;
                case InputImageRotation.rotation90deg:
                  x =
                      size.width -
                      _translateX(
                        point.y.toDouble(),
                        size,
                        imageSize,
                        rotation,
                        cameraLensDirection,
                      );
                  y = _translateY(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  );
                  break;
              }
              break;
            case CameraLensDirection.external:
              break;
          }
        }

        cornerPoints.add(Offset(x, y));
      }

      // Add the first point to close the polygon
      cornerPoints.add(cornerPoints.first);
      canvas.drawPoints(PointMode.polygon, cornerPoints, paint);

      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(width: (right - left).abs())),
        Offset(
          Platform.isAndroid && cameraLensDirection == CameraLensDirection.front
              ? right
              : left,
          top,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(TextRecognizerPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}

class CameraView extends StatefulWidget {
  final List<CustomPaint> customPaints;
  final Function(InputImage inputImage) onImage;
  final Widget Function(BuildContext, String) errorBuilder;
  final CameraLensDirection initialCameraLensDirection;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;

  const CameraView({
    super.key,
    required this.customPaints,
    required this.onImage,
    required this.errorBuilder,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.onCameraLensDirectionChanged,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  String? _errorMsg;
  CameraController? _controller;
  int _cameraIndex = -1;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      _cameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == widget.initialCameraLensDirection,
      );
      await _startLiveFeed();
    } catch (e) {
      _errorMsg = e.toString();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _stopLiveFeed();
  }

  @override
  Widget build(BuildContext context) {
    final isError = _errorMsg != null;
    final gettingCamera = _cameras.isEmpty;
    final isCameraInitialized = _controller?.value.isInitialized != true;
    if (isError || gettingCamera || isCameraInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Builder(
          builder: (context) {
            if (isError) return widget.errorBuilder(context, _errorMsg!);
            if (gettingCamera) return const SizedBox.shrink();
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }
    final bool isPortrait = Utils.isPortrait(context);
    final cameraHeight = _controller!.value.previewSize?.height;
    final cameraWidth = _controller!.value.previewSize?.width;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: isPortrait ? cameraHeight : cameraWidth,
          height: isPortrait ? cameraWidth : cameraHeight,
          child: CameraPreview(
            _controller!,
            child: Stack(fit: StackFit.expand, children: widget.customPaints),
          ),
        ),
      ),
    );
  }

  Future<void> _startLiveFeed() async {
    if (_cameraIndex < 0) return;
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await _controller?.initialize().then((_) async {
      if (!mounted) return;
      await _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = const {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // Validate format depending on platform
    const androidSupportedFormats = [
      InputImageFormat.nv21,
      InputImageFormat.yv12,
      InputImageFormat.yuv_420_888,
    ];

    if (format == null ||
        (Platform.isAndroid && !androidSupportedFormats.contains(format)) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    InputImageFormat resolvedFormat = format;
    final Uint8List bytes;

    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else if (Platform.isAndroid &&
        (format == InputImageFormat.yuv_420_888 ||
            format == InputImageFormat.yv12) &&
        image.planes.length == 3) {
      bytes = _convertYUV420ToNV21(image);
      resolvedFormat = InputImageFormat.nv21;
    } else {
      bytes = _concatenatePlanes(image);
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: resolvedFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // Reusable buffer to avoid per-frame allocations when concatenating planes.
  Uint8List? _reusablePlaneBuffer;

  Uint8List _concatenatePlanes(CameraImage image) {
    // Calculate the total number of bytes across all planes.
    final int totalBytes = image.planes.fold<int>(
      0,
      (int sum, Plane plane) => sum + plane.bytes.length,
    );

    // Ensure the reusable buffer is allocated and large enough.
    var buffer = _reusablePlaneBuffer;
    if (buffer == null || buffer.length < totalBytes) {
      buffer = Uint8List(totalBytes);
      _reusablePlaneBuffer = buffer;
    }

    // Copy each plane's bytes into the reusable buffer.
    var offset = 0;
    for (final Plane plane in image.planes) {
      final bytes = plane.bytes;
      buffer.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length;
    }

    // Return the reusable buffer directly when sizes match, or a zero-copy view otherwise.
    if (totalBytes == buffer.length) {
      return buffer;
    }
    return Uint8List.sublistView(buffer, 0, totalBytes);
  }

  Uint8List? _reusableNv21Buffer;
  int _lastNv21Size = 0;

  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;
    final int requiredSize = ySize + uvSize;

    if (_reusableNv21Buffer == null || _lastNv21Size != requiredSize) {
      _reusableNv21Buffer = Uint8List(requiredSize);
      _lastNv21Size = requiredSize;
    }

    final Uint8List nv21 = _reusableNv21Buffer!;

    // Copy Y plane (strip row padding)
    final Plane yPlane = image.planes[0];
    int destIndex = 0;
    for (int row = 0; row < height; row++) {
      final int srcRowStart = row * yPlane.bytesPerRow;
      nv21.setRange(destIndex, destIndex + width, yPlane.bytes, srcRowStart);
      destIndex += width;
    }

    // Interleave V and U planes into NV21 (VU order)
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    int uvIndex = ySize;
    for (int row = 0; row < height ~/ 2; row++) {
      final int uRowStart = row * uPlane.bytesPerRow;
      final int vRowStart = row * vPlane.bytesPerRow;

      for (int col = 0; col < width ~/ 2; col++) {
        final int uIndex = uRowStart + col * uvPixelStride;
        final int vIndex = vRowStart + col * vPixelStride;

        nv21[uvIndex++] = vPlane.bytes[vIndex];
        nv21[uvIndex++] = uPlane.bytes[uIndex];
      }
    }

    return nv21;
  }
}
