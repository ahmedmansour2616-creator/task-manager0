enum TaskStatus { pending, late, done }

class TaskItem {
  String id;
  String title;
  String date; // 'yyyy-MM-dd' or ''
  String time; // 'HH:mm' or ''
  bool completed;

  TaskItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.completed,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: (json['date'] ?? '') as String,
      time: (json['time'] ?? '') as String,
      completed: (json['completed'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'completed': completed,
      };

  /// Computes current status based on device date/time.
  TaskStatus get status {
    if (completed) return TaskStatus.done;
    if (date.isEmpty) return TaskStatus.pending;
    try {
      final parts = date.split('-').map(int.parse).toList();
      final timeStr = time.isNotEmpty ? time : '23:59';
      final timeParts = timeStr.split(':').map(int.parse).toList();
      final due = DateTime(
        parts[0],
        parts[1],
        parts[2],
        timeParts[0],
        timeParts[1],
      );
      if (due.isBefore(DateTime.now())) return TaskStatus.late;
      return TaskStatus.pending;
    } catch (_) {
      return TaskStatus.pending;
    }
  }
}
