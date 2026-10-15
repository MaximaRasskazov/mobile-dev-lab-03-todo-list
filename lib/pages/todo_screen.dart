import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../repositories/todo_repository.dart';
import 'todo_form_page.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() {
    return TodoState();
  }
}

class TodoState extends State<TodoScreen> {
  final repository = TodoRepository();
  String searchText = '';
  String selectedFilter = 'Все';
  String selectedSort = 'Сначала новые';

  bool isLoading = true;
  bool loadError = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  Future<void> loadTodos() async {
    setState(() {
      isLoading = true;
      loadError = false;
    });
    try {
      await repository.loadTodos();
    } catch (_) {
      if (mounted) {
        setState(() {
          loadError = true;
        });
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveTodos() async {
    if (isSaving) {
      return;
    }
    setState(() {
      isSaving = true;
    });
    try {
      await repository.saveTodos();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось сохранить задачи'),
            action: SnackBarAction(label: 'Повторить', onPressed: saveTodos),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  List<Todo> getVisibleTodos() {
    final List<Todo> result = [];
    final query = searchText.trim().toLowerCase();

    for (final todo in repository.getTodos()) {
      if (selectedFilter == 'Активные' && todo.isDone) {
        continue;
      }
      if (selectedFilter == 'Выполненные' && !todo.isDone) {
        continue;
      }
      if (!todo.title.toLowerCase().contains(query)) {
        continue;
      }
      result.add(todo);
    }

    // Сортируем только задачи, которые подходят под фильтр и поиск.
    result.sort((first, second) {
      if (selectedSort == 'По названию') {
        return first.title.toLowerCase().compareTo(second.title.toLowerCase());
      }
      if (selectedSort == 'Сначала старые') {
        return first.createdAt.compareTo(second.createdAt);
      }
      return second.createdAt.compareTo(first.createdAt);
    });
    return result;
  }

  Future<void> openForm(Todo? todo) async {
    if (isSaving) {
      return;
    }
    final title = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return TodoFormPage(todo: todo);
        },
      ),
    );

    // При отмене результат равен null. mounted проверяет, что экран ещё открыт.
    if (!mounted || title == null) {
      return;
    }
    setState(() {
      if (todo == null) {
        repository.addTodo(title);
      } else {
        repository.updateTodo(todo, title);
      }
    });
    await saveTodos();
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} $hour:$minute';
  }

  Widget buildFilter(String filter) {
    return ChoiceChip(
      label: Text(filter),
      selected: selectedFilter == filter,
      onSelected: (selected) {
        setState(() {
          selectedFilter = filter;
        });
      },
    );
  }

  Widget buildTodoCard(Todo todo) {
    TextDecoration decoration = TextDecoration.none;
    Color titleColor = Colors.white;
    if (todo.isDone) {
      decoration = TextDecoration.lineThrough;
      titleColor = const Color(0xFFFFD8C2);
    }

    return Card(
      child: ListTile(
        subtitleTextStyle: const TextStyle(color: Color(0xFFFFE2CC)),
        leading: Checkbox(
          activeColor: Colors.white,
          checkColor: const Color(0xFF9C4827),
          side: const BorderSide(color: Colors.white70),
          value: todo.isDone,
          onChanged: (value) async {
            if (isSaving) {
              return;
            }
            setState(() {
              repository.toggleTodo(todo);
            });
            await saveTodos();
          },
        ),
        title: Text(
          todo.title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(decoration: decoration, color: titleColor),
        ),
        subtitle: Text('Создана: ${formatDate(todo.createdAt)}'),
        onTap: () {
          openForm(todo);
        },
        trailing: PopupMenuButton<String>(
          iconColor: Colors.white,
          tooltip: 'Действия с задачей',
          onSelected: (action) async {
            if (isSaving) {
              return;
            }
            if (action == 'edit') {
              openForm(todo);
            } else if (action == 'delete') {
              setState(() {
                repository.deleteTodo(todo);
              });
              await saveTodos();
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(value: 'edit', child: Text('Редактировать')),
              PopupMenuItem(value: 'delete', child: Text('Удалить')),
            ];
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || loadError) {
      Widget content = const CircularProgressIndicator();
      if (loadError) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить задачи'),
            const SizedBox(height: 12),
            FilledButton(onPressed: loadTodos, child: const Text('Повторить')),
          ],
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Список задач')),
        body: SafeArea(child: Center(child: content)),
      );
    }

    final todos = getVisibleTodos();
    String emptyText = 'Задач пока нет. Нажмите +, чтобы добавить.';
    if (repository.getTodos().isNotEmpty) {
      emptyText = 'Подходящих задач нет';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Список задач')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Поиск по названию',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                buildFilter('Все'),
                buildFilter('Активные'),
                buildFilter('Выполненные'),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedSort,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Сортировка',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Сначала новые',
                  child: Text('Сначала новые'),
                ),
                DropdownMenuItem(
                  value: 'Сначала старые',
                  child: Text('Сначала старые'),
                ),
                DropdownMenuItem(
                  value: 'По названию',
                  child: Text('По названию'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedSort = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (todos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(emptyText, textAlign: TextAlign.center),
              ),
            for (final todo in todos) buildTodoCard(todo),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить задачу',
        onPressed: () {
          openForm(null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
