import 'package:attendease_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendEaseApp());

    expect(find.text('AttendEase'), findsOneWidget);
    expect(find.text('EMPLOYEE PORTAL'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
