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
  navTitleRecorder,
  navTitleScanner,
  navTitleManager,
  navTitleSettings,
  // Button
  commonUiCancel,
  saveLabel,
  commonLabelDelete,
  sureToDeleteThisLabel,
  swipeToSortLabel,
  sortLabel,
  addNewLabel,
  // Toast
  copiedLabel,
  noContentToCopyLabel,
  // preferences
  settingGroupAppearance,
  settingOptionTheme,
  settingOptionThemeSystem,
  settingOptionThemeLight,
  settingOptionThemeDark,
  settingOptionColor,
  settingGroupLanguages,
  settingOptionLanguagesDefault,
  preferencesPreferenceTitle,
  preferencesSwitchAutoBrightnessLabel,
  settingOptionScanLockOrient,
  preferencesSwitchShowScreenRotationLabel,
  preferencesClearImageCacheLabel,
  preferencesClearedImageCache,
  preferencesFailure,
  settingGroupAbout,
  settingOptionVersion,
  settingOptionVersionTag,
  settingOptionLicenses,
  settingOptionSourceCode,
  preferencesTermsTitle,
  preferencesTermsAgreedAll,
  preferencesTermsContinue,
  // Barcode Type
  barcodeFormatQrCode,
  barcodeFormatDataMatrix,
  barcodeFormatAztec,
  barcodeFormatPdf417,
  barcodeFormatEan13,
  barcodeFormatEan8,
  barcodeFormatUpcA,
  barcodeFormatUpcE,
  barcodeFormatCode128,
  barcodeFormatCode93,
  barcodeFormatCode39,
  barcodeFormatCodabar,
  barcodeFormatItf,
  // Barcode Composition
  barcodeNumberCompositionLabel,
  barcodeCompositionText,
  barcodeCompositionTextSimple,
  barcodeCompositionTextUpperSimple,
  barcodeCompositionDigits,
  barcodeCompositionEvenLengthNumbers,
  barcodeComposition7Digits1Check,
  barcodeComposition11Digits1Check,
  barcodeComposition12Digits1Check,
  // Barcode Generator Errors
  errorEmptyFields,
  errorNotNumber,
  errorWrongLength,
  errorWrongCheckDigit,
  errorUnsupportedCharsIso88591,
  errorUnsupportedCharsAscii,
  errorRegexCode93,
  errorRegexCode39,
  errorRegexCodabar,
  errorItfEvenLength,
  errorUpcEStartZero,
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
  // Recorder
  recorderPeriodTransactionsAndAmount,
  recorderMonthTransactionsAndAmount,
  recorderMenuStatisticalAnalysisLabel,
  recorderMenuSearchLabel,
  recorderMenuReturnTodayLabel,
  // Receipt
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
  receiptHeaderTotalAmountLabel,
  receiptHeaderItemLengthLabel,
  receiptDetailLabel,
  receiptDetailItemLabel,
  receiptDetailUnitPriceLabel,
  receiptDetailQuantityLabel,
  receiptDetailAmountLabel;

  String get s => _instance[this] ?? '<$name>';

  static late LocaleInstance _instance;
  static late Locale _locale;

  static void load(BuildContext context) {
    _instance = Localizations.of<LocaleInstance>(context, LocaleInstance)!;
    _locale = Localizations.localeOf(context);
  }

  static String get languageTag => _locale.toLanguageTag();
}
