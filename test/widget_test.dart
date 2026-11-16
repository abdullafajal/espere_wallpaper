import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:espere_wallpaper/app/app.dart';
import 'package:espere_wallpaper/core/storage/hive_boxes.dart';
import 'package:espere_wallpaper/features/home/presentation/home_notifier.dart';
import 'package:espere_wallpaper/features/home/presentation/home_state.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.favorites);
    await Hive.openBox(HiveBoxes.collections);
    await Hive.openBox(HiveBoxes.searchHistory);
    await Hive.openBox(HiveBoxes.appSettings);
  });

  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override home notifier to avoid infinite pending network timers in smoke test
          homeNotifierProvider.overrideWith((ref) => MockHomeNotifier()),
        ],
        child: const EspereWallpaperApp(),
      ),
    );

    expect(find.byType(EspereWallpaperApp), findsOneWidget);
  });
}

class MockHomeNotifier extends StateNotifier<HomeState>
    implements HomeNotifier {
  MockHomeNotifier() : super(const HomeState(isLoading: false));

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}
}
