class Todo {
  String title;
  bool isDone;
  final DateTime createdAt;

  Todo({required this.title, required this.createdAt, this.isDone = false});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    if (title.trim().isEmpty) {
      throw const FormatException('Пустое название сохранённой задачи');
    }
    return Todo(
      title: title,
      isDone: json['isDone'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
