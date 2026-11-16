import 'dart:io';
import 'package:espere_wallpaper/app/app.dart';
import 'package:espere_wallpaper/core/constants/app_colors.dart';
import 'package:espere_wallpaper/core/storage/hive_boxes.dart';
import 'package:espere_wallpaper/core/theme/app_theme.dart';
import 'package:espere_wallpaper/core/widgets/photo_grid.dart';
import 'package:espere_wallpaper/features/home/presentation/home_notifier.dart';
import 'package:espere_wallpaper/features/home/presentation/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _IdleHomeNotifier extends StateNotifier<HomeState>
    implements HomeNotifier {
  _IdleHomeNotifier()
    : super(const HomeState(isLoading: false, hasMore: false));

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    final dir = await Directory.systemTemp.createTemp('hive_redesign_');
    Hive.init(dir.path);
    await Hive.openBox(HiveBoxes.favorites);
    await Hive.openBox(HiveBoxes.collections);
    await Hive.openBox(HiveBoxes.searchHistory);
    await Hive.openBox(HiveBoxes.appSettings);
  });

  group('brand palette', () {
    test('color schemes are built from the logo colors', () {
      expect(AppTheme.lightScheme.primary, AppColors.navy);
      expect(AppTheme.lightScheme.secondary, AppColors.leaf);
      expect(AppTheme.darkScheme.primaryContainer, AppColors.navy);
      expect(AppTheme.darkScheme.secondary, AppColors.leaf);
    });
  });

  group('grid density', () {
    test('keeps the preferred column count on phones', () {
      expect(effectiveGridColumns(2, 390), 2);
      expect(effectiveGridColumns(2, 360), 2);
    });

    test('adds columns on wide screens so tiles stay similar in size', () {
      expect(effectiveGridColumns(2, 800), 4);
      expect(effectiveGridColumns(2, 2000), 6); // capped at 3x preference
    });
  });

  Widget app() => ProviderScope(
    overrides: [
      homeNotifierProvider.overrideWith((ref) => _IdleHomeNotifier()),
    ],
    child: const EspereWallpaperApp(),
  );

  testWidgets('wide screens use a navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('phone shell shows Home / Search / Library and switches tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeNotifierProvider.overrideWith((ref) => _IdleHomeNotifier()),
        ],
        child: const EspereWallpaperApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byType(NavigationBar),
      findsNothing,
    ); // floating buttons instead
    expect(find.text('All'), findsOneWidget); // topic tabs
    for (final label in ['Home', 'Search', 'Library']) {
      expect(find.byTooltip(label), findsWidgets, reason: label);
    }

    await tester.tap(find.byTooltip('Library').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pins'), findsOneWidget);
    expect(find.text('Boards'), findsOneWidget);
    expect(find.text('Save ideas you love'), findsOneWidget);

    await tester.tap(find.text('Boards'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('All Pins'), findsOneWidget);
  });
}
