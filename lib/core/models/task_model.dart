import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime? dueTime;

  @HiveField(4)
  int priority; // 0 = normal, 1 = high, 2 = urgent

  @HiveField(5)
  String? category;

  @HiveField(6)
  bool addedViaVoice;

  @HiveField(7)
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueTime,
    this.priority = 0,
    this.category,
    this.addedViaVoice = false,
    required this.createdAt,
  });

  TaskModel copyWith({
    String? title,
    bool? isCompleted,
    DateTime? dueTime,
    int? priority,
    String? category,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      addedViaVoice: addedViaVoice,
      createdAt: createdAt,
    );
  }
}

@HiveType(typeId: 1)
class ReminderModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime scheduledTime;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  bool isRecurring;

  @HiveField(5)
  bool addedViaVoice;

  ReminderModel({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.isActive = true,
    this.isRecurring = false,
    this.addedViaVoice = false,
  });
}
