import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> generateLevels(
    double targetAmount,
    double savingCapacity,
  ) {
    List<Map<String, dynamic>> levels = [];
    double remaining = targetAmount;
    int levelNumber = 1;

    while (remaining > 0) {
      double amount = remaining >= savingCapacity ? savingCapacity : remaining;
      levels.add({
        'number': levelNumber,
        'amountRequired': amount,
        'completed': false,
        'completedAt': null,
      });
      remaining -= amount;
      levelNumber++;
    }

    return levels;
  }

  Future<void> createGoal(
    String uid, {
    required String title,
    required double targetAmount,
    required double savingCapacity,
    required String period,
    required String urgency,
    required String estimatedDate,
    required int periodsNeeded,
  }) async {
    final levels = generateLevels(targetAmount, savingCapacity);

    await _db.collection('users').doc(uid).collection('goals').add({
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': 0,
      'savingCapacity': savingCapacity,
      'period': period,
      'urgency': urgency,
      'estimatedDate': estimatedDate,
      'periodsNeeded': periodsNeeded,
      'levels': levels,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Goal>> goalsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Goal.fromDoc(doc)).toList());
  }

  Future<void> completeNextLevel(String uid, String goalId, Goal goal) async {
    final nextLevelIndex = goal.levels.indexWhere((l) => !l.completed);
    if (nextLevelIndex == -1) return;

    final updatedLevels = goal.levels.map((l) {
      if (l.number == nextLevelIndex + 1) {
        return {
          'number': l.number,
          'amountRequired': l.amountRequired,
          'completed': true,
          'completedAt': Timestamp.now(),
        };
      }
      return l.toMap();
    }).toList();

    final newSaved =
        goal.savedAmount + goal.levels[nextLevelIndex].amountRequired;
    final isCompleted = newSaved >= goal.targetAmount;

    await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc(goalId)
        .update({
          'levels': updatedLevels,
          'savedAmount': newSaved,
          'completed': isCompleted,
        });
  }

  Future<void> deleteGoal(String uid, String goalId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  // archiva la meta pero la borra d la vista chavalin
  Future<void> archiveGoal(String uid, String goalId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc(goalId)
        .update({
          'completed': true,
          'archivedAt': FieldValue.serverTimestamp(),
        });
  }
}
