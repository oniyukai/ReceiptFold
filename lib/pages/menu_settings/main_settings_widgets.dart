import 'package:flutter/material.dart';
import 'package:receipt_fold/pages/widget/functions.dart';

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: isSection ? const EdgeInsets.only(top: 16, left: 16) : null,
      leading: SizedBox(width: 48, child: Icon(iconData)),
      shape: shape,
      minTileHeight: isSection ? 0 : null,
      title: Text(
        text,
        style: TextStyle(
          fontSize: isSection ? theme.textTheme.titleSmall?.fontSize : null,
        ),
      ),
      subtitle: subText==null ? null : Text(subText!),
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
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(width: 48, child: Icon(iconData)),
      title: Text(text),
      enabled: enabled,
      shape: shape,
      onTap: ()=>onToggle(!initialValue),
      trailing: Switch.adaptive(
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
  final Map<T, String> optionMap;  // 現在開放<T>是因為新版Prefs對SharedPreferences不再限定於特定型別
  final ValueChanged<T> onChanged;
  final ShapeBorder? shape;

  const ListTilePicker({
    super.key,
    required this.text,
    this.iconData,
    this.dialogText,
    required this.selectedOption,
    required this.optionMap,
    required this.onChanged,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(width: 48, child: Icon(iconData)),
      title: Text(text),
      subtitle: Text('${optionMap[selectedOption] ?? selectedOption}'),
      shape: shape,
      onTap: () => showMyDialog(
        context: context,
        title: dialogText ?? text,
        content: Scrollbar(
          child: SingleChildScrollView(
            child: RadioGroup<T>(
              groupValue: selectedOption,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: optionMap.entries.map((entry) => RadioListTile(
                  title: Text(entry.value),
                  value: entry.key,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}