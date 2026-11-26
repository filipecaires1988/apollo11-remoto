import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';

class _ThemeBinding extends Fake implements RustdeskImpl {
  String theme = '';
  @override
  String mainGetLocalOption({required String key, dynamic hint}) => theme;
}

void main() {
  testWidgets('mantém o padrão escuro com preferências e sistema claros',
      (tester) async {
    final previousDesktopType = desktopType;
    final binding = _ThemeBinding();
    platformFFI.setBindingForTesting(binding);
    desktopType = DesktopType.cm;
    addTearDown(() async {
      await Get.reset();
      desktopType = previousDesktopType;
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
      platformFFI.setBindingForTesting(_ThemeBinding());
    });
    for (final preference in ['light', 'system', '', 'dark']) {
      binding.theme = preference;
      for (final brightness in Brightness.values) {
        tester.binding.platformDispatcher.platformBrightnessTestValue =
            brightness;
        expect(MyTheme.currentThemeMode(), ThemeMode.dark);
      }
    }
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await tester.pumpWidget(GetMaterialApp(
      theme: MyTheme.lightTheme,
      darkTheme: MyTheme.darkTheme,
      themeMode: MyTheme.currentThemeMode(),
      home: const Scaffold(body: Text('Apollo11 Remoto')),
    ));
    for (final mode in [ThemeMode.light, ThemeMode.system]) {
      await MyTheme.changeDarkMode(mode);
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Apollo11 Remoto'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(tester.widget<Material>(find.byType(Material).first).color,
          const Color(0xFF0D1928));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
