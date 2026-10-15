import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l3_todo_list/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> addTodo(WidgetTester tester, String title) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), title);
  await tester.tap(find.text('Сохранить'));
  await tester.pumpAndSettle();
}

Future<void> chooseAction(
  WidgetTester tester,
  String title,
  String action,
) async {
  final card = find.ancestor(of: find.text(title), matching: find.byType(Card));
  await tester.tap(
    find.descendant(of: card, matching: find.byType(PopupMenuButton<String>)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

Future<void> chooseSort(WidgetTester tester, String sort) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sort).last);
  await tester.pumpAndSettle();
}

Future<void> restartApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(const TodoApp());
  await tester.pumpAndSettle();
}

final class FailingPreferences extends InMemorySharedPreferencesAsync {
  FailingPreferences() : super.empty();

  bool failWrites = true;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (failWrites) {
      throw Exception('Storage unavailable');
    }
    return super.setString(key, value, options);
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Tasks, edits, completion, dates and deletion survive restart', (
    tester,
  ) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await addTodo(tester, 'Купить хлеб');
    await addTodo(tester, 'Сделать лабораторную');
    await chooseAction(tester, 'Сделать лабораторную', 'Редактировать');
    await tester.enterText(find.byType(TextFormField), 'Защитить лабораторную');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final dates = tester
        .widgetList<Text>(find.textContaining('Создана:'))
        .map((text) => text.data)
        .toList();

    await restartApp(tester);
    expect(find.text('Купить хлеб'), findsOneWidget);
    expect(find.text('Защитить лабораторную'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    expect(
      tester
          .widgetList<Text>(find.textContaining('Создана:'))
          .map((text) => text.data)
          .toList(),
      dates,
    );
    await chooseAction(tester, 'Купить хлеб', 'Удалить');
    await restartApp(tester);
    expect(find.text('Купить хлеб'), findsNothing);
    expect(find.text('Защитить лабораторную'), findsOneWidget);
    await chooseAction(tester, 'Защитить лабораторную', 'Удалить');
    await restartApp(tester);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('Invalid saved data is not overwritten and load can be retried', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'todo_list': 'broken json'});
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить задачи'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    final preferences = SharedPreferencesAsync();
    expect(await preferences.getString('todo_list'), 'broken json');
    await preferences.setString('todo_list', '[]');
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Failed save shows retry and successful retry survives restart', (
    tester,
  ) async {
    final storage = FailingPreferences();
    SharedPreferencesAsyncPlatform.instance = storage;
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await addTodo(tester, 'Важная задача');
    expect(find.text('Не удалось сохранить задачи'), findsOneWidget);
    expect(find.text('Важная задача'), findsOneWidget);
    storage.failWrites = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    await restartApp(tester);
    expect(find.text('Важная задача'), findsOneWidget);
  });
  testWidgets('CRUD, creation date and completed appearance', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await addTodo(tester, '  Сделать лабораторную  ');
    expect(find.text('Сделать лабораторную'), findsOneWidget);
    final dateBefore = tester
        .widget<Text>(find.textContaining('Создана:'))
        .data;

    await chooseAction(tester, 'Сделать лабораторную', 'Редактировать');
    expect(find.text('Сделать лабораторную'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Защитить лабораторную');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Сделать лабораторную'), findsNothing);
    expect(find.text('Защитить лабораторную'), findsOneWidget);
    expect(
      tester.widget<Text>(find.textContaining('Создана:')).data,
      dateBefore,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(
      tester.widget<Text>(find.text('Защитить лабораторную')).style!.decoration,
      TextDecoration.lineThrough,
    );
    await chooseAction(tester, 'Защитить лабораторную', 'Удалить');
    expect(find.byType(Card), findsNothing);
  });

  testWidgets(
    'Empty and whitespace titles are rejected; cancel preserves data',
    (tester) async {
      await tester.pumpWidget(const TodoApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Введите название задачи'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Введите название задачи'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);

      await addTodo(tester, 'Купить хлеб');
      await tester.tap(find.text('Купить хлеб'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), ' ');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Введите название задачи'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Несохранённое название',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Купить хлеб'), findsOneWidget);
      expect(find.text('Несохранённое название'), findsNothing);
    },
  );

  testWidgets('Filters and case-insensitive partial search work together', (
    tester,
  ) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await addTodo(tester, 'Купить хлеб');
    await addTodo(tester, 'Купить молоко');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Активные'));
    await tester.pumpAndSettle();
    expect(find.text('Купить хлеб'), findsOneWidget);
    expect(find.text('Купить молоко'), findsNothing);
    await tester.enterText(find.byType(TextField), '  ХЛЕ  ');
    await tester.pumpAndSettle();
    expect(find.text('Купить хлеб'), findsOneWidget);
    await tester.tap(find.text('Выполненные'));
    await tester.pumpAndSettle();
    expect(find.text('Подходящих задач нет'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'мол');
    await tester.pumpAndSettle();
    expect(find.text('Купить молоко'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Все'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('Sorting by title and both date directions; rename reorders', (
    tester,
  ) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await addTodo(tester, 'Яблоки');
    await addTodo(tester, 'бананы');
    expect(
      tester.getTopLeft(find.text('бананы')).dy,
      lessThan(tester.getTopLeft(find.text('Яблоки')).dy),
    );
    await chooseSort(tester, 'Сначала старые');
    expect(
      tester.getTopLeft(find.text('Яблоки')).dy,
      lessThan(tester.getTopLeft(find.text('бананы')).dy),
    );
    await chooseSort(tester, 'По названию');
    expect(
      tester.getTopLeft(find.text('бананы')).dy,
      lessThan(tester.getTopLeft(find.text('Яблоки')).dy),
    );
    await tester.tap(find.text('Яблоки'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Абрикосы');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Абрикосы')).dy,
      lessThan(tester.getTopLeft(find.text('бананы')).dy),
    );
    await chooseSort(tester, 'Сначала новые');
    expect(
      tester.getTopLeft(find.text('бананы')).dy,
      lessThan(tester.getTopLeft(find.text('Абрикосы')).dy),
    );
  });

  testWidgets('Deleting a duplicate title removes only the selected task', (
    tester,
  ) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    await addTodo(tester, 'Задача');
    await addTodo(tester, 'Задача');
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Задача'), findsOneWidget);
  });

  testWidgets('Small mobile screen, long title, large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    final longTitle = 'Очень длинное название задачи ' * 10;
    await addTodo(tester, longTitle);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), longTitle);
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
