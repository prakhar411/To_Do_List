// lib/services/task_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:to_do_list/models/task.dart';

class TaskService {
  static const String _baseUrl =
      "https://9dab-103-60-196-249.ngrok-free.app/tasks";
  // 'http://10.0.2.2:5000/tasks'; // For Android Emulator

  static Future<http.Response> fetchTasks() {
    return http.get(Uri.parse(_baseUrl));
  }
  // for emulator
  // static Future<http.Response> fetchTasks() {
  //   return http.get(Uri.parse(_baseUrl));
  // }

  static Future<http.Response> createTask(Task task) {
    return http.post(
      Uri.parse(_baseUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(task.toJson()),
    );
  }

  static Future<http.Response> deleteTask(int id) {
    return http.delete(Uri.parse('$_baseUrl/$id'));
  }

  static Future<http.Response> updateTask(Task task) {
    return http.put(
      Uri.parse('$_baseUrl/${task.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(task.toJson()),
    );
  }
}
