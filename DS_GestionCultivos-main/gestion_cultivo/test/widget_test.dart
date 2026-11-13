import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_cultivo/pages/help_page.dart';

void main() {
  testWidgets('help center filters questions by search', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HelpPage())),
    );

    expect(find.text('Centro de ayuda'), findsOneWidget);
    expect(find.text('¿Cómo activo el modo oscuro?'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'modo oscuro',
    );
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo activo el modo oscuro?'), findsOneWidget);
    expect(find.text('¿Puedo subir o administrar archivos?'), findsNothing);
  });

  testWidgets('help center acknowledges feedback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HelpPage())),
    );

    await tester.ensureVisible(find.text('Sí'));
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    expect(find.text('¡Gracias! Nos alegra que te haya servido.'), findsOneWidget);
  });
}
