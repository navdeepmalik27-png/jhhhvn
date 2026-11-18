import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:come_on/core.dart';
import 'package:come_on/screens.dart';
import 'package:come_on/stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Stage fills portrait and landscape; tasks still toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    final now = DateTime.now();
    state.project = Project('My project', DateTime(now.year, now.month, now.day), 2,
        planned: true, days: [[Task('Read chapter')], [Task('Revise')]]);
    for (final size in [const Size(400, 800), const Size(900, 440)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(useMaterial3: true),
          home: HomeScreen(state: state)));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getSize(find.byType(PixelStage)), size);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text("Today's tasks"));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Read chapter'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(state.project!.days[0][0].done, isTrue);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Particles animate and reduced motion remains still', (tester) async {
    tester.view.physicalSize = const Size(900, 440);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    Future<List<int>> capture(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      await File('../$name.png').writeAsBytes(bytes);
      image.dispose();
      return bytes;
    }
    Widget stage(bool reduced) => MaterialApp(home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: RepaintBoundary(key: key, child: const PixelStage(targetX: -.4))));
    await tester.pumpWidget(stage(false));
    await tester.pump(const Duration(milliseconds: 30));
    final a = await tester.runAsync(() => capture('stage-before'));
    await tester.pump(const Duration(seconds: 1));
    final b = await tester.runAsync(() => capture('stage-after'));
    expect(a, isNot(equals(b)));
    await tester.pumpWidget(stage(true));
    final c = await tester.runAsync(() => capture('stage-still'));
    await tester.pump(const Duration(seconds: 1));
    final d = await tester.runAsync(() => capture('stage-still-after'));
    expect(c, equals(d));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
