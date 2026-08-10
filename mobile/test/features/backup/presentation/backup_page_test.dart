import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/backup/presentation/backup_page.dart';

void main() {
  testWidgets('explains backup boundaries and validates a new password', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BackupPage())),
    );

    expect(find.text('数据与备份'), findsOneWidget);
    expect(find.textContaining('不会自动上传云端'), findsOneWidget);
    expect(find.textContaining('API Key'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '创建备份'));
    await tester.pumpAndSettle();
    expect(find.text('创建加密备份'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'short');
    await tester.enterText(find.byType(TextField).last, 'short');
    await tester.tap(find.widgetWithText(FilledButton, '选择保存位置'));
    await tester.pump();

    expect(find.text('备份口令至少需要 10 个字符'), findsOneWidget);
    expect(find.text('创建加密备份'), findsNWidgets(2));
  });
}
