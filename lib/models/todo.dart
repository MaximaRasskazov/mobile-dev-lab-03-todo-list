class Todo {
  String title;
  bool isDone;
  final DateTime createdAt;

  Todo({required this.title, required this.createdAt, this.isDone = false});
}
