import 'package:flutter/material.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class ListTileText extends StatelessWidget {
  final String text;
  final String? subText;
  final bool isSection;
  final Widget? trailing;
  final IconData? iconData;
  final VoidCallback? onTap;
  final ShapeBorder? shape;

  const ListTileText({
    super.key,
    required this.text,
    this.subText,
    this.isSection = false,
    this.trailing,
    this.iconData,
    this.onTap,
    this.shape,
  });

  @override
  Widget build(context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: isSection ? const EdgeInsets.only(top: 16, left: 16) : null,
      leading: Icon(iconData),
      shape: shape,
      minTileHeight: isSection ? 0 : null,
      title: Text(
        text,
        style: TextStyle(
          fontSize: isSection ? theme.textTheme.titleSmall?.fontSize : null,
        ),
      ),
      subtitle: subText == null ? null : Text(subText!),
      textColor: isSection ? colorScheme.primary : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class ListTileSwitch extends StatelessWidget {
  final String text;
  final bool initialValue;
  final ValueChanged<bool> onToggle;
  final IconData? iconData;
  final bool enabled;
  final ShapeBorder? shape;

  const ListTileSwitch({
    super.key,
    required this.text,
    required this.initialValue,
    required this.onToggle,
    this.iconData,
    this.enabled = true,
    this.shape,
  });

  @override
  Widget build(context) {
    return ListTile(
      leading: Icon(iconData),
      title: Text(text),
      enabled: enabled,
      shape: shape,
      onTap: () => onToggle(!initialValue),
      trailing: Switch(
        value: initialValue,
        onChanged: enabled ? onToggle : null,
      ),
    );
  }
}

class ListTilePicker<T> extends StatelessWidget {
  final String text;
  final IconData? iconData;
  final String? dialogText;
  final T selectedOption;
  final Map<T, String> optionMap;
  final ValueChanged<T> onChanged;
  final Widget Function(Radio<T>, bool)? optionLeadingBuilder;
  final ShapeBorder? shape;

  const ListTilePicker({
    super.key,
    required this.text,
    this.iconData,
    this.dialogText,
    required this.selectedOption,
    required this.optionMap,
    required this.onChanged,
    this.optionLeadingBuilder,
    this.shape,
  });

  void _onChanged(BuildContext context, T? value) {
    if (value != null && value != selectedOption) {
      onChanged(value);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(context) {
    return ListTile(
      leading: Icon(iconData),
      title: Text(text),
      subtitle: Text('${optionMap[selectedOption] ?? selectedOption}'),
      shape: shape,
      onTap: () => OverlayShow.dialog(
        context: context,
        title: dialogText ?? text,
        content: Scrollbar(
          child: SingleChildScrollView(
            child: RadioGroup<T>(
              groupValue: selectedOption,
              onChanged: (value) => _onChanged(context, value),
              child: Column(
                mainAxisSize: .min,
                children: [
                  for (final T value in optionMap.keys)
                    ListTile(
                      leading: (optionLeadingBuilder ?? (radio, _) => radio)(
                        Radio(
                            value: value,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap
                        ),
                        value == selectedOption,
                      ),
                      title: Text(optionMap[value]!),
                      shape: RoundedRectangleBorder(borderRadius: .circular(12.0)),
                      onTap: () => _onChanged(context, value),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
