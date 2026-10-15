import '../models/todo.dart';

class TodoRepository {
  final List<Todo> _todos = [];

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
