import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';
import 'package:receipt_fold/pages/menu_manager/tab_carrier_view.dart';
import 'package:receipt_fold/pages/menu_manager/tab_member_view.dart';

class MainManagerView extends StatefulWidget {
  const MainManagerView({super.key});

  @override
  State<MainManagerView> createState() => _MainManagerViewState();
}

class _MainManagerViewState extends State<MainManagerView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.dock),
              text: DictKey.managerTabBarcode.s,
            ),
            Tab(
              icon: const Icon(Icons.loyalty_outlined),
              text: DictKey.managerTabMember.s,
            ),
            Tab(
              icon: const Icon(Icons.payment),
              text: DictKey.managerTabCarrier.s,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [TabBarcodeView(), TabMemberView(), TabCarrierView()],
        ),
      ),
    );
  }
}
