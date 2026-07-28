import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/locale/app_language.dart';

abstract final class OverlayShow {
  static Future<void> dialog({
    required BuildContext context,
    required String title,
    required Widget content,
    bool noCancelButton = false,
    List<Widget>? actions,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: content,
        actions: [
          if (!noCancelButton)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(DictKey.commonUiCancel.s),
            ),
          ...?actions,
        ],
      ),
    );
  }

  static Future<void> bottomSheet({
    required BuildContext context,
    Widget? title,
    Widget? content,
    bool noCancelButton = false,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            ?title,
            if (title != null) const SizedBox(height: 16),
            ?content,
            if (content != null) const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!noCancelButton)
                  ElevatedButton(
                    child: Text(DictKey.commonUiCancel.s),
                    onPressed: () => Navigator.pop(context),
                  ),
                ...?actions,
              ],
            ),
            if (actions != null && actions.isNotEmpty && !noCancelButton)
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<void> sortDialog<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(T item) itemBuilder,
    required ValueChanged<List<T>> saveOnTap,
  }) {
    final ScrollController scrollController = ScrollController();
    return OverlayShow.dialog(
      context: context,
      title: DictKey.commonUiSwipeSort.s,
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Scrollbar(
          controller: scrollController,
          child: _ReorderableTiles(
            scrollController: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            initialItems: items,
            onReorderFinished: (list) => items = list,
            itemBuilder: itemBuilder,
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(DictKey.commonUiSave.s),
          onPressed: () {
            Navigator.pop(context);
            saveOnTap(items);
          },
        ),
      ],
    ).whenComplete(scrollController.dispose);
  }

  static _ToastWidget? _lastToastWidget;

  static Future<void> toast(
    Widget content, {
    int seconds = 2,
    Alignment alignment = Alignment.bottomCenter,
    EdgeInsetsGeometry margin = const EdgeInsets.all(16),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 16,
    ),
  }) {
    final OverlayState? overlayState =
        MyRouter.delegate.navigatorKey.currentState?.overlay;
    if (overlayState == null) return SynchronousFuture(null);
    late _ToastWidget toastWidget;
    toastWidget = _ToastWidget(
      seconds: seconds,
      completer: Completer(),
      overlayEntry: OverlayEntry(
        builder: (context) => SafeArea(
          child: Align(alignment: alignment, child: toastWidget),
        ),
      ),
      builder: (context) => Card(
        margin: margin,
        elevation: 2,
        color: Theme.of(context).colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(padding: padding, child: content),
      ),
    );
    _lastToastWidget?.remove();
    _lastToastWidget = toastWidget;
    overlayState.insert(toastWidget.overlayEntry);
    return toastWidget.completer.future;
  }
}

class _ReorderableTiles<T> extends StatefulWidget {
  final ScrollController scrollController;
  final List<T> initialItems;
  final ValueChanged<List<T>> onReorderFinished;
  final Widget Function(T item) itemBuilder;
  final EdgeInsets? padding;

  const _ReorderableTiles({
    super.key,
    required this.scrollController,
    required this.initialItems,
    required this.onReorderFinished,
    required this.itemBuilder,
    this.padding,
  });

  @override
  State<_ReorderableTiles> createState() => _ReorderableTilesState<T>();
}

class _ReorderableTilesState<T> extends State<_ReorderableTiles<T>> {
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List<T>.from(widget.initialItems);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    _items = List<T>.from(widget.initialItems);
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() => _items.insert(newIndex, _items.removeAt(oldIndex)));
    widget.onReorderFinished(_items);
  }

  @override
  Widget build(context) {
    return ReorderableListView.builder(
      scrollController: widget.scrollController,
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: _items.length,
      padding: widget.padding,
      onReorderItem: _onReorderItem,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) =>
          Material(elevation: 0, color: Colors.transparent, child: child),
      itemBuilder: (BuildContext context, index) =>
          ReorderableDragStartListener(
            key: ValueKey(index),
            index: index,
            child: widget.itemBuilder(_items[index]),
          ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final int seconds;
  final Completer<void> completer;
  final OverlayEntry overlayEntry;
  final WidgetBuilder builder;

  const _ToastWidget({
    required this.seconds,
    required this.completer,
    required this.overlayEntry,
    required this.builder,
  });

  void remove() {
    if (overlayEntry.mounted) overlayEntry.remove();
    if (!completer.isCompleted) completer.complete();
  }

  @override
  State<StatefulWidget> createState() => _ToastState();
}

class _ToastState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 0.9).animate(_controller);
    _controller.forward();
    Future.delayed(Duration(seconds: widget.seconds), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.remove());
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.builder(context));
  }
}
