import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App harness boots', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('TerraBite')))),
    );
    expect(find.text('TerraBite'), findsOneWidget);
  });
}
