import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';

void main() {
  testWidgets('shows the LifeOS foundation message', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LifeOsApp()));
    await tester.pump();

    expect(find.text('你要怎样度过这一生？'), findsOneWidget);
    expect(find.text('LifeOS'), findsOneWidget);
    expect(find.text('从过去一同迈向明天。'), findsOneWidget);
  });
}
