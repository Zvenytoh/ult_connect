import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ult_connect/main.dart';

void main() {
  testWidgets('Vérifie que l\'application se lance correctement', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}