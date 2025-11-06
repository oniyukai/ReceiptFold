import 'package:flutter/material.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';
import 'package:receipt_fold/pages/menu_manager/tab_carrier_view.dart';
import 'package:receipt_fold/pages/menu_manager/tab_member_view.dart';

class MainManagerView extends StatefulWidget {
  const MainManagerView({super.key});

  @override
  State<MainManagerView> createState() => _MainManagerViewState();
}

class _MainManagerViewState extends State<MainManagerView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dock)),
            Tab(icon: Icon(Icons.loyalty_outlined)),
            Tab(icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [
            TabBarcodeView(),
            TabMemberView(),
            TabCarrierView(),
          ],
        ),
      )
    );
  }
}