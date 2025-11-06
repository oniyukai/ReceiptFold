import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/modules/secure_prefs.dart';
import 'package:receipt_fold/pages/widget/functions.dart';
import 'package:receipt_fold/pages/widget/required_text_field.dart';

enum PlatformLoginState {
  notSet,
  pending,
  failed,
  verified;

  String get locale => switch (this) {
    notSet => AppLocale.preferencesLoginStateNotSet.s,
    pending => AppLocale.preferencesLoginStatePending.s,
    failed => AppLocale.preferencesLoginStateFailed.s,
    verified => AppLocale.preferencesLoginStateVerified.s,
  };
}

Future<void> pagePlatformForm(BuildContext context) async {
  final textTheme = Theme.of(context).textTheme;
  final formKey = GlobalKey<FormBuilderState>();
  final PlatformLoginState loginState = context.readPrefs.get(PrefsEnum.invoicePlatformLoginState);
  const accountName = 'account';
  const passwordName = 'password';
  final initialAccount = await SecurePrefs.invoicePlatformAccount.read();
  final initialPassword = await SecurePrefs.invoicePlatformPassword.read();

  Future<void> checkPressed() async {
    if (formKey.currentState?.saveAndValidate() != true) return;
    final String account = formKey.currentState?.value[accountName];
    final String password = formKey.currentState?.value[passwordName];
    Navigator.pop(context);
    if (initialAccount == account && initialPassword == password) return;
    await context.readPrefs.update(PrefsEnum.invoicePlatformLoginState, PlatformLoginState.pending);
    if (initialAccount != account) await SecurePrefs.invoicePlatformAccount.write(account);
    if (initialPassword != password) await SecurePrefs.invoicePlatformPassword.write(password);
  }

  void logoutPressed() {
    assert(loginState != PlatformLoginState.notSet);
    showMyDialog(
      context: context,
      title: AppLocale.preferencesInvoicePlatformTitle.s,
      content: Text(AppLocale.preferencesSureToLogoutPlatformLabel.s),
      actions: [
        TextButton(
          child: Text(AppLocale.preferencesLogoutLabel.s),
          onPressed: () async {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            context.readPrefs.update(PrefsEnum.invoicePlatformLoginState, PlatformLoginState.notSet);
            await SecurePrefs.invoicePlatformAccount.delete();
            await SecurePrefs.invoicePlatformPassword.delete();
          },
        ),
      ],
    );
  }

  void build() => showMyBottomSheet(
    context: context,
    noCancelButton: true,
    title: ListTile(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        AppLocale.preferencesInvoicePlatformTitle.s,
        style: textTheme.titleMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loginState != PlatformLoginState.notSet) IconButton(
            onPressed: logoutPressed,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: checkPressed,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
    ),
    content: FormBuilder(
      key: formKey,
      child: Column(
        children: [
          ListTile(
            minTileHeight: 0,
            title: Text(loginState.locale),
            subtitle: Text(AppLocale.preferencesLoginStateLabel.s),
          ),
          ListTile(
            minTileHeight: 0,
            subtitle: Text(AppLocale.preferencesAccountLabel.s),
          ),
          RequiredTextField(
            name: accountName,
            initialValue: initialAccount,
          ),
          ListTile(
            minTileHeight: 0,
            subtitle: Text(AppLocale.preferencesPasswordLabel.s),
          ),
          RequiredTextField(
            name: passwordName,
            initialValue: initialPassword,
            type: FieldType.password,
          ),
        ],
      ),
    ),
  );

  build();
}