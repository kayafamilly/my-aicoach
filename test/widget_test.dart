import 'package:flutter_test/flutter_test.dart';

import 'package:my_aicoach/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(showOnboarding: false));
    await tester.pumpAndSettle();

    expect(find.text('Find your coach'), findsOneWidget);
  });
}
