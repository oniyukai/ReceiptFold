import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum FieldType {
  onelineText(Icons.format_size, TextInputType.text, false),
  number(Icons.pin_outlined, TextInputType.number, false),
  password(Icons.password, TextInputType.visiblePassword, true);

  final IconData iconData;
  final TextInputType inputType;
  final bool isObscure;

  const FieldType(this.iconData, this.inputType, this.isObscure);

  String get labelText => switch (this) {
    onelineText => AppLocale.barcodeTextCompositionLabel.s,
    number=> AppLocale.barcodeDigitsCompositionLabel.s,
    password => AppLocale.barcodeTextCompositionLabel.s,
  };
}

class RequiredTextField extends StatefulWidget {
  final String name;
  final String? initialValue;
  final FieldType type;

  const RequiredTextField({
    super.key,
    required this.name,
    this.initialValue,
    this.type = FieldType.onelineText,
  });

  @override
  State<RequiredTextField> createState() => _RequiredTextFieldState();
}

class _RequiredTextFieldState extends State<RequiredTextField> {
  bool textHidden = false;

  @override
  void initState() {
    super.initState();
    textHidden = widget.type.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: widget.name,
      maxLines: 1,
      initialValue: widget.initialValue,
      obscureText: textHidden,
      decoration: InputDecoration(
        prefixIcon: Icon(widget.type.iconData),
        labelText: widget.type.labelText,
        errorMaxLines: 8,
        suffixIcon: widget.type.isObscure ? IconButton(
          onPressed: () {
            setState(() => textHidden = !textHidden);
          },
          icon: Icon(textHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded),
        ) : null,
      ),
      keyboardType: widget.type.inputType,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: AppLocale.errorEmptyFields.s),
        if (widget.type == FieldType.number) FormBuilderValidators.numeric(errorText: AppLocale.errorBarcodeNotANumberMessage.s),
      ]),
    );
  }
}