import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final String text;
  final IconData? iconData;
  final bool? initialExpanded;
  final Widget? collapsedChild;
  final Widget? expandedChild;

  const ExpandableCard({
    super.key,
    required this.text,
    this.iconData,
    this.initialExpanded = false,
    this.collapsedChild,
    this.expandedChild,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded ?? false;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: widget.iconData != null
                ? Icon(widget.iconData)
                : null,
            title: Text(widget.text),
            trailing: RotationTransition(
              turns: _arrowAnimation,
              child: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: _toggleExpand,
          ),
          if (widget.collapsedChild != null && !_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: widget.collapsedChild,
            ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1,
            child: (widget.expandedChild == null) ? null : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.expandedChild,
            ),
          ),
        ],
      ),
    );
  }
}