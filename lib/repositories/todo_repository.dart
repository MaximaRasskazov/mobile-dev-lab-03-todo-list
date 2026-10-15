import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

class TodoRepository {
  final List<Todo> _todos = [];
  final preferences = SharedPreferencesAsync();
  final String storageKey = 'todo_list';

  Future<void> loadTodos() async {
    final savedTodos = await preferences.getString(storageKey);
    final List<Todo> loadedTodos = [];
    if (savedTodos != null) {
      final List<dynamic> data = jsonDecode(savedTodos);
      for (final item in data) {
        loadedTodos.add(Todo.fromJson(item as Map<String, dynamic>));
      }
    }
    // Заменяем список только после успешного чтения всех задач.
    _todos.clear();
    _todos.addAll(loadedTodos);
  }

  Future<void> saveTodos() async {
    final List<Map<String, dynamic>> data = [];
    for (final todo in _todos) {
      data.add(todo.toJson());
    }
    await preferences.setString(storageKey, jsonEncode(data));
  }

  List<Todo> getTodos() {
    // Копия списка позволяет сортировать результат, не меняя порядок хранения.
    return List<Todo>.from(_todos);
  }

  void addTodo(String title) {
    _todos.add(Todo(title: title.trim(), createdAt: DateTime.now()));
  }

  void updateTodo(Todo todo, String title) {
    todo.title = title.trim();
  }

  void deleteTodo(Todo todo) {
    _todos.remove(todo);
  }

  void toggleTodo(Todo todo) {
    todo.isDone = !todo.isDone;
  }
}
