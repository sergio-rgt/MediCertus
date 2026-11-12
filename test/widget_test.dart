import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicertus_app/main.dart';

void main() {
  testWidgets('MediCertus muestra el formulario de inicio de sesión',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MediCertusApp());

    expect(find.text('MediCertus'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
