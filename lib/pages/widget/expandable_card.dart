import 'package:material_ui/material_ui.dart';

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
    this.initialExpanded = true,
    this.collapsedChild,
    this.expandedChild,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late bool _isExpandedChildVisible;
  late final AnimationController _controller;
  late final Animation<double> _arrowAnimation;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpandedChildVisible = _isExpanded = widget.initialExpanded ?? false;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (_isExpanded) _controller.value = 1.0;
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _isExpandedChildVisible = false);
      } else if (status == AnimationStatus.forward) {
        setState(() => _isExpandedChildVisible = true);
      }
    });

    _arrowAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_controller);
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: Icon(widget.iconData),
            title: Text(widget.text),
            trailing: RotationTransition(
              turns: _arrowAnimation,
              child: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: _toggleExpand,
          ),
          if (widget.collapsedChild != null && !_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
              child: widget.collapsedChild,
            ),
          Visibility(
            visible: _isExpandedChildVisible && widget.expandedChild != null,
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
                child: widget.expandedChild,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
