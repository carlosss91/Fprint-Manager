import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fprint_manager/main.dart';

void main() {
  testWidgets('Fprint-Manager UI renders initial layout and loads hardware info',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FprintManagerApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verifica la HeaderBar
    expect(find.text('Fprint-Manager'), findsOneWidget);

    // Verifica panel de huellas
    expect(find.text('Huellas Registradas'), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);

    // Verifica el panel central del sensor
    expect(find.textContaining('LISTO PARA LECTURA'), findsOneWidget);
    expect(find.textContaining('Verificar'), findsWidgets);

    // Verifica la barra inferior
    expect(find.text('Reiniciar Sensor y Servicio USB'), findsOneWidget);
  });

  testWidgets('Enrollment dialog opens and displays finger selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FprintManagerApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Clic en agregar huella
    await tester.tap(find.text('Agregar'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verifica diálogo de registro
    expect(find.text('Registrar nueva huella'), findsOneWidget);
    expect(find.text('Iniciar en Sensor'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Cierra el diálogo
    await tester.tap(find.text('Cancelar'));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Verification history dialog opens properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FprintManagerApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Clic en el icono de historial
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pump(const Duration(milliseconds: 400));

    // Verifica que se muestre el modal de historial
    expect(find.text('Historial de Verificaciones'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
