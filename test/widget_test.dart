import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poketran/core/theme.dart';
import 'package:poketran/data/models.dart';
import 'package:poketran/widgets/common_widgets.dart';

void main() {
  testWidgets('type pill labels a primary type', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme(true),
      home: const Scaffold(body: TypePill(type: PokeType.electric))));
    expect(find.textContaining('Electric'), findsOneWidget);
  });

  testWidgets('status pill displays training state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: StatusPill(status: TeamStatus.active))));
    expect(find.text('Training'), findsOneWidget);
  });

  testWidgets('confirmation dialog can be canceled', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          await askConfirm(context, title: 'Delete?', message: 'Are you sure?');
        }, child: const Text('Open')),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete?'), findsNothing);
  });
}
