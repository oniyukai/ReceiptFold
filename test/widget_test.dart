import 'dart:async';

// import 'package:flutter/material.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
// import 'package:flutter_test/flutter_test.dart';

int time = 0;

int? ppp([String? s]) {
  try {
    if (time++ >= 12) throw 'eee';
    ppp();
  } catch (e) {
    LogService(null).i();
    LogService('2').i();
    LogService('3').i();
  }
  return null;
}

void main() async {
  ppp();
  await Future.delayed(Duration(seconds: 2));
}
