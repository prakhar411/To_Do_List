class Task {
  final int? id;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? completedOn;

  Task({
    this.id,
    required this.title,
    required this.isCompleted,
    this.dueDate,
    this.completedOn,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['is_completed'],
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completedOn: json['completed_on'] != null
          ? DateTime.parse(json['completed_on'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'completed_on': completedOn?.toIso8601String(),
    };
  }

  Task copyWith({bool? isCompleted, DateTime? completedOn}) {
    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate,
      completedOn: completedOn ?? this.completedOn,
    );
  }
}
