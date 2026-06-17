import 'package:flutter_test/flutter_test.dart';
import 'package:voltewise/main.dart';

void main() {
  testWidgets('SHEMS app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SHEMSApp());

    expect(find.text('VoltWise'), findsOneWidget);
  });
}