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
    fillObjectMonths = '<fillObject.fillObjectMonths>',
    fillObjectNumber = '<fillObject.fillObjectNumber>',
    fillObjectAmount = '<fillObject.fillObjectAmount>',
    fillObjectOldBytes = '<fillObject.fillObjectOldBytes>',
    fillObjectNewBytes = '<fillObject.fillObjectNewBytes>',
    // Other
    nullString = 'NULL<String>',
    searchSplit = '||';
}

enum DictKey {
  // ===== Common: 通用 UI & 動作 =====
  commonUiCancel,
  commonUiSave,
  commonUiDelete,
  commonUiSureDelete,
  commonUiSwipeSort,
  commonUiSort,
  commonUiAdd,
  commonUiFailure,

  // ===== Toast: 提示訊息 =====
  toastCopied,
  toastNoContentCopy,

  // ===== Nav: 導航 =====
  navTitleRecorder,
  navTitleScanner,
  navTitleManager,
  navTitleSettings,

  // ===== Scanner: 掃描對獎 =====
  scannerTabManual,
  scannerTabNumber,
  scannerTabScan,
  scannerManualHint,
  scannerManualNoData,
  scannerNumberBrowsePeriod,
  scannerNumberColumnPrize,
  scannerNumberColumnAmount,
  scannerNumberColumnNumber,
  scannerNumberRule,

  // ===== Barcode: 格式 =====
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

  // ===== Barcode: 組成規則 =====
  barcodeCompositionText,
  barcodeCompositionTextSimple,
  barcodeCompositionTextUpperSimple,
  barcodeCompositionDigits,
  barcodeCompositionNumber,
  barcodeCompositionEvenLengthNumbers,
  barcodeComposition7Digits1Check,
  barcodeComposition11Digits1Check,
  barcodeComposition12Digits1Check,

  // ===== Barcode: 錯誤驗證 =====
  barcodeErrorEmptyFields,
  barcodeErrorNotNumber,
  barcodeErrorWrongLength,
  barcodeErrorWrongCheckDigit,
  barcodeErrorUnsupportedCharsIso88591,
  barcodeErrorUnsupportedCharsAscii,
  barcodeErrorRegexCode93,
  barcodeErrorRegexCode39,
  barcodeErrorRegexCodabar,
  barcodeErrorItfEvenLength,
  barcodeErrorUpcEStartZero,

  // ===== Manager: 載具管理 =====
  managerTabBarcode,
  managerTabMember,
  managerTabCarrier,
  managerNotYetSet,
  managerMobileCarrier,
  managerEditMobileCarrier,
  managerAddMobileCarrier,
  managerChangeMobileCarrier,
  managerMembershipCard,
  managerEditMembershipCard,
  managerAddMembershipCard,
  managerThumbnailUrl,
  managerNotAUrl,
  managerBrightenScreen,
  managerCodeLabel,
  managerNameLabel,
  managerPreviousRendering,
  managerAddCarrier,
  managerEditCarrier,
  managerCarrierStatus,
  managerCarrierId2,
  managerCarrierCustomName,
  managerCarrierTypeCode,
  managerCarrierTypeName,
  managerCarrierDuplicate,

  // ===== Carrier: 載具狀態 =====
  carrierStatusPlatform,
  carrierStatusPlatformExpired,
  carrierStatusManual,

  // ===== Origin: 發票來源狀態 =====
  originStatusPlatformUnconfirmed,
  originStatusPlatformInvalidated,
  originStatusPlatformDonated,
  originStatusPlatformConfirmed,
  originStatusPlatformConfirmedNotDonated,
  originStatusPlatformExpired,
  originStatusManualImport,
  originStatusManualScan,
  originStatusManualEntry,

  // ===== Recorder: 記錄器 =====
  recorderMenuPrizeCheck,
  recorderMenuStatisticalAnalysis,
  recorderMenuSearch,
  recorderMenuReturnToday,
  recorderPeriodTransactionsAndAmount,
  recorderMonthTransactionsAndAmount,

  // ===== Receipt: 發票檢視 =====
  receiptViewAddRecord,
  receiptViewRecord,
  receiptViewOriginalContent,
  receiptViewModify,
  receiptHeaderSellerName,
  receiptHeaderInvoiceNumber,
  receiptHeaderOriginStatus,
  receiptHeaderCarrierName,
  receiptHeaderCarrierType,
  receiptHeaderCarrierId2,
  receiptHeaderSellerAddress,
  receiptHeaderSellerTaxId,
  receiptHeaderRandomNumber,
  receiptHeaderSellerRemark,
  receiptHeaderUserNote,
  receiptHeaderPrizeName,
  receiptHeaderPrizeAmount,
  receiptHeaderTotalAmount,
  receiptHeaderItemLength,
  receiptHeaderIssuedPeriod,
  receiptDetailItem,
  receiptDetailUnitPrice,
  receiptDetailQuantity,
  receiptDetailAmount,

  // ===== Platform: 發票平台 =====
  platformTitle,
  platformFunctionAction,
  platformAccountSetting,
  platformFillAccount,
  platformPhoneLabel,
  platformPasswordLabel,
  platformQueryMonths,
  platformQueryMonthsOption,
  platformImportCsv,
  platformExecuteAll,
  platformFetchCarrier,
  platformFetchAward,
  platformFetchInvoice,
  platformWebView,
  platformRealTimeLog,

  // ===== Backup: 備份同步 =====
  backupTitle,
  backupDeviceAction,
  backupDevicePushFile,
  backupPush,
  backupPull,
  backupPushForce,
  backupPullForce,
  backupSync,
  backupWebDAV,
  backupConnectionSetting,
  backupSaveAndConnect,
  backupUrlLabel,
  backupUserLabel,
  backupPasswordLabel,
  backupAutoSync,
  backupRealTimeLog,
  backupDeleteLog,
  backupSureDeleteLog,

  // ===== Setting: 設定 =====
  settingGroupAppearance,
  settingOptionColor,
  settingOptionTheme,
  settingOptionThemeSystem,
  settingOptionThemeLight,
  settingOptionThemeDark,
  settingGroupLanguages,
  settingOptionLanguagesDefault,
  settingGroupDataAutomation,
  settingDataPlatform,
  settingDataBackup,
  settingGroupPreferences,
  settingSwitchAutoBrightness,
  settingOptionScanLockOrient,
  settingSwitchShowLockRotation,
  settingActionClearCache,
  settingCacheClearedMsg,
  settingGroupAbout,
  settingOptionVersion,
  settingOptionVersionTag,
  settingOptionLicenses,
  settingOptionSourceCode,
  settingOptionDebugLog,
  settingTermsTitle,
  settingTermsAgreedAll,
  settingTermsContinue,

  // ===== Setting: 顏色選項 =====
  settingOptionColorMaterialYou,
  settingOptionColorBlue,
  settingOptionColorViolet,
  settingOptionColorPurple,
  settingOptionColorPink,
  settingOptionColorDeepOrange,
  settingOptionColorOrange,
  settingOptionColorYellow,
  settingOptionColorGreen,
  settingOptionColorTeal,

  // ===== Action: 其他動作 =====
  actionCouldNotLaunch;

  String get s => _instance[this] ?? '<$name>';

  static late LocaleInstance _instance;
  static late Locale _locale;

  static void load(BuildContext context) {
    _instance = Localizations.of<LocaleInstance>(context, LocaleInstance)!;
    _locale = Localizations.localeOf(context);
  }

  static String get languageTag => _locale.toLanguageTag();
}
