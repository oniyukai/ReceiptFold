import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/widget/reorderable_tiles.dart';

Future<void> showMyDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  bool noCancelButton = false,
  List<Widget>? actions,})
async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title,
          style:Theme.of(context).textTheme.titleMedium,
          textAlign: .center
      ),
      content: content,
      actions: [
        if (!noCancelButton) TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(DictKey.cancelLabel.s),
        ),
        if (actions != null) ...actions,
      ],
    ),
  );
}

Future<void> showMyBottomSheet({
  required BuildContext context,
  Widget? title,
  Widget? content,
  bool noCancelButton = false,
  List<Widget>? actions,})
async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      padding: .fromLTRB(16.0, 16.0, 16.0, MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          ?title,
          if (title != null) const SizedBox(height: 16),
          ?content,
          if (content != null) const SizedBox(height: 16),
          Row(
            mainAxisAlignment: .spaceAround,
            children: [
              if (!noCancelButton) ElevatedButton(
                child: Text(DictKey.cancelLabel.s),
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
}

Future<void> showSortDialog<T>({
  required BuildContext context,
  required List<T> items,
  required Widget Function(T item) itemBuilder,
  required ValueChanged<List<T>> saveOnTap,})
async {
  await showMyDialog(
    context: context,
    title: DictKey.swipeToSortLabel.s,
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
        child: Text(DictKey.saveLabel.s),
        onPressed: () {
          Navigator.pop(context);
          saveOnTap(items);
        },
      ),
    ],
  );
}
