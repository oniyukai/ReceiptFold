import 'package:flutter/material.dart';

typedef LocaleInstance = Map<AppLocale, String?>;
typedef K = AppLocale;

extension StaticString on AppLocale {
  static const String
    appName = 'ReceiptFold',
    appVersion = '1.0.0+1',
    appVersionTag = 'v1.0.alpha_25.07.25',
    // Language
    localeLanguageEn = 'English',
    localeLanguageJa = '日本語',
    localeLanguageZhHans = '简体中文',
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
    currencyNTD = 'NTD',
    nullString = 'NULL<String>'

  ;
}

enum AppLocale {
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
  preferencesInvoicePlatformTitle,
  preferencesAccountPasswordLabel,
  preferencesAccountLabel,
  preferencesPasswordLabel,
  preferencesLogoutLabel,
  preferencesSureToLogoutPlatformLabel,
  preferencesLoginStateLabel,
  preferencesLoginStateNotSet,
  preferencesLoginStatePending,
  preferencesLoginStateFailed,
  preferencesLoginStateVerified,
  preferencesBackupTitle,
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
  receiptHeaderInvoicePeriodLabel,
  receiptHeaderTimestampLabel,
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
  invoiceStatusConfirmedNotDonated,
  ;

  String get s => _instance?[this] ?? '<$name>';

  static LocaleInstance? _instance;
  static late Locale _locale;

  static void load(BuildContext context) {
    _instance = Localizations.of<LocaleInstance>(context, LocaleInstance)!;
    _locale = Localizations.localeOf(context);
  }

  static String get languageTag => _locale.toLanguageTag();
}