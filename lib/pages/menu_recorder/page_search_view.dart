import 'package:flutter/material.dart';

class PageSearchView extends StatefulWidget {
  const PageSearchView({super.key});

  @override
  State<PageSearchView> createState() => _PageSearchViewState();
}

class _PageSearchViewState extends State<PageSearchView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: Text('搜尋結果')),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [],
          ),
        ),
      ),
    );
  }
}
