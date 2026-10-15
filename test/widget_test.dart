import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l3_todo_list/main.dart';

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

void main() {
  testWidgets('CRUD, creation date and completed appearance', (tester) async {
    await tester.pumpWidget(const TodoApp());
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
