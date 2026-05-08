import 'package:flutter/material.dart';

typedef LocaleInstance = Map<DictKey, String?>;

extension StaticString on DictKey {
  static const String
    appName = 'ReceiptFold',
    appVersion = '0.0.1+1',
    appVersionTag = 'v0.1.alpha_26.04.27+1',
    // Language
    localeLanguageEn = 'English',
    localeLanguageJa = '日本語',
    localeLanguageZhHant = '繁體中文',
    // Url
    sourceCodeLink = 'https://github.com/oniyukai/ReceiptFold',
    // Fill Object
    fillObjectMonth = '<fillObject.fillObjectMonth>',
    fillObjectNumber = '<fillObject.fillObjectNumber>',
    fillObjectAmount = '<fillObject.fillObjectAmount>',
    fillObjectOldBytes = '<fillObject.fillObjectOldBytes>',
    fillObjectNewBytes = '<fillObject.fillObjectNewBytes>',
    // Other
    nullString = 'NULL<String>';
}

enum DictKey {
  titleRecorder,
  titleScanner,
  titleManager,
  titleSettings,
  // Button
  cancelLabel,
  saveLabel,
  deleteLabel,
  unknownLabel,
  sureToDeleteThisLabel,
  swipeToSortLabel,
  sortLabel,
  addNewLabel,
  // Toast
  copiedLabel,
  noContentToCopyLabel,
  // preferences
  preferencesDefault,
  preferencesAppearanceTitle,
  preferencesThemeLabel,
  preferencesThemeSystem,
  preferencesThemeLight,
  preferencesThemeDark,
  preferencesColorLabel,
  preferencesColorMaterialYou,
  preferencesColorBlue,
  preferencesColorOrange,
  preferencesColorGreen,
  preferencesColorRed,
  preferencesColorPurple,
  preferencesLanguageLabel,
  preferencesPreferenceTitle,
  preferencesSwitchAutoBrightnessLabel,
  preferencesSwitchScanScreenRotationLabel,
  preferencesSwitchShowScreenRotationLabel,
  preferencesClearImageCacheLabel,
  preferencesClearedImageCache,
  preferencesFailure,
  preferencesAccountLabel,
  preferencesPasswordLabel,
  preferencesLogoutLabel,
  preferencesSureToLogoutPlatformLabel,
  preferencesAboutTitle,
  preferencesApplicationVersionLabel,
  preferencesApplicationVersionTagLabel,
  preferencesAboutOpenSourceLibrariesLabel,
  preferencesSourceCodeLabel,
  preferencesTermsTitle,
  preferencesTermsAgreedAll,
  preferencesTermsContinue,
  // Barcode Type
  barcodeQrCodeLabel,
  barcodeDataMatrixLabel,
  barcodePdf417Label,
  barcodeAztecLabel,
  barcodeEan13Label,
  barcodeEan8Label,
  barcodeUpcALabel,
  barcodeUpcELabel,
  barcodeCode128Label,
  barcodeCode93Label,
  barcodeCode39Label,
  barcodeCodabarLabel,
  barcodeItfLabel,
  // Barcode Composition
  barcodeNumberCompositionLabel,
  barcodeTextCompositionLabel,
  barcodeTextNoSpecialCompositionLabel,
  barcodeTextUpperNoSpecialCompositionLabel,
  barcodeDigitsCompositionLabel,
  barcodeEvenDigitsCompositionLabel,
  barcode7Digits1CheckCompositionLabel,
  barcode11Digits1CheckCompositionLabel,
  barcode12Digits1CheckCompositionLabel,
  // Barcode Generator Errors
  errorEmptyFields,
  errorBarcodeNotANumberMessage,
  errorBarcodeWrongLengthMessage,
  errorBarcodeWrongKeyMessage,
  errorBarcodeEncodingIso88591ErrorMessage,
  errorBarcodeEncodingUsAsciiErrorMessage,
  errorBarcode93RegexErrorMessage,
  errorBarcode39RegexErrorMessage,
  errorBarcodeCodabarRegexErrorMessage,
  errorBarcodeItfErrorMessage,
  errorBarcodeUpcENotStartWith0ErrorMessage,
  // Barcode Manager
  barcodeManagerNotYetSetLabel,
  barcodeManagerMobileCarrierLabel,
  barcodeManagerEditMobileCarrierLabel,
  barcodeManagerAddMobileCarrierLabel,
  barcodeManagerChangeMobileCarrierLabel,
  barcodeManagerMembershipCardLabel,
  barcodeManagerEditMembershipCardLabel,
  barcodeManagerAddMembershipCardLabel,
  barcodeManagerThumbnailURL,
  barcodeManagerNotanURL,
  barcodeManagerBrightenScreenLabel,
  barcodeManagerCodeLabel,
  barcodeManagerNameLabel,
  barcodeManagerPreviousRenderingLabel,
  // Invoice Awarding Prize
  prizeSpecialLabel,
  prizeGrandLabel,
  prizeFirstLabel,
  prizeSecondLabel,
  prizeThirdLabel,
  prizeFourthLabel,
  prizeFifthLabel,
  prizeSixthLabel,
  prizeAdditionalSixthLabel,
  // Recorder
  recorderPeriodTransactionsAndAmount,
  recorderMonthTransactionsAndAmount,
  recorderMenuSyncPlatformLabel,
  recorderMenuLabelPrizeVerification,
  recorderMenuStatisticalAnalysisLabel,
  recorderMenuSearchLabel,
  recorderMenuReturnTodayLabel,
  // Receipt
  receiptOriginCloudPlatform,
  receiptOriginManualAddition,
  receiptViewAddRecordReceiptLabel,
  receiptViewRecordReceiptLabel,
  receiptViewOriginalContentLabel,
  receiptViewModifyLabel,
  receiptHeaderSellerNameLabel,
  receiptHeaderInvoiceNumberLabel,
  receiptHeaderInvoiceStatusLabel,
  receiptHeaderCarrierNameLabel,
  receiptHeaderCarrierTypeLabel,
  receiptHeaderSellerAddressLabel,
  receiptHeaderSellerBanIdLabel,
  receiptHeaderInvoiceRandomNumberLabel,
  receiptHeaderMainRemarkLabel,
  receiptHeaderUserNoteLabel,
  receiptHeaderPrizeInformationLabel,
  receiptHeaderPrizeAmountLabel,
  receiptHeaderReceiptOriginLabel,
  receiptHeaderTotalAmountLabel,
  receiptHeaderItemLengthLabel,
  receiptHeaderCurrencyLabel,
  receiptDetailLabel,
  receiptDetailItemLabel,
  receiptDetailUnitPriceLabel,
  receiptDetailQuantityLabel,
  receiptDetailAmountLabel,
  invoiceStatusUnconfirmed,
  invoiceStatusConfirmed,
  invoiceStatusInvalidated,
  invoiceStatusDonated,
  invoiceStatusConfirmedNotDonated;

  String get s => _instance[this] ?? '<$name>';

  static late LocaleInstance _instance;
  static late Locale _locale;

  static void load(BuildContext context) {
    _instance = Localizations.of<LocaleInstance>(context, LocaleInstance)!;
    _locale = Localizations.localeOf(context);
  }

  static String get languageTag => _locale.toLanguageTag();
}
