import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';

class PageTermsView extends StatefulWidget {
  const PageTermsView({super.key});

  @override
  State<PageTermsView> createState() => _PageTermsViewState();
}

class _PageTermsViewState extends State<PageTermsView> {
  bool _isAgreedAllTerms = false;
  String? _termsText;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    String termsText = await rootBundle.loadString('assets/license_and_terms.md');
    setState(() => _termsText = termsText);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAgreed = context.readPrefs.get(PrefsEnum.isAgreedAllTerms);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.preferencesTermsTitle.s),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _termsText == null
                  ? const Center(child: CircularProgressIndicator())
                  : Scrollbar(
                thumbVisibility: true,
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Text(_termsText!),
                    ),
                  ),
                ),
              ),
            ),
            if (!isAgreed) CheckboxListTile(
              title: Text(AppLocale.preferencesTermsAgreedAll.s),
              value: _isAgreedAllTerms,
              enabled: _termsText != null,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() => _isAgreedAllTerms = value ?? false),
            ),
            if (!isAgreed) ElevatedButton(
              onPressed: _termsText != null && _isAgreedAllTerms
                  ? () => context.readPrefs.update(PrefsEnum.isAgreedAllTerms, true)
                  : null,
              child: Text(AppLocale.preferencesTermsContinue.s),
            ),
            const Row(),
          ],
        ),
      ),
    );
  }
}