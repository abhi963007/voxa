import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  static const String _tasksBoxName = 'tasks';
  static const String _remindersBoxName = 'reminders';

  late Box<TaskModel> _tasksBox;
  late Box<ReminderModel> _remindersBox;

  List<TaskModel> _tasks = [];
  List<ReminderModel> _reminders = [];

  final _uuid = const Uuid();
  final _notificationService = NotificationService();

  List<TaskModel> get tasks => _tasks;
  List<ReminderModel> get reminders => _reminders;

  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueTime == null) return false;
      final due = t.dueTime!;
      return due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    }).toList()
      ..sort((a, b) => (a.dueTime ?? DateTime.now())
          .compareTo(b.dueTime ?? DateTime.now()));
  }

  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  List<TaskModel> get highPriorityTasks =>
      _tasks.where((t) => t.priority >= 1 && !t.isCompleted).toList();

  int get todayCompletedCount =>
      todayTasks.where((t) => t.isCompleted).length;

  int get todayTotalCount => todayTasks.length;

  List<ReminderModel> get upcomingReminders {
    final now = DateTime.now();
    return _reminders
        .where((r) => r.isActive && r.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<void> init() async {
    _tasksBox = await Hive.openBox<TaskModel>(_tasksBoxName);
    _remindersBox = await Hive.openBox<ReminderModel>(_remindersBoxName);
    _tasks = _tasksBox.values.toList();
    _reminders = _remindersBox.values.toList();

    // Seed demo data if empty
    if (_tasks.isEmpty) {
      await _seedDemoData();
    }

    notifyListeners();
  }

  Future<void> _seedDemoData() async {
    final now = DateTime.now();

    final demotasks = [
      TaskModel(
        id: _uuid.v4(),
        title: 'Complete Flutter UI design',
        priority: 1,
        dueTime: DateTime(now.year, now.month, now.day, 9, 0),
        addedViaVoice: false,
        createdAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Team standup meeting',
        priority: 1,
        dueTime: DateTime(now.year, now.month, now.day, 11, 30),
        addedViaVoice: true,
        createdAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Review API documentation',
        priority: 0,
        dueTime: DateTime(now.year, now.month, now.day, 8, 30),
        isCompleted: true,
        addedViaVoice: true,
        createdAt: now,
      ),
      TaskModel(
        id: _uuid.v4(),
        title: 'Buy groceries',
        priority: 0,
        category: 'Personal',
        addedViaVoice: true,
        createdAt: now,
      ),
    ];

    for (final task in demotasks) {
      await _tasksBox.put(task.id, task);
      if (!task.isCompleted &&
          task.dueTime != null &&
          task.dueTime!.isAfter(now)) {
        await _scheduleTaskNotification(task);
      }
    }
    _tasks = _tasksBox.values.toList();

    final demoReminders = [
      ReminderModel(
        id: _uuid.v4(),
        title: 'Call mom',
        scheduledTime: DateTime(now.year, now.month, now.day, 19, 0),
        addedViaVoice: true,
      ),
      ReminderModel(
        id: _uuid.v4(),
        title: 'Take evening medication',
        scheduledTime: DateTime(now.year, now.month, now.day, 21, 0),
        isRecurring: true,
      ),
      ReminderModel(
        id: _uuid.v4(),
        title: 'Project submission deadline',
        scheduledTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
      ),
    ];

    for (final reminder in demoReminders) {
      await _remindersBox.put(reminder.id, reminder);
      if (reminder.isActive && reminder.scheduledTime.isAfter(now)) {
        await _scheduleReminderNotification(reminder);
      }
    }
    _reminders = _remindersBox.values.toList();
  }

  Future<void> addTask({
    required String title,
    DateTime? dueTime,
    int priority = 0,
    String? category,
    bool addedViaVoice = false,
  }) async {
    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      dueTime: dueTime,
      priority: priority,
      category: category,
      addedViaVoice: addedViaVoice,
      createdAt: DateTime.now(),
    );
    await _tasksBox.put(task.id, task);
    _tasks = _tasksBox.values.toList();

    if (dueTime != null) {
      await _scheduleTaskNotification(task);
    }

    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await task.save();
      _tasks = _tasksBox.values.toList();

      if (task.isCompleted) {
        await _notificationService.cancelNotification(_idToInt(task.id));
      } else if (task.dueTime != null) {
        await _scheduleTaskNotification(task);
      }

      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
    _tasks = _tasksBox.values.toList();
    await _notificationService.cancelNotification(_idToInt(id));
    notifyListeners();
  }

  Future<void> addReminder({
    required String title,
    required DateTime scheduledTime,
    bool isRecurring = false,
    bool addedViaVoice = false,
  }) async {
    final reminder = ReminderModel(
      id: _uuid.v4(),
      title: title,
      scheduledTime: scheduledTime,
      isRecurring: isRecurring,
      addedViaVoice: addedViaVoice,
    );
    await _remindersBox.put(reminder.id, reminder);
    _reminders = _remindersBox.values.toList();

    await _scheduleReminderNotification(reminder);

    notifyListeners();
  }

  Future<void> toggleReminder(String id) async {
    final reminder = _remindersBox.get(id);
    if (reminder != null) {
      reminder.isActive = !reminder.isActive;
      await reminder.save();
      _reminders = _remindersBox.values.toList();

      if (reminder.isActive) {
        await _scheduleReminderNotification(reminder);
      } else {
        await _notificationService.cancelNotification(_idToInt(reminder.id));
      }

      notifyListeners();
    }
  }

  Future<void> _scheduleTaskNotification(TaskModel task) async {
    if (task.dueTime == null) return;
    await _notificationService.scheduleNotification(
      id: _idToInt(task.id),
      title: 'Task Reminder',
      body: task.title,
      scheduledTime: task.dueTime!,
    );
  }

  Future<void> _scheduleReminderNotification(ReminderModel reminder) async {
    await _notificationService.scheduleNotification(
      id: _idToInt(reminder.id),
      title: 'Voxa Reminder',
      body: reminder.title,
      scheduledTime: reminder.scheduledTime,
    );
  }

  int _idToInt(String id) {
    // Simple hash for constant length ID
    return id.hashCode.abs();
  }
}
