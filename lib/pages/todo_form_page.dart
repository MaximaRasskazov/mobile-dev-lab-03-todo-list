import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoFormPage extends StatefulWidget {
  final Todo? todo;

  const TodoFormPage({super.key, this.todo});

  @override
  State<TodoFormPage> createState() {
    return _TodoFormPageState();
  }
}

class _TodoFormPageState extends State<TodoFormPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    if (todo != null) {
      titleController.text = todo.title;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void saveTodo() {
    if (formKey.currentState!.validate()) {
      // Возвращаем название. Сам список изменяется только на главном экране.
      Navigator.pop(context, titleController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = 'Новая задача';
    if (widget.todo != null) {
      pageTitle = 'Редактирование задачи';
    }

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название задачи',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saveTodo,
                  child: const Text('Сохранить'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
