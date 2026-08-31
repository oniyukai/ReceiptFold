import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:drift/drift.dart' show Value;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:material_ui/material_ui.dart';
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
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_scanner_widgets.dart';
import 'package:receipt_fold/services/drift_service.dart';
import 'package:receipt_fold/services/invoice_prize_searcher.dart';
import 'package:receipt_fold/services/log_service.dart';

/// ASCII "*"
const int _asterisk = 0x2A;

class TabScannerView extends StatefulWidget {
  final InvoicePrizeSearcher searcher;

  const TabScannerView({super.key, required this.searcher});

  @override
  State<TabScannerView> createState() => _TabScannerViewState();
}

class _TabScannerViewState extends State<TabScannerView> {
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
  ReceiptRecord? _receiptRecord;
  bool _isSaved = false;
  bool _isProcessingSave = false;
  Future<void> Function()? _latestSaveQueued;

  @override
  void dispose() {
    super.dispose();
    _setCameraOpen(false);
    _setOrientationLock(false);
    _barcodeScanner.close();
    _textRecognizer.close();
    _audioPlayer.dispose();
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
    } catch (e) {
      if (context.readPrefs.get(.isAppDeveloperMode)) {
        LogService(
          '_processImage($InputImage)',
          errorObject: e,
          instance: this,
        ).w();
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
        LogService(
          '$QrCodeInvoice.parse($Uint8List)',
          errorObject: e,
          instance: this,
        ).w();
        isRecognizedValid = false;
      }
    }

    _checkNeedUpdate(isRecognizedValid ? recognizedInvoice : null);
    return (resultBarcodes, resultRecognizedText);
  }

  void _checkNeedUpdate(RecognizedInvoice? recognizedInvoice) {
    if (recognizedInvoice == null) return;
    final receiptRecord = recognizedInvoice.receiptRecord();
    if (receiptRecord == null) return;
    final (receipt, products) = receiptRecord;
    final lastReceiptRecord = _receiptRecord;
    var lastReceipt = lastReceiptRecord?.receipt;
    var lastProducts = lastReceiptRecord?.products;
    if (lastReceipt == null ||
        receipt.invoiceNumber != lastReceipt.invoiceNumber) {
      Utils.deviceVibrate();
      Utils.audioPlayBeep(_audioPlayer);
      unawaited(_refreshPrize(receipt));
      unawaited(_processUpdate(receiptRecord));
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
    if (lastReceiptRecord?.receipt == lastReceipt) return;
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

  Future<void> _processUpdate([ReceiptRecord? receiptRecord]) async {
    if (receiptRecord != null) _receiptRecord = receiptRecord;
    _isSaved = false;
    if (mounted) setState(() {});
    if (receiptRecord == null || context.readPrefs.get<bool>(.isScanAutoAdd)) {
      receiptRecord ??= _receiptRecord;
      if (receiptRecord == null) return;
      _latestSaveQueued = () => _saveReceipt(receiptRecord!);
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

  Future<void> _saveReceipt(ReceiptRecord receiptRecord) async {
    var (receipt, products) = receiptRecord;
    final award = await widget.searcher.getPrizeAward(Period(receipt.issuedAt));
    final prize = award?.checkAll(receipt.invoiceNumber);
    if (prize != null) {
      receipt = receipt.copyWith(
        prizeAmount: Value(prize.amount.toDouble()),
        prizeName: Value(prize.name),
      );
    }
    await DriftService.appDb.receiptDao.upsertMany(
      pairMap: {receipt: products},
      scopeStart: OriginStatus.deviceScan,
      scopeEnd: OriginStatus.deviceScan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isPortrait = Utils.isPortrait(context);
    final bool isScanAutoAdd = context.readPrefs.get(.isScanAutoAdd);
    final receipt = _receiptRecord?.receipt;
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
                title: Text(
                  receipt?.invoiceNumber ?? DictKey.scannerScannerHint.s,
                ),
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
                  child: Text(
                    isScanAutoAdd
                        ? DictKey.scannerScannerAuto.s
                        : DictKey.commonUiSave.s,
                  ),
                ),
              ),
              ListTile(
                tileColor: _invoicePrize == null
                    ? null
                    : colorScheme.primaryContainer,
                title: Text(
                  _invoiceAward == null
                      ? DictKey.scannerManualNoData.s
                      : _invoicePrize?.name ?? DictKey.scannerScannerNoPrize.s,
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
                child: LifecycleVisibility(
                  replacement: const Center(child: CircularProgressIndicator()),
                  child: CameraView(
                    customPaints: [?_customPaintBarcode, ?_customPaintText],
                    onImage: _processImage,
                    errorBuilder: (context, msg) => Center(child: Text(msg)),
                    initialCameraLensDirection: _cameraLensDirection,
                    onCameraLensDirectionChanged: (value) =>
                        _cameraLensDirection = value,
                  ),
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
