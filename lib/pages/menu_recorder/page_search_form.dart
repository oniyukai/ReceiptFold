import 'package:flutter/material.dart';

class PageSearchForm extends StatefulWidget {
  const PageSearchForm({super.key});

  @override
  State<PageSearchForm> createState() => _PageSearchFormState();
}

class _PageSearchFormState extends State<PageSearchForm> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: Text('搜尋條件')),
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

// 寫死式多AND{
// - originStatus 複選
// - issuedAt 最早最晚區間
// - description 字串複選
// - totalAmount 最大最小區間
// - prizeAmount 最大最小區間
// - 增加式多AND{
//     可選字串項(userNote,invoiceNumber,randomNumber,carrierName,carrierType,carrierId2,sellerName,sellerTaxId,sellerAddress,sellerRemark,prizeName)
//     當中 OR 達成 字串複選 者
//   }
// }
