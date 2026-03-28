import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goal_service.dart';
import '../models/goal_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<List<Goal>>(
      stream: GoalService().goalsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedGoals = (snapshot.data ?? [])
            .where((g) => g.completed)
            .toList();

        if (completedGoals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 72,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no has completado ninguna meta.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Sigue ahorrando, pronto aparecerán aquí!',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedGoals.length,
          itemBuilder: (context, index) {
            return _CompletedGoalCard(goal: completedGoals[index]);
          },
        );
      },
    );
  }
}

class _CompletedGoalCard extends StatelessWidget {
  final Goal goal;

  const _CompletedGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.amber[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${goal.targetAmount.toStringAsFixed(0)} ahorrados · ${goal.levels.length} niveles',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.period == 'semanal' ? 'Semanal' : 'Mensual'} · ${goal.periodsNeeded} ${goal.period == 'semanal' ? 'semanas' : 'meses'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                '✅ Cumplida',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
