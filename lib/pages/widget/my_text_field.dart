import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum FieldType {
  text(Icons.format_size, TextInputType.text, false),
  number(Icons.pin_outlined, TextInputType.number, false),
  password(Icons.password, TextInputType.visiblePassword, true);

  final IconData iconData;
  final TextInputType inputType;
  final bool isObscure;

  const FieldType(this.iconData, this.inputType, this.isObscure);

  String get labelText => switch (this) {
    text => DictKey.barcodeCompositionText,
    number=> DictKey.barcodeNumberCompositionLabel,
    password => DictKey.barcodeCompositionText,
  }.s;
}

class MyTextField extends StatefulWidget {
  final String name;
  final String? initialValue;
  final FieldType type;
  final bool required;
  final bool readOnly;

  const MyTextField({
    super.key,
    required this.name,
    this.initialValue,
    this.type = .text,
    this.required = true,
    this.readOnly = false,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool textHidden = false;

  @override
  void initState() {
    super.initState();
    textHidden = widget.type.isObscure;
  }

  @override
  Widget build(context) {
    return FormBuilderTextField(
      name: widget.name,
      maxLines: 1,
      initialValue: widget.initialValue,
      obscureText: textHidden,
      readOnly: widget.readOnly,
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
        if (widget.required) FormBuilderValidators.required(errorText: DictKey.errorEmptyFields.s),
        if (widget.type == .number) FormBuilderValidators.numeric(errorText: DictKey.errorNotNumber.s, checkNullOrEmpty: false),
      ]),
    );
  }
}
