import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:to_do_list/models/task.dart';
import 'package:to_do_list/services/task_service.dart';

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Task> _tasks = [];
  bool _isLoading = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await TaskService.fetchTasks();
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final tasks = data.map((json) => Task.fromJson(json)).toList();
        setState(() {
          _tasks = tasks;
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load tasks')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();

    final result = await showDialog<Task>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedDate == null
                          ? 'Pick Due Date'
                          : 'Due Date: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                          color: selectedDate == null
                              ? Colors.blue
                              : Colors.green),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(Task(
                      title: titleController.text,
                      isCompleted: false,
                      dueDate: selectedDate,
                    ));
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await TaskService.createTask(result);
      _loadTasks();
    }
  }

  Future<void> _deleteTask(int id) async {
    await TaskService.deleteTask(id);
    _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final completedOn =
        task.isCompleted ? null : DateTime.now(); // Add completedOn date
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedOn: completedOn, // Update with current date or null if unchecked
    );
    await TaskService.updateTask(updatedTask);
    setState(() {
      _tasks[_tasks.indexWhere((t) => t.id == task.id)] = updatedTask;
    });
  }

  String _getDueDateMessage(DateTime? date) {
    if (date == null) {
      return 'No Due Date';
    }
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    if (difference > 0) {
      return 'Due in $difference day${difference > 1 ? 's' : ''}';
    } else if (difference < 0) {
      return 'Overdue by ${-difference} day${-difference > 1 ? 's' : ''}';
    } else {
      return 'Due Today';
    }
  }

  Color _getCardColor(Task task) {
    if (task.isCompleted) {
      return const Color.fromARGB(255, 144, 255, 150);
    } else if (task.dueDate != null && task.dueDate!.isBefore(DateTime.now())) {
      return const Color.fromARGB(255, 255, 100, 131);
    } else {
      return const Color.fromARGB(255, 179, 205, 255);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Tasks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(
                  child: Text('No tasks available',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteTask(task.id!);
                      },
                      background: Container(
                        color: Colors.yellow[700],
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        color: _getCardColor(task),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDueDateMessage(task.dueDate),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              if (task.isCompleted &&
                                  task.completedOn != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Completed on: ${task.completedOn!.toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Checkbox(
                            fillColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.purple; // Purple when checked
                              }
                              return Colors.black; // Black when unchecked
                            }),
                            value: task.isCompleted,
                            onChanged: (value) {
                              if (value != null) {
                                _toggleTaskCompletion(task);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        label: const Text(
          'Add Task',
          style: TextStyle(color: Colors.black),
        ),
        icon: const Icon(
          Icons.pages,
          color: Colors.black,
        ),
        backgroundColor: const Color.fromARGB(255, 93, 247, 232),
      ),
    );
  }
}
