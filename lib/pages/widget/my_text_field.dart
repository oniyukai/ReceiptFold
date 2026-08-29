import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
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
    number => DictKey.barcodeCompositionNumber,
    password => DictKey.barcodeCompositionText,
  }.s;
}

class MyTextField extends StatefulWidget {
  final String name;
  final String? initialValue;
  final String? labelText;
  final IconData? prefixIconData;
  final FieldType type;
  final bool required;
  final bool readOnly;

  const MyTextField({
    super.key,
    required this.name,
    this.initialValue,
    this.labelText,
    this.prefixIconData,
    this.type = FieldType.text,
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
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: widget.name,
      maxLines: 1,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: widget.initialValue,
      obscureText: textHidden,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        prefixIcon: Icon(widget.prefixIconData ?? widget.type.iconData),
        labelText: widget.labelText ?? widget.type.labelText,
        errorMaxLines: 8,
        suffixIcon: widget.type.isObscure
            ? IconButton(
                onPressed: () {
                  setState(() => textHidden = !textHidden);
                },
                icon: Icon(
                  textHidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              )
            : null,
      ),
      keyboardType: widget.type.inputType,
      validator: FormBuilderValidators.compose([
        if (widget.required)
          FormBuilderValidators.required(
            errorText: DictKey.barcodeErrorEmptyFields.s,
          ),
        if (widget.type == FieldType.number)
          FormBuilderValidators.numeric(
            errorText: DictKey.barcodeErrorNotNumber.s,
            checkNullOrEmpty: false,
          ),
      ]),
    );
  }
}
