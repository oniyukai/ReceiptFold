import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';

class PageLogsView extends StatefulWidget {
  const PageLogsView({super.key});

  @override
  State<PageLogsView> createState() => _PageLogsViewState();
}

class _PageLogsViewState extends State<PageLogsView> {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('除錯日誌'),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            children: [
              Text("未完成"),
            ],
          )
        )
      )
    );
  }
}