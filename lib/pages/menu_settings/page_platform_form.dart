import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/modules/secure_prefs.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';

enum PlatformLoginState {
  notSet,
  pending,
  failed,
  verified;

  String get locale => switch (this) {
    notSet => DictKey.preferencesLoginStateNotSet.s,
    pending => DictKey.preferencesLoginStatePending.s,
    failed => DictKey.preferencesLoginStateFailed.s,
    verified => DictKey.preferencesLoginStateVerified.s,
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

  Future<void> logoutPressed() {
    assert(loginState != PlatformLoginState.notSet);
    return OverlayShow.dialog(
      context: context,
      title: '發票平台',
      content: Text(DictKey.preferencesSureToLogoutPlatformLabel.s),
      actions: [
        TextButton(
          child: Text(DictKey.preferencesLogoutLabel.s),
          onPressed: () async {
            Navigator.pop(context);
            Navigator.pop(context);
            context.readPrefs.update(PrefsEnum.invoicePlatformLoginState, PlatformLoginState.notSet);
            await SecurePrefs.invoicePlatformAccount.delete();
            await SecurePrefs.invoicePlatformPassword.delete();
          },
        ),
      ],
    );
  }

  Future<void> build() => OverlayShow.bottomSheet(
    context: context,
    noCancelButton: true,
    title: ListTile(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        '發票平台',
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
            subtitle: Text(DictKey.preferencesLoginStateLabel.s),
          ),
          ListTile(
            minTileHeight: 0,
            subtitle: Text(DictKey.preferencesAccountLabel.s),
          ),
          MyTextField(
            name: accountName,
            initialValue: initialAccount,
          ),
          ListTile(
            minTileHeight: 0,
            subtitle: Text(DictKey.preferencesPasswordLabel.s),
          ),
          MyTextField(
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
