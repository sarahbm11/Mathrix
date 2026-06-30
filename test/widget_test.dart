import 'package:flutter_test/flutter_test.dart';

import 'package:mathrix/main.dart';

void main() {
  testWidgets('App boots and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MathrixApp());
    expect(find.text('Mathrix'), findsOneWidget);
    expect(find.text('Capturer un cahier'), findsOneWidget);
  });
}
