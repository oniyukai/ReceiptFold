import 'package:flutter/material.dart';

class MyMenuItem {
  final String? text;
  final IconData? iconData;
  final VoidCallback? onTap;

  const MyMenuItem({
    required this.text,
    this.onTap,
    this.iconData,
  });
}

class MyMenuButton extends StatelessWidget {
  final Widget? icon;
  final List<MyMenuItem> items;
  final void Function(int value)? onSelectedEnd;

  const MyMenuButton({
    super.key,
    this.icon,
    required this.items,
    this.onSelectedEnd,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: icon ?? const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => List.generate(
          items.length,
          (value) {
            final text = items[value].text;
            final iconData = items[value].iconData;
            return PopupMenuItem<int>(
              value: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconData != null) Icon(iconData),
                  if (iconData != null) const SizedBox(width: 8),
                  if (text != null) Text(text),
                ],
              ),
            );
          }),
      onSelected: (int value) {
        final func = items[value].onTap;
        if (func != null) func();
        if (onSelectedEnd != null) onSelectedEnd!(value);
      },
    );
  }
}