import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class StorageService {
  static const String tasksKey = 'tasks_v1';

  /// Default seed tasks shown the very first time the app runs.
  static List<TaskItem> _defaultTasks() => [
        TaskItem(
          id: 't1',
          title: 'مراجعة وإكمال حسابات عدد 2 منشأة خاصة بمحمود مسعود',
          date: '2026-06-04',
          time: '',
          completed: false,
        ),
        TaskItem(
          id: 't2',
          title: 'إنهاء منشأة الفاروق',
          date: '2026-06-04',
          time: '',
          completed: false,
        ),
        TaskItem(
          id: 't3',
          title: 'إنهاء الملفات الموجودة أمامي التي تحتاج حساب وحدات',
          date: '2026-06-04',
          time: '',
          completed: false,
        ),
        TaskItem(
          id: 't4',
          title:
              'إنهاء الملفات الموجودة أمامي التي تحتاج تغيير الحالة من "مسبق دفع" إلى "ميكانيكي"',
          date: '2026-06-04',
          time: '',
          completed: false,
        ),
      ];

  static Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(tasksKey);
    if (raw == null) {
      final seeded = _defaultTasks();
      await saveTasks(seeded);
      return seeded;
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return _defaultTasks();
    }
  }

  static Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(tasksKey, raw);
  }
}
