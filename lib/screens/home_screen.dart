import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TaskItem> _tasks = [];
  String _filter = 'all';
  bool _loading = true;

  static const List<String> _weekdays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ];
  static const List<String> _months = [
    'يناير','فبراير','مارس','أبريل','مايو','يونيو',
    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await StorageService.loadTasks();
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await StorageService.saveTasks(_tasks);
  }

  String _fmtDateLabel(String ds) {
    if (ds.isEmpty) return 'بدون تاريخ';
    final d = DateTime.parse(ds);
    return '${_weekdays[d.weekday - 1]}، ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  List<TaskItem> get _filtered {
    final list = _tasks.where((t) {
      if (_filter == 'all') return true;
      if (_filter == 'pending') return t.status == TaskStatus.pending;
      if (_filter == 'late') return t.status == TaskStatus.late;
      if (_filter == 'done') return t.status == TaskStatus.done;
      return true;
    }).toList();

    list.sort((a, b) {
      int order(TaskStatus s) =>
          s == TaskStatus.late ? 0 : (s == TaskStatus.pending ? 1 : 2);
      final oa = order(a.status), ob = order(b.status);
      if (oa != ob) return oa - ob;
      final da = a.date.isEmpty ? '9999-99-99' : a.date;
      final db = b.date.isEmpty ? '9999-99-99' : b.date;
      if (da != db) return da.compareTo(db);
      return a.time.compareTo(b.time);
    });
    return list;
  }

  Future<void> _toggle(TaskItem t) async {
    setState(() => t.completed = !t.completed);
    await _persist();
  }

  Future<void> _openEditor({TaskItem? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    DateTime selectedDate = existing != null && existing.date.isNotEmpty
        ? DateTime.parse(existing.date)
        : DateTime.now();
    TimeOfDay? selectedTime = existing != null && existing.time.isNotEmpty
        ? TimeOfDay(
            hour: int.parse(existing.time.split(':')[0]),
            minute: int.parse(existing.time.split(':')[1]))
        : null;
    bool hasDate = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18, right: 18, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'مهمة جديدة' : 'تعديل المهمة',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: 'نص المهمة',
                    filled: true,
                    fillColor: AppColors.paper,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setSheet(() { selectedDate = picked; });
                          }
                        },
                        child: Text(intl.DateFormat('yyyy-MM-dd').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setSheet(() { selectedTime = picked; });
                          }
                        },
                        child: Text(selectedTime == null
                            ? 'اختياري: الوقت'
                            : selectedTime!.format(ctx)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (existing != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.late,
                            side: const BorderSide(color: AppColors.late),
                          ),
                          onPressed: () async {
                            setState(() => _tasks.removeWhere((x) => x.id == existing.id));
                            await _persist();
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('حذف'),
                        ),
                      ),
                    if (existing != null) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;
                          final dateStr = intl.DateFormat('yyyy-MM-dd').format(selectedDate);
                          final timeStr = selectedTime == null
                              ? ''
                              : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

                          setState(() {
                            if (existing != null) {
                              existing.title = title;
                              existing.date = dateStr;
                              existing.time = timeStr;
                            } else {
                              _tasks.add(TaskItem(
                                id: const Uuid().v4(),
                                title: title,
                                date: dateStr,
                                time: timeStr,
                                completed: false,
                              ));
                            }
                          });
                          await _persist();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pendingCount = _tasks.where((t) => t.status == TaskStatus.pending).length;
    final lateCount = _tasks.where((t) => t.status == TaskStatus.late).length;
    final doneCount = _tasks.where((t) => t.status == TaskStatus.done).length;

    // group by date for section headers
    final items = _filtered;
    String? lastGroup;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('مهامي اليومية',
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active_outlined),
                    color: AppColors.brand,
                    onPressed: () async {
                      await NotificationService.requestPermissions();
                      await NotificationService.startReminderChain();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تفعيل التنبيهات')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statPill('قيد التنفيذ', pendingCount, AppColors.pending),
                  const SizedBox(width: 8),
                  _statPill('متأخرة', lateCount, AppColors.late),
                  const SizedBox(width: 8),
                  _statPill('مكتملة', doneCount, AppColors.ok),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مهمة جديدة'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tab('الكل', 'all'),
                    _tab('قيد التنفيذ', 'pending'),
                    _tab('متأخرة', 'late'),
                    _tab('مكتملة', 'done'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد مهام هنا', style: TextStyle(color: AppColors.inkSoft)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final t = items[i];
                        final groupKey = t.date;
                        Widget? header;
                        if (groupKey != lastGroup) {
                          header = Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                            child: Text(_fmtDateLabel(groupKey),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                          );
                          lastGroup = groupKey;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (header != null) header,
                            TaskCard(
                              task: t,
                              onToggle: () => _toggle(t),
                              onEdit: () => _openEditor(existing: t),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, String key) {
    final active = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => _filter = key),
        selectedColor: AppColors.ink,
        labelStyle: TextStyle(color: active ? Colors.white : AppColors.inkSoft, fontSize: 12.5),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
      ),
    );
  }
}
