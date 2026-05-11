import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  final int number;
  final double amountRequired;
  final bool completed;
  final DateTime? completedAt;

  Level({
    required this.number,
    required this.amountRequired,
    required this.completed,
    this.completedAt,
  });

  // Nombre motivacional según el progreso
  String motivationalName(int totalLevels) {
    final progress = number / totalLevels;
    if (number == 1) return 'Primer paso 🚀';
    if (number == totalLevels) return 'Recta final !!!';
    if (progress <= 0.25) return 'Arrancando 💪';
    if (progress <= 0.50) return 'Tomando ritmo, nice';
    if (progress <= 0.75) return 'A mitad de camino !!';
    return 'Ya Casi 🏁';
  }

  Map<String, dynamic> toMap() => {
    'number': number,
    'amountRequired': amountRequired,
    'completed': completed,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
  };

  factory Level.fromMap(Map<String, dynamic> map) => Level(
    number: (map['number'] as num?)?.toInt() ?? 0,
    amountRequired: (map['amountRequired'] as num?)?.toDouble() ?? 0.0,
    completed: map['completed'] ?? false,
    // CORREGIDO: null-check antes de castear a Timestamp
    completedAt: map['completedAt'] != null
        ? (map['completedAt'] as Timestamp).toDate()
        : null,
  );
}

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final double savingCapacity;
  final String period;
  final String urgency;
  final String estimatedDate;
  final int periodsNeeded;
  final List<Level> levels;
  final bool completed;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.savingCapacity,
    required this.period,
    required this.urgency,
    required this.estimatedDate,
    required this.periodsNeeded,
    required this.levels,
    required this.completed,
    required this.createdAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount * 100).clamp(0, 100) : 0;

  int get currentLevel => levels.where((l) => l.completed).length;

  factory Goal.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final levelsList = (data['levels'] as List<dynamic>? ?? [])
        .map((l) => Level.fromMap(l as Map<String, dynamic>))
        .toList();

    return Goal(
      id: doc.id,
      title: data['title'] ?? '',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0.0,
      savingCapacity: (data['savingCapacity'] as num?)?.toDouble() ?? 0.0,
      period: data['period'] ?? 'semanal',
      urgency: data['urgency'] ?? 'media',
      estimatedDate: data['estimatedDate'] ?? '',
      periodsNeeded: (data['periodsNeeded'] as num?)?.toInt() ?? 0,
      levels: levelsList,
      completed: data['completed'] ?? false,
      // CORREGIDO: si createdAt llega null (ej. justo después del add()),
      // usamos DateTime.now() como fallback en vez de crashear
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
