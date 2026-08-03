import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/entity/recognized_invoice.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_scanner_widgets.dart';

/// ASCII "*"
const int _asterisk = 0x2A;

class TabScannerView extends StatefulWidget {
  final InvoicePrizeSearcher searcher;

  const TabScannerView({super.key, required this.searcher});

  @override
  State<TabScannerView> createState() => _TabScannerViewState();
}

class _TabScannerViewState extends State<TabScannerView>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  InvoicePrizeAward? _invoiceAward;
  InvoicePrize? _invoicePrize;
  late final _barcodeScanner = BarcodeScanner(
    formats: const [BarcodeFormat.qrCode],
  );
  late final _textRecognizer = TextRecognizer();
  final _isCameraOpen = ValueNotifier(false);
  bool _isLockOrient = false;
  bool _isLastTimeOnView = false;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.back;
  bool _isProcessingImage = false;
  CustomPaint? _customPaintBarcode;
  CustomPaint? _customPaintText;
  (Receipt, List<ReceiptProduct>)? _receiptResult;
  bool _isSaved = false;
  bool _isProcessingSave = false;
  Future<void> Function()? _latestSaveQueued;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _setCameraOpen(false);
    _setOrientationLock(false);
    _barcodeScanner.close();
    _textRecognizer.close();
    _audioPlayer.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _setCameraOpen(true);
    if (state == AppLifecycleState.inactive) _setCameraOpen(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewEntryExitEvent(context.watch<MenuNavBarProvider>().onScanner);
  }

  Future<void> _viewEntryExitEvent(bool onScanner) async {
    if (onScanner && !_isLastTimeOnView) {
      _isLastTimeOnView = true;
      final bool isScanLockOrient = context.readPrefs.get(.isScanLockOrient);
      _setCameraOpen(true);
      await _setOrientationLock(isScanLockOrient);
    } else if (!onScanner && _isLastTimeOnView) {
      _isLastTimeOnView = false;
      _setCameraOpen(false);
      await _setOrientationLock(false);
    }
  }

  void _setCameraOpen(bool toOpen) => _isCameraOpen.value = toOpen;

  Future<void> _setOrientationLock(bool toLock) async {
    if (_isLockOrient == toLock) return;
    if (toLock) {
      await Utils.lockOrientation(
        context: context,
        orientation: (await NativeDeviceOrientationCommunicator().orientation())
            .deviceOrientation,
      );
    } else if (_isLockOrient) {
      await Utils.unlockOrientation();
    }
    _isLockOrient = toLock;
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!mounted || _isProcessingImage) return;
    _isProcessingImage = true;
    try {
      final sourceBarcodes = await _barcodeScanner.processImage(inputImage);
      final sourceTexts = await _textRecognizer.processImage(inputImage);
      if (inputImage.metadata == null) {
        _customPaintBarcode = null;
        _customPaintText = null;
      } else {
        final (resultBarcodes, resultTexts) = _verifyRecognized(
          sourceBarcodes,
          sourceTexts,
        );
        _customPaintBarcode = CustomPaint(
          painter: BarcodeDetectorPainter(
            resultBarcodes,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _cameraLensDirection,
          ),
        );
        _customPaintText = CustomPaint(
          painter: TextRecognizerPainter(
            resultTexts,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _cameraLensDirection,
          ),
        );
      }
    } finally {
      _isProcessingImage = false;
      if (mounted) setState(() {});
    }
  }

  (List<Barcode>, RecognizedText) _verifyRecognized(
    List<Barcode> sourceBarcodes,
    RecognizedText sourceRecognizedText,
  ) {
    final recognizedInvoice = RecognizedInvoice();
    bool isRecognizedValid = true;

    final resultRecognizedText = RecognizedText(
      text: sourceRecognizedText.text,
      blocks: [],
    );
    for (final block in sourceRecognizedText.blocks) {
      bool acceptedDisplay = false;
      for (final line in block.lines.map((line) => line.text)) {
        final mNumber = RecognizedInvoice.rNumber.firstMatch(line);
        if (mNumber != null) {
          isRecognizedValid &= recognizedInvoice.invoiceNumber == null;
          recognizedInvoice.invoiceNumber =
              '${mNumber.group(1)!}${mNumber.group(2)!}';
          acceptedDisplay = true;
          continue;
        }
        for (final text in line.split(' ')) {
          final mYYYYmmDD = RecognizedInvoice.rYYYYmmDD.firstMatch(text);
          final mRRRmmDD = RecognizedInvoice.rRRRmmDD.firstMatch(text);
          final mHHmmSS = RecognizedInvoice.rHHmmSS.firstMatch(text);
          final mHHmm = RecognizedInvoice.rHHmm.firstMatch(text);
          acceptedDisplay |=
              (mYYYYmmDD ?? mRRRmmDD ?? mHHmmSS ?? mHHmm) != null;
          if (mYYYYmmDD != null) {
            isRecognizedValid &= recognizedInvoice.yearMonthDay == null;
            recognizedInvoice.yearMonthDay = (
              mYYYYmmDD.group(1)!,
              mYYYYmmDD.group(2)!,
              mYYYYmmDD.group(3)!,
            );
          } else if (mRRRmmDD != null) {
            isRecognizedValid &= recognizedInvoice.yearMonthDay == null;
            recognizedInvoice.yearMonthDay = (
              mRRRmmDD.group(1)!,
              mRRRmmDD.group(2)!,
              mRRRmmDD.group(3)!,
            );
          } else if (mHHmmSS != null) {
            isRecognizedValid &= recognizedInvoice.hourMinuteSecond == null;
            recognizedInvoice.hourMinuteSecond = (
              mHHmmSS.group(1)!,
              mHHmmSS.group(2)!,
              mHHmmSS.group(3)!,
            );
          } else if (mHHmm != null) {
            isRecognizedValid &= recognizedInvoice.hourMinuteSecond == null;
            recognizedInvoice.hourMinuteSecond = (
              mHHmm.group(1)!,
              mHHmm.group(2)!,
              '00',
            );
          }
        }
      }
      if (acceptedDisplay) resultRecognizedText.blocks.add(block);
    }

    final resultBarcodes = <Barcode>[];
    Uint8List? leftUint8List;
    Uint8List? rightUint8List;
    for (final barcode in sourceBarcodes) {
      final rawBytes = barcode.rawBytes;
      bool acceptedDisplay = false;
      if (rawBytes == null || rawBytes.length < 2) continue;
      if (rawBytes[0] == _asterisk && rawBytes[1] == _asterisk) {
        acceptedDisplay = true;
        isRecognizedValid &= rightUint8List == null;
        rightUint8List = rawBytes;
      } else if (rawBytes.length >= 77) {
        acceptedDisplay = true;
        isRecognizedValid &= leftUint8List == null;
        leftUint8List = rawBytes;
      }
      if (acceptedDisplay) resultBarcodes.add(barcode);
    }

    isRecognizedValid &= !((leftUint8List == null) ^ (rightUint8List == null));
    if (leftUint8List != null && rightUint8List != null) {
      try {
        recognizedInvoice.qrCodeInvoice = QrCodeInvoice.parse(
          Uint8List.fromList([...leftUint8List, ...rightUint8List.sublist(2)]),
        );
      } catch (e) {
        debugPrint('$QrCodeInvoice.parse: $e');
        isRecognizedValid = false;
      }
    }

    _checkNeedUpdate(isRecognizedValid ? recognizedInvoice : null);
    return (resultBarcodes, resultRecognizedText);
  }

  void _checkNeedUpdate(RecognizedInvoice? recognizedInvoice) {
    if (recognizedInvoice == null) return;
    final receiptResult = recognizedInvoice.receiptResult();
    if (receiptResult == null) return;
    final (receipt, products) = receiptResult;
    final lastReceiptResult = _receiptResult;
    var lastReceipt = lastReceiptResult?.$1;
    var lastProducts = lastReceiptResult?.$2;
    if (lastReceipt == null ||
        receipt.invoiceNumber != lastReceipt.invoiceNumber) {
      Utils.deviceVibrate();
      Utils.audioPlayBeep(_audioPlayer);
      unawaited(_refreshPrize(receipt));
      unawaited(_processUpdate(receiptResult));
      return;
    }
    if (recognizedInvoice.qrCodeInvoice != null) {
      lastReceipt = lastReceipt.copyWith(
        randomNumber: Value(receipt.randomNumber),
        totalAmount: receipt.totalAmount,
        sellerTaxId: Value(receipt.sellerTaxId),
        sellerRemark: Value(receipt.sellerRemark),
      );
      lastProducts = products;
    }
    if ((recognizedInvoice.yearMonthDay ??
            recognizedInvoice.hourMinuteSecond) !=
        null) {
      lastReceipt = lastReceipt.copyWith(issuedAt: receipt.issuedAt);
    }
    if (lastReceiptResult?.$1 == lastReceipt) return;
    unawaited(_processUpdate((lastReceipt, lastProducts!)));
  }

  Future<void> _refreshPrize(Receipt receipt) async {
    _invoiceAward = await widget.searcher.getPrizeAward(
      Period(receipt.issuedAt),
    );
    _invoicePrize = _invoiceAward?.checkAll(receipt.invoiceNumber);
    if (mounted) setState(() {});
    if (_invoicePrize != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      await Utils.deviceVibrate();
      await Utils.audioPlayBeep(_audioPlayer);
    }
  }

  Future<void> _processUpdate([
    (Receipt, List<ReceiptProduct>)? receiptResult,
  ]) async {
    if (receiptResult != null) _receiptResult = receiptResult;
    _isSaved = false;
    if (mounted) setState(() {});
    if (receiptResult == null || context.readPrefs.get<bool>(.isScanAutoAdd)) {
      receiptResult ??= _receiptResult;
      if (receiptResult == null) return;
      _latestSaveQueued = () => _saveReceipt(receiptResult!);
      _isSaved = true;
      if (mounted) setState(() {});
      if (_isProcessingSave) return;
      _isProcessingSave = true;
      try {
        while (_latestSaveQueued != null) {
          final saveTask = _latestSaveQueued;
          _latestSaveQueued = null;
          await saveTask?.call();
        }
      } finally {
        _isProcessingSave = false;
      }
    }
  }

  Future<void> _saveReceipt(
    (Receipt, List<ReceiptProduct>) receiptResult,
  ) async {
    var (receipt, products) = receiptResult;
    final award = await widget.searcher.getPrizeAward(Period(receipt.issuedAt));
    final prize = award?.checkAll(receipt.invoiceNumber);
    if (prize != null) {
      receipt = receipt.copyWith(
        prizeAmount: Value(prize.amount.toDouble()),
        prizeName: Value(prize.name),
      );
    }
    await DriftServices.appDb.receiptDao.upsertMany(
      pairMap: {receipt: products},
      scopeStart: OriginStatus.manualScan,
      scopeEnd: OriginStatus.manualScan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isPortrait = Utils.isPortrait(context);
    final bool isScanAutoAdd = context.readPrefs.get(.isScanAutoAdd);
    final receipt = _receiptResult?.$1;
    return Flex(
      direction: isPortrait ? Axis.vertical : Axis.horizontal,
      verticalDirection: isPortrait
          ? VerticalDirection.up
          : VerticalDirection.down,
      children: [
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              ListTile(
                title: Text(receipt?.invoiceNumber ?? '請讓鏡頭同時只辨識一張發票。'),
                subtitle: Text(
                  <String>[
                    receipt == null
                        ? ''
                        : UnitUtils.singleTimeText(receipt.issuedAt),
                    receipt == null
                        ? ''
                        : '${DictKey.receiptHeaderTotalAmount.s}: ${UnitUtils.amountText(receipt.totalAmount)}',
                  ].join('\n'),
                ),
                trailing: ElevatedButton(
                  onPressed: isScanAutoAdd || _isSaved || receipt == null
                      ? null
                      : _processUpdate,
                  child: Text(isScanAutoAdd ? '自動' : DictKey.commonUiSave.s),
                ),
              ),
              ListTile(
                tileColor: _invoicePrize == null
                    ? null
                    : colorScheme.primaryContainer,
                title: Text(
                  _invoiceAward == null
                      ? DictKey.scannerManualNoData.s
                      : _invoicePrize?.name ?? '未中獎',
                ),
                subtitle: Text(
                  _invoicePrize == null
                      ? ''
                      : '\$${UnitUtils.amountText(_invoicePrize!.amount)}',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ValueListenableBuilder(
                valueListenable: _isCameraOpen,
                child: CameraView(
                  customPaints: [?_customPaintBarcode, ?_customPaintText],
                  onImage: _processImage,
                  errorBuilder: (context, msg) => Center(child: Text(msg)),
                  initialCameraLensDirection: _cameraLensDirection,
                  onCameraLensDirectionChanged: (value) =>
                      _cameraLensDirection = value,
                ),
                builder: (context, value, child) => value
                    ? child!
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
