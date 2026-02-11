import 'package:flutter/material.dart';

class ReorderableTiles<T> extends StatefulWidget {
  final List<T> initialItems;
  final ValueChanged<List<T>> onReorderFinished;
  final Widget Function(T item) itemBuilder;
  final EdgeInsets? padding;

  const ReorderableTiles({
    super.key,
    required this.initialItems,
    required this.onReorderFinished,
    required this.itemBuilder,
    this.padding,
  });

  @override
  State<ReorderableTiles> createState() => _ReorderableTilesState<T>();
}

class _ReorderableTilesState<T> extends State<ReorderableTiles<T>> {
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    _items = List.from(widget.initialItems);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() => _items.insert(newIndex, _items.removeAt(oldIndex)));
    widget.onReorderFinished(_items);
  }

  @override
  Widget build(context) {
    return ReorderableListView.builder(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      itemCount: _items.length,
      padding: widget.padding,
      onReorder: _onReorder,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 0,
        color: Colors.transparent,
        child: child,
      ),
      itemBuilder: (BuildContext context, index) => ReorderableDragStartListener(
        key: ValueKey(index),
        index: index,
        child: widget.itemBuilder(_items[index]),
      ),
    );
  }
}
