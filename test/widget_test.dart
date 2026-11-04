import 'package:flutter_test/flutter_test.dart';
import 'package:shaban_elmnhrawy_edu/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShabanElmnhrawyApp());
    expect(find.byType(ShabanElmnhrawyApp), findsOneWidget);
  });
}
