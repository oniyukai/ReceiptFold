import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

void main() async {
  debugPrint(DateTime.utc(2025, 0, 1).toIso8601String());
  debugPrint(DateTime.now().toUtc().toIso8601String());
}
