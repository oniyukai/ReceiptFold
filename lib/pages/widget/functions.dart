import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/widget/reorderable_tiles.dart';

void showMyDialog({
  required BuildContext context,
  String? title,
  required Widget content,
  bool noCancelButton = false,
  List<Widget>? actions,})
{
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: (title != null) ? Center(
          child: Text(title, style:Theme.of(context).textTheme.titleMedium),
        ) : null,
        content: content,
        actions: <Widget>[
          if (!noCancelButton) TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocale.cancelLabel.s),
          ),
          if (actions != null) ...actions,
        ],
      );
    },
  );
}


void showMyBottomSheet({
  required BuildContext context,
  Widget? title,
  Widget? content,
  bool noCancelButton = false,
  List<Widget>? actions,})
{
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              if (title != null) title,
              if (title != null) const SizedBox(height: 8),
              if (content != null) content,
              if (content != null) const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (!noCancelButton) ElevatedButton(
                    child: Text(AppLocale.cancelLabel.s),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (actions != null) ...actions,
                ],
              ),
              if (actions != null && actions.isNotEmpty && !noCancelButton) const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}


void showSortDialog<T>({
  required BuildContext context,
  required List<T> items,
  required Widget Function(T item) itemBuilder,
  required ValueChanged<List<T>> saveOnTap,})
=> showMyDialog(
  context: context,
  title: AppLocale.swipeToSortLabel.s,
  content: SizedBox(
    height: MediaQuery.of(context).size.height * 0.6,
    width: MediaQuery.of(context).size.width * 0.8,
    child: Scrollbar(
      child: ReorderableTiles(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        initialItems: items,
        onReorderFinished: (list) => items=list,
        itemBuilder: itemBuilder,
      ),
    ),
  ),
  actions: [
    TextButton(
      child: Text(AppLocale.saveLabel.s),
      onPressed: () {
        Navigator.of(context).pop();
        saveOnTap(items);
      },
    ),
  ],
);