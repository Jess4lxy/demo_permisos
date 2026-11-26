import 'package:flutter_test/flutter_test.dart';

import 'package:demo_permisos/main.dart';

void main() {
  testWidgets('El menú muestra las tres opciones', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoPermisosApp());

    expect(find.text('1.7'), findsOneWidget);
    expect(find.text('1.13'), findsOneWidget);
    expect(find.text('1.14'), findsOneWidget);
  });
}
